import 'dart:convert';

import 'package:diff_match_patch/diff_match_patch.dart';
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

/// Owns all business logic for apply operations; [ApplyRepository] is reduced to raw I/O.
class ApplyService {
  ApplyService({required ApplyRepository repo, String Function()? uuidGen})
    : _repo = repo,
      _uuidGen = uuidGen ?? (() => const Uuid().v4());

  final ApplyRepository _repo;
  final String Function() _uuidGen;

  /// Applies [newContent] to [filePath], snapshots the original for revert,
  /// and returns the recorded [AppliedChange]. Throws [PathEscapeException],
  /// [ProjectMissingException], [ApplyTooLargeException], [ApplyDiskException],
  /// or [ApplyContentChangedException] on guard or I/O failures.
  ///
  /// When [expectedChecksum] is non-null and the file exists, the on-disk
  /// content is verified against the checksum before writing. If they differ
  /// (indicating an external modification since the caller last read the file),
  /// [ApplyContentChangedException] is thrown and the file is left unchanged.
  Future<AppliedChange> applyChange({
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
    String? expectedChecksum,
  }) async {
    ApplyRepository.assertWithinProject(filePath, projectPath);

    final newByteLen = utf8.encode(newContent).length;
    if (newByteLen > kMaxApplyContentBytes) {
      throw ApplyTooLargeException(newByteLen);
    }

    // null = file does not exist yet (new-file apply)
    final originalContent = await _repo.readFile(filePath);

    if (originalContent != null) {
      final originalByteLen = utf8.encode(originalContent).length;
      if (originalByteLen > kMaxApplyContentBytes) {
        throw ApplyTooLargeException(originalByteLen);
      }
      if (expectedChecksum != null && ApplyRepository.sha256OfString(originalContent) != expectedChecksum) {
        throw const ApplyContentChangedException();
      }
    }

    await _repo.writeFile(filePath, newContent);

    final (additions, deletions) = _computeLineCounts(originalContent, newContent);
    final checksum = ApplyRepository.sha256OfString(newContent);

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
    ApplyRepository.assertWithinProject(change.filePath, projectPath);
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
    ApplyRepository.assertWithinProject(filePath, projectPath);
    try {
      return await _repo.readFile(filePath);
    } on ApplyDiskException catch (e) {
      dLog('[ApplyService] readFileContent failed: $e');
      return null;
    }
  }

  /// Returns current on-disk content of [absolutePath] for diff rendering.
  /// Returns `null` when the file does not exist yet (new-file apply).
  /// Throws [ApplyDiskException] on other I/O failures.
  Future<String?> readOriginalForDiff(String absolutePath, String projectPath) async {
    ApplyRepository.assertWithinProject(absolutePath, projectPath);
    try {
      return await _repo.readFile(absolutePath);
    } on ApplyDiskException catch (e) {
      dLog('[ApplyService] readOriginalForDiff failed: $e');
      rethrow;
    }
  }

  /// Returns `true` if [filePath] no longer matches [storedChecksum].
  /// A missing file or read error also returns `true`.
  Future<bool> isExternallyModified(String filePath, String storedChecksum) async {
    try {
      final current = await _repo.readFile(filePath);
      if (current == null) return true;
      return ApplyRepository.sha256OfString(current) != storedChecksum;
    } on ApplyDiskException catch (e) {
      dLog('[ApplyService] isExternallyModified read failed: ${e.runtimeType}');
      return true;
    }
  }

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
