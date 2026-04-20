import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/coding_tools/models/coding_tool_result.dart';
import '../../data/coding_tools/repository/coding_tools_repository.dart';
import '../../data/coding_tools/repository/coding_tools_repository_impl.dart';
import '../apply/apply_service.dart';

export '../../data/coding_tools/models/coding_tool_result.dart';

part 'coding_tools_service.g.dart';

@Riverpod(keepAlive: true)
CodingToolsService codingToolsService(Ref ref) =>
    CodingToolsService(repo: ref.watch(codingToolsRepositoryProvider), applyService: ref.watch(applyServiceProvider));

/// Executes a single tool call. Each handler is path-guarded, size-capped,
/// and scrubs error messages before returning them to the loop.
class CodingToolsService {
  CodingToolsService({required CodingToolsRepository repo, required ApplyService applyService})
    : _repo = repo,
      _apply = applyService;

  final CodingToolsRepository _repo;
  final ApplyService _apply;

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
    } finally {
      dLog('[CodingToolsService] $toolName done in ${DateTime.now().difference(started).inMilliseconds}ms');
    }
  }

  String _resolve(String raw, String projectPath) =>
      p.isAbsolute(raw) ? p.normalize(raw) : p.normalize(p.join(projectPath, raw));

  Future<CodingToolResult> _readFile(Map<String, dynamic> args, String projectPath) async {
    final raw = args['path'];
    if (raw is! String || raw.isEmpty) return CodingToolResult.error('read_file requires a non-empty "path"');
    final abs = _resolve(raw, projectPath);

    try {
      ApplyService.assertWithinProject(abs, projectPath);
      final size = await _repo.fileSizeBytes(abs);
      if (size > _kMaxReadBytes) {
        return CodingToolResult.error(
          'File too large ($size bytes; max $_kMaxReadBytes bytes). Consider str_replace for targeted edits.',
        );
      }
      final content = await _repo.readTextFile(abs);
      return CodingToolResult.success(content);
    } on PathEscapeException {
      return CodingToolResult.error('Path "$raw" is outside the project root.');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } on PathNotFoundException {
      return CodingToolResult.error('File "$raw" does not exist.');
    } on FormatException {
      return CodingToolResult.error('File "$raw" is not text-encoded.');
    }
  }

  Future<CodingToolResult> _listDir(Map<String, dynamic> args, String projectPath) async {
    final raw = args['path'];
    if (raw is! String || raw.isEmpty) return CodingToolResult.error('list_dir requires a non-empty "path"');
    final recursive = args['recursive'] == true;
    final abs = _resolve(raw, projectPath);

    try {
      // Allow the project root itself; assertWithinProject only accepts paths
      // _under_ the root (i.e. with a separator), so check separately.
      final normalAbs = p.normalize(p.absolute(abs));
      final normalRoot = p.normalize(p.absolute(projectPath));
      if (normalAbs != normalRoot) {
        ApplyService.assertWithinProject(abs, projectPath);
      } else if (!Directory(normalRoot).existsSync()) {
        throw ProjectMissingException(projectPath);
      }
      if (!await _repo.directoryExists(abs)) {
        return CodingToolResult.error('"$raw" is not a directory or does not exist.');
      }
      final entries = await _repo.listDirectory(abs, recursive: recursive);
      final buffer = StringBuffer();
      var count = 0;
      for (final entry in entries) {
        final rel = p.relative(entry.path, from: abs);
        final depth = rel.split(p.separator).length;
        if (recursive && depth > _kMaxListDepth) continue;
        final typeStr = entry.statSync().type.toString().split('.').last;
        buffer.writeln('- $rel ($typeStr)');
        count++;
        if (count >= _kMaxListEntries) {
          buffer.writeln('(truncated, $_kMaxListEntries+ entries)');
          break;
        }
      }
      return CodingToolResult.success(buffer.toString().trimRight());
    } on PathEscapeException {
      return CodingToolResult.error('Path "$raw" is outside the project root.');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
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
    final abs = _resolve(raw, projectPath);

    try {
      await _apply.applyChange(
        filePath: abs,
        projectPath: projectPath,
        newContent: content,
        sessionId: sessionId,
        messageId: messageId,
      );
      final bytes = utf8.encode(content).length;
      return CodingToolResult.success('Wrote $bytes bytes to $raw.');
    } on PathEscapeException {
      return CodingToolResult.error('Path "$raw" is outside the project root.');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } on ApplyTooLargeException catch (e) {
      return CodingToolResult.error('File too large (${e.bytes} bytes).');
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
    final abs = _resolve(raw, projectPath);

    try {
      ApplyService.assertWithinProject(abs, projectPath);
      final original = await _repo.readTextFile(abs);
      final matchCount = _countOccurrences(original, oldStr);
      if (matchCount == 0) {
        return CodingToolResult.error('old_str not found in $raw. The match must be exact, including whitespace.');
      }
      if (matchCount > 1) {
        return CodingToolResult.error(
          'old_str matches $matchCount times in $raw. Include more surrounding context to make it unique.',
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
      return CodingToolResult.success('Replaced 1 match in $raw.');
    } on PathEscapeException {
      return CodingToolResult.error('Path "$raw" is outside the project root.');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } on PathNotFoundException {
      return CodingToolResult.error('File "$raw" does not exist.');
    } on FormatException {
      return CodingToolResult.error('File "$raw" is not text-encoded.');
    } on ApplyTooLargeException catch (e) {
      return CodingToolResult.error('File too large (${e.bytes} bytes).');
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
