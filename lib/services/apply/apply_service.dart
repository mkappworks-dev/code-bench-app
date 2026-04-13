import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/apply/repository/apply_repository.dart';
import '../../data/apply/repository/apply_repository_impl.dart';
import '../../data/apply/models/applied_change.dart';
import 'apply_exceptions.dart';

export 'apply_exceptions.dart';

part 'apply_service.g.dart';

@Riverpod(keepAlive: true)
ApplyService applyService(Ref ref) {
  return ApplyService(repo: ref.watch(applyRepositoryProvider));
}

/// Service owning all business logic for file apply operations:
/// path-traversal guards, size limits, checksum computation, and
/// diff line-count calculation. [ApplyRepository] is reduced to
/// raw I/O (read/write/delete/gitCheckout).
class ApplyService {
  ApplyService({required ApplyRepository repo, String Function()? uuidGen})
    : _repo = repo,
      _uuidGen = uuidGen ?? (() => const Uuid().v4());

  final ApplyRepository _repo;
  final String Function() _uuidGen;

  // ── Static utilities ─────────────────────────────────────────────────────

  /// Throws [PathEscapeException] if [filePath] is not lexically and
  /// physically inside [projectPath]. Guards against path-traversal attacks
  /// from AI-controlled filenames. Permitted in widgets per CLAUDE.md.
  static void assertWithinProject(String filePath, String projectPath) {
    final lexFile = p.normalize(p.absolute(filePath));
    final lexRoot = p.normalize(p.absolute(projectPath));
    final lexRootWithSep = lexRoot + p.separator;
    if (!lexFile.startsWith(lexRootWithSep)) {
      sLog('[assertWithinProject] lexical reject: "$filePath" outside "$projectPath"');
      throw PathEscapeException(filePath, projectPath);
    }

    final rootDir = Directory(lexRoot);
    if (!rootDir.existsSync()) {
      throw ProjectMissingException(projectPath);
    }
    final rootReal = rootDir.resolveSymbolicLinksSync();

    var probe = Directory(p.dirname(lexFile));
    while (!probe.existsSync()) {
      final parent = probe.parent;
      if (parent.path == probe.path) break;
      probe = parent;
    }
    String probeReal;
    try {
      probeReal = probe.resolveSymbolicLinksSync();
    } on FileSystemException {
      sLog('[assertWithinProject] symlink resolve failed: "$filePath"');
      throw PathEscapeException(filePath, projectPath);
    }
    final rootRealWithSep = rootReal + p.separator;
    if (probeReal != rootReal && !probeReal.startsWith(rootRealWithSep)) {
      sLog('[assertWithinProject] symlink escape: "$filePath" → "$probeReal" outside "$rootReal"');
      throw PathEscapeException(filePath, projectPath);
    }
  }

  /// Returns the SHA-256 hex digest of [content].
  static String sha256OfString(String content) {
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }

  // ── Core operations ──────────────────────────────────────────────────────

  /// Applies [newContent] to [filePath], snapshots the original for revert,
  /// and returns the recorded [AppliedChange].
  ///
  /// Throws:
  /// - [PathEscapeException] for path-traversal violations.
  /// - [ProjectMissingException] when the project root is gone.
  /// - [ApplyTooLargeException] when content exceeds [kMaxApplyContentBytes].
  /// - [FileSystemException] on disk write failure.
  Future<AppliedChange> applyChange({
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    assertWithinProject(filePath, projectPath);

    final newByteLen = utf8.encode(newContent).length;
    if (newByteLen > kMaxApplyContentBytes) {
      throw ApplyTooLargeException(newByteLen);
    }

    String? originalContent;
    try {
      originalContent = await _repo.readFile(filePath);
    } on PathNotFoundException {
      originalContent = null;
    } on FileSystemException {
      rethrow;
    }

    if (originalContent != null) {
      final originalByteLen = utf8.encode(originalContent).length;
      if (originalByteLen > kMaxApplyContentBytes) {
        throw ApplyTooLargeException(originalByteLen);
      }
    }

    await _repo.writeFile(filePath, newContent);

    final (additions, deletions) = _computeLineCounts(originalContent, newContent);
    final checksum = sha256OfString(newContent);

    return AppliedChange(
      id: _uuidGen(),
      sessionId: sessionId,
      messageId: messageId,
      filePath: filePath,
      originalContent: originalContent,
      newContent: newContent,
      appliedAt: DateTime.now(),
      additions: additions,
      deletions: deletions,
      contentChecksum: checksum,
    );
  }

  /// Reverts [change] using git checkout (when [isGit]) or by restoring
  /// [AppliedChange.originalContent]. Deletes the file when originalContent
  /// is null (file was created by apply).
  Future<void> revertChange({required AppliedChange change, required bool isGit, required String projectPath}) async {
    assertWithinProject(change.filePath, projectPath);
    if (change.originalContent == null) {
      await _repo.deleteFile(change.filePath);
    } else if (isGit) {
      await _repo.gitCheckout(change.filePath, projectPath);
    } else {
      await _repo.writeFile(change.filePath, change.originalContent!);
    }
  }

  /// Returns current on-disk content of [filePath] for the conflict-merge
  /// view. Returns `null` if the file cannot be read.
  Future<String?> readFileContent(String filePath, String projectPath) async {
    assertWithinProject(filePath, projectPath);
    try {
      return await _repo.readFile(filePath);
    } on PathNotFoundException {
      return null;
    } on FileSystemException catch (e) {
      dLog('[ApplyService] readFileContent failed: $e');
      return null;
    }
  }

  /// Returns current on-disk content of [absolutePath] for diff rendering.
  /// Returns `null` when the file does not exist yet (new-file apply).
  Future<String?> readOriginalForDiff(String absolutePath, String projectPath) async {
    assertWithinProject(absolutePath, projectPath);
    try {
      return await _repo.readFile(absolutePath);
    } on PathNotFoundException {
      return null;
    } on FileSystemException catch (e) {
      dLog('[ApplyService] readOriginalForDiff failed: ${e.message}');
      rethrow;
    }
  }

  /// Returns `true` if [filePath] no longer matches [storedChecksum].
  /// A missing file or read error also returns `true`.
  Future<bool> isExternallyModified(String filePath, String storedChecksum) async {
    try {
      final current = await _repo.readFile(filePath);
      return sha256OfString(current) != storedChecksum;
    } on PathNotFoundException {
      return true;
    } on FileSystemException catch (e) {
      dLog('[ApplyService] isExternallyModified read failed: ${e.runtimeType}');
      return true;
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  static (int additions, int deletions) _computeLineCounts(String? original, String newContent) {
    final a = original ?? '';
    final aLines = a.isEmpty ? <String>[] : a.split('\n');
    final bLines = newContent.isEmpty ? <String>[] : newContent.split('\n');

    final lineToChar = <String, String>{};
    final charArray = <String>[''];
    String encode(List<String> lines) {
      final buf = StringBuffer();
      for (final line in lines) {
        if (!lineToChar.containsKey(line)) {
          charArray.add(line);
          lineToChar[line] = String.fromCharCode(charArray.length - 1);
        }
        buf.write(lineToChar[line]);
      }
      return buf.toString();
    }

    final encA = encode(aLines);
    final encB = encode(bLines);

    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(encA, encB, false);
    dmp.diffCleanupSemantic(diffs);

    var additions = 0;
    var deletions = 0;
    for (final d in diffs) {
      if (d.operation == DIFF_INSERT)
        additions += d.text.length;
      else if (d.operation == DIFF_DELETE)
        deletions += d.text.length;
    }
    return (additions, deletions);
  }
}
