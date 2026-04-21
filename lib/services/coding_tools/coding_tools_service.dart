import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/apply/repository/apply_repository.dart';
import '../../data/coding_tools/models/coding_tool_result.dart';
import '../../data/coding_tools/models/denylist_category.dart';
import '../../data/coding_tools/repository/coding_tools_denylist_repository.dart';
import '../../data/coding_tools/repository/coding_tools_denylist_repository_impl.dart';
import '../../data/coding_tools/repository/coding_tools_repository.dart';
import '../../data/coding_tools/repository/coding_tools_repository_impl.dart';
import '../apply/apply_service.dart';

export '../../data/coding_tools/models/coding_tool_result.dart';

part 'coding_tools_service.g.dart';

@Riverpod(keepAlive: true)
CodingToolsService codingToolsService(Ref ref) => CodingToolsService(
  repo: ref.watch(codingToolsRepositoryProvider),
  applyService: ref.watch(applyServiceProvider),
  denylist: ref.watch(codingToolsDenylistRepositoryProvider),
);

typedef _EffectiveDenylist = ({
  Set<String> segments,
  Set<String> filenames,
  Set<String> extensions,
  Set<String> prefixes,
});

/// Executes a single tool call. Each handler is path-guarded, size-capped,
/// and scrubs error messages before returning them to the loop.
class CodingToolsService {
  CodingToolsService({
    required CodingToolsRepository repo,
    required ApplyService applyService,
    required CodingToolsDenylistRepository denylist,
  }) : _repo = repo,
       _apply = applyService,
       _denylist = denylist;

  final CodingToolsRepository _repo;
  final ApplyService _apply;
  final CodingToolsDenylistRepository _denylist;

  static const int _kMaxReadBytes = 2 * 1024 * 1024; // 2 MB
  static const int _kMaxListEntries = 500;
  static const int _kMaxListDepth = 3;

  Future<CodingToolResult> execute({
    required String toolName,
    required Map<String, dynamic> args,
    required String projectPath,
    required String sessionId,
    required String messageId,
  }) async {
    final started = DateTime.now();
    dLog('[CodingToolsService] $toolName start');
    try {
      return switch (toolName) {
        'read_file' => await _readFile(args, projectPath),
        'list_dir' => await _listDir(args, projectPath),
        'write_file' => await _writeFile(args, projectPath, sessionId, messageId),
        'str_replace' => await _strReplace(args, projectPath, sessionId, messageId),
        _ => CodingToolResult.error('Unknown tool "$toolName"'),
      };
    } catch (e, st) {
      // Final safety net: every handler catches its expected shapes (path,
      // size, text-encoding). Anything landing here is truly unexpected —
      // OSError, IsolateSpawnException, StackOverflowError, etc. Surface it
      // as a tool_result error so the agent loop can feed it back to the
      // model instead of aborting the whole stream.
      dLog('[CodingToolsService] $toolName crashed: ${e.runtimeType} $e\n$st');
      return CodingToolResult.error('Tool "$toolName" crashed unexpectedly (${e.runtimeType}).');
    } finally {
      dLog('[CodingToolsService] $toolName done in ${DateTime.now().difference(started).inMilliseconds}ms');
    }
  }

  String _resolve(String raw, String projectPath) =>
      p.isAbsolute(raw) ? p.normalize(raw) : p.normalize(p.join(projectPath, raw));

  /// Throws [BlockedPathException] if [abs] lands on a sensitive dotfile,
  /// credential file, or key-material extension _inside_ the project root.
  /// Complements [ApplyRepository.assertWithinProject], which only bounds the
  /// project boundary. Called from every tool handler.
  void _assertNotDenied(String abs, String projectPath, _EffectiveDenylist denylist) {
    final rel = p.relative(abs, from: projectPath);
    for (final segRaw in p.split(rel)) {
      final seg = segRaw.toLowerCase();
      if (seg.isEmpty || seg == '.' || seg == '..') continue;
      if (denylist.segments.contains(seg)) {
        sLog('[CodingTools] denied segment: "$rel" (segment=$seg)');
        throw BlockedPathException(rel, 'blocked directory');
      }
      if (denylist.filenames.contains(seg)) {
        sLog('[CodingTools] denied filename: "$rel" (name=$seg)');
        throw BlockedPathException(rel, 'blocked filename');
      }
      if (denylist.prefixes.any(seg.startsWith)) {
        sLog('[CodingTools] denied filename prefix: "$rel" (name=$seg)');
        throw BlockedPathException(rel, 'blocked filename');
      }
      final ext = p.extension(seg).toLowerCase();
      if (ext.isNotEmpty && denylist.extensions.contains(ext)) {
        sLog('[CodingTools] denied extension: "$rel" (ext=$ext)');
        throw BlockedPathException(rel, 'blocked extension');
      }
    }
  }

  /// Returns `true` if [relPath] (a path relative to the project root) would
  /// match the denylist. Used by `list_dir` to filter entries without
  /// revealing that they exist.
  bool _isDeniedRel(String relPath, _EffectiveDenylist denylist) {
    for (final segRaw in p.split(relPath)) {
      final seg = segRaw.toLowerCase();
      if (seg.isEmpty || seg == '.' || seg == '..') continue;
      if (denylist.segments.contains(seg)) return true;
      if (denylist.filenames.contains(seg)) return true;
      if (denylist.prefixes.any(seg.startsWith)) return true;
      final ext = p.extension(seg).toLowerCase();
      if (ext.isNotEmpty && denylist.extensions.contains(ext)) return true;
    }
    return false;
  }

  Future<_EffectiveDenylist> _loadEffectiveDenylist() async => (
    segments: await _denylist.effective(DenylistCategory.segment),
    filenames: await _denylist.effective(DenylistCategory.filename),
    extensions: await _denylist.effective(DenylistCategory.extension),
    prefixes: await _denylist.effective(DenylistCategory.prefix),
  );

  // Newlines or control chars in a model-supplied path would pollute the
  // tool_result message fed back to the next iteration. Strip and truncate.
  String _sanitize(String raw, {int max = 120}) {
    final stripped = raw.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ');
    return stripped.length > max ? '${stripped.substring(0, max)}…' : stripped;
  }

  Future<CodingToolResult> _readFile(Map<String, dynamic> args, String projectPath) async {
    final raw = args['path'];
    if (raw is! String || raw.isEmpty) return CodingToolResult.error('read_file requires a non-empty "path"');
    final safeRaw = _sanitize(raw);
    final abs = _resolve(raw, projectPath);
    final denylist = await _loadEffectiveDenylist();

    try {
      ApplyRepository.assertWithinProject(abs, projectPath);
      _assertNotDenied(abs, projectPath, denylist);
      final size = await _repo.fileSizeBytes(abs);
      if (size > _kMaxReadBytes) {
        return CodingToolResult.error(
          'File too large ($size bytes; max $_kMaxReadBytes bytes). Consider str_replace for targeted edits.',
        );
      }
      final content = await _repo.readTextFile(abs);
      return CodingToolResult.success(content);
    } on PathEscapeException {
      return CodingToolResult.error('Path "$safeRaw" is outside the project root.');
    } on BlockedPathException {
      return CodingToolResult.error('Reading "$safeRaw" is blocked for safety (sensitive file).');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } on PathNotFoundException {
      return CodingToolResult.error('File "$safeRaw" does not exist.');
    } on FormatException {
      return CodingToolResult.error('File "$safeRaw" is not text-encoded.');
    } on FileSystemException catch (e) {
      dLog('[CodingToolsService] read_file FileSystemException: ${e.osError?.message ?? e.message}');
      return CodingToolResult.error('Cannot read "$safeRaw": ${e.osError?.message ?? 'I/O error'}.');
    }
  }

  Future<CodingToolResult> _listDir(Map<String, dynamic> args, String projectPath) async {
    final raw = args['path'];
    if (raw is! String || raw.isEmpty) return CodingToolResult.error('list_dir requires a non-empty "path"');
    final safeRaw = _sanitize(raw);
    final recursive = args['recursive'] == true;
    final abs = _resolve(raw, projectPath);
    final denylist = await _loadEffectiveDenylist();

    try {
      // Allow the project root itself; assertWithinProject only accepts paths
      // _under_ the root (i.e. with a separator), so check separately.
      final normalAbs = p.normalize(p.absolute(abs));
      final normalRoot = p.normalize(p.absolute(projectPath));
      if (normalAbs != normalRoot) {
        ApplyRepository.assertWithinProject(abs, projectPath);
        _assertNotDenied(abs, projectPath, denylist);
      } else if (!await _repo.directoryExists(normalRoot)) {
        throw ProjectMissingException(projectPath);
      }
      if (!await _repo.directoryExists(abs)) {
        return CodingToolResult.error('"$safeRaw" is not a directory or does not exist.');
      }
      final entries = await _repo.listDirectory(abs, recursive: recursive);
      final buffer = StringBuffer();
      var count = 0;
      for (final entry in entries) {
        final rel = p.relative(entry.path, from: abs);
        final depth = rel.split(p.separator).length;
        if (recursive && depth > _kMaxListDepth) continue;
        // Filter: never reveal denied entries in the listing. The model
        // should not learn a `.env` exists.
        if (_isDeniedRel(p.relative(entry.path, from: projectPath), denylist)) continue;
        final String typeStr;
        try {
          typeStr = entry.statSync().type.toString().split('.').last;
        } on FileSystemException catch (e) {
          dLog('[CodingToolsService] list_dir stat failed for "${entry.path}": ${e.osError?.message ?? e.message}');
          continue;
        }
        buffer.writeln('- $rel ($typeStr)');
        count++;
        if (count >= _kMaxListEntries) {
          buffer.writeln('(truncated, $_kMaxListEntries+ entries)');
          break;
        }
      }
      return CodingToolResult.success(buffer.toString().trimRight());
    } on PathEscapeException {
      return CodingToolResult.error('Path "$safeRaw" is outside the project root.');
    } on BlockedPathException {
      return CodingToolResult.error('Listing "$safeRaw" is blocked for safety (sensitive directory).');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } on FileSystemException catch (e) {
      dLog('[CodingToolsService] list_dir FileSystemException: ${e.osError?.message ?? e.message}');
      return CodingToolResult.error('Cannot list "$safeRaw": ${e.osError?.message ?? 'I/O error'}.');
    }
  }

  Future<CodingToolResult> _writeFile(
    Map<String, dynamic> args,
    String projectPath,
    String sessionId,
    String messageId,
  ) async {
    final raw = args['path'];
    final content = args['content'];
    if (raw is! String || raw.isEmpty) return CodingToolResult.error('write_file requires a non-empty "path"');
    if (content is! String) return CodingToolResult.error('write_file requires a string "content"');
    final safeRaw = _sanitize(raw);
    final abs = _resolve(raw, projectPath);
    final denylist = await _loadEffectiveDenylist();

    try {
      ApplyRepository.assertWithinProject(abs, projectPath);
      _assertNotDenied(abs, projectPath, denylist);
      await _apply.applyChange(
        filePath: abs,
        projectPath: projectPath,
        newContent: content,
        sessionId: sessionId,
        messageId: messageId,
      );
      final bytes = utf8.encode(content).length;
      return CodingToolResult.success('Wrote $bytes bytes to $safeRaw.');
    } on PathEscapeException {
      return CodingToolResult.error('Path "$safeRaw" is outside the project root.');
    } on BlockedPathException {
      return CodingToolResult.error('Writing "$safeRaw" is blocked for safety (sensitive file).');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } on ApplyTooLargeException catch (e) {
      return CodingToolResult.error('File too large (${e.bytes} bytes).');
    } on FileSystemException catch (e) {
      dLog('[CodingToolsService] write_file FileSystemException: ${e.osError?.message ?? e.message}');
      return CodingToolResult.error('Cannot write "$safeRaw": ${e.osError?.message ?? 'I/O error'}.');
    }
  }

  Future<CodingToolResult> _strReplace(
    Map<String, dynamic> args,
    String projectPath,
    String sessionId,
    String messageId,
  ) async {
    final raw = args['path'];
    final oldStr = args['old_str'];
    final newStr = args['new_str'];
    if (raw is! String || raw.isEmpty) return CodingToolResult.error('str_replace requires a non-empty "path"');
    if (oldStr is! String || oldStr.isEmpty) return CodingToolResult.error('str_replace requires "old_str"');
    if (newStr is! String) return CodingToolResult.error('str_replace requires "new_str"');
    final safeRaw = _sanitize(raw);
    final abs = _resolve(raw, projectPath);
    final denylist = await _loadEffectiveDenylist();

    try {
      ApplyRepository.assertWithinProject(abs, projectPath);
      _assertNotDenied(abs, projectPath, denylist);
      final original = await _repo.readTextFile(abs);
      final matchCount = _countOccurrences(original, oldStr);
      if (matchCount == 0) {
        return CodingToolResult.error('old_str not found in $safeRaw. The match must be exact, including whitespace.');
      }
      if (matchCount > 1) {
        return CodingToolResult.error(
          'old_str matches $matchCount times in $safeRaw. Include more surrounding context to make it unique.',
        );
      }
      final updated = original.replaceFirst(oldStr, newStr);
      await _apply.applyChange(
        filePath: abs,
        projectPath: projectPath,
        newContent: updated,
        sessionId: sessionId,
        messageId: messageId,
      );
      return CodingToolResult.success('Replaced 1 match in $safeRaw.');
    } on PathEscapeException {
      return CodingToolResult.error('Path "$safeRaw" is outside the project root.');
    } on BlockedPathException {
      return CodingToolResult.error('Editing "$safeRaw" is blocked for safety (sensitive file).');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } on PathNotFoundException {
      return CodingToolResult.error('File "$safeRaw" does not exist.');
    } on FormatException {
      return CodingToolResult.error('File "$safeRaw" is not text-encoded.');
    } on ApplyTooLargeException catch (e) {
      return CodingToolResult.error('File too large (${e.bytes} bytes).');
    } on FileSystemException catch (e) {
      dLog('[CodingToolsService] str_replace FileSystemException: ${e.osError?.message ?? e.message}');
      return CodingToolResult.error('Cannot edit "$safeRaw": ${e.osError?.message ?? 'I/O error'}.');
    }
  }

  static int _countOccurrences(String haystack, String needle) {
    if (needle.isEmpty) return 0;
    var count = 0;
    var idx = 0;
    while ((idx = haystack.indexOf(needle, idx)) != -1) {
      count++;
      idx += needle.length;
    }
    return count;
  }
}
