import 'dart:async';
import 'dart:io';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart' as app_errors;
import '../../../core/utils/debug_logger.dart';
import '../../../data/models/applied_change.dart';
import '../../filesystem/repository/filesystem_repository.dart';
import '../../filesystem/repository/filesystem_repository_impl.dart';
import 'apply_repository.dart';

part 'apply_repository_impl.g.dart';

/// Hard cap on the size of content that can be applied in a single operation.
const int kMaxApplyContentBytes = 1024 * 1024;

/// Timeout for `git checkout --` during revert.
const Duration kGitCheckoutTimeout = Duration(seconds: 15);

typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments, {String? workingDirectory});

@Riverpod(keepAlive: true)
ApplyRepository applyRepository(Ref ref) {
  return ApplyRepositoryImpl(fs: ref.watch(filesystemRepositoryProvider));
}

class ApplyRepositoryImpl implements ApplyRepository {
  ApplyRepositoryImpl({required FilesystemRepository fs, String Function()? uuidGen, ProcessRunner? processRunner})
    : _fs = fs,
      _uuidGen = uuidGen ?? (() => const Uuid().v4()),
      _processRunner = processRunner ?? Process.run;

  final FilesystemRepository _fs;
  final String Function() _uuidGen;
  final ProcessRunner _processRunner;

  @override
  Future<AppliedChange> applyChange({
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    ApplyRepository.assertWithinProject(filePath, projectPath);

    if (newContent.length > kMaxApplyContentBytes) {
      throw StateError(
        'Content too large to apply: ${newContent.length} bytes exceeds '
        'limit of $kMaxApplyContentBytes bytes',
      );
    }

    String? originalContent;
    try {
      originalContent = await _fs.readFile(filePath);
    } on app_errors.FileSystemException catch (e) {
      if (e.originalError is PathNotFoundException) {
        originalContent = null;
      } else {
        rethrow;
      }
    }

    if (originalContent != null && originalContent.length > kMaxApplyContentBytes) {
      throw StateError(
        'Original file too large to snapshot for revert: '
        '${originalContent.length} bytes exceeds limit of '
        '$kMaxApplyContentBytes bytes',
      );
    }

    if (originalContent == null) {
      await _fs.createDirectory(p.dirname(filePath));
    }
    await _fs.writeFile(filePath, newContent);

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

  @override
  Future<void> revertChange({required AppliedChange change, required bool isGit, required String projectPath}) async {
    ApplyRepository.assertWithinProject(change.filePath, projectPath);
    if (change.originalContent == null) {
      await _fs.deleteFile(change.filePath);
    } else if (isGit) {
      final ProcessResult result;
      try {
        result = await _processRunner('git', [
          'checkout',
          '--',
          change.filePath,
        ], workingDirectory: projectPath).timeout(kGitCheckoutTimeout);
      } on TimeoutException {
        throw StateError('git checkout timed out after ${kGitCheckoutTimeout.inSeconds}s');
      }
      if (result.exitCode != 0) {
        throw StateError('git checkout failed (exit ${result.exitCode}): ${result.stderr}');
      }
    } else {
      await _fs.writeFile(change.filePath, change.originalContent!);
    }
  }

  @override
  Future<String?> readFileContent(String filePath, String projectPath) async {
    ApplyRepository.assertWithinProject(filePath, projectPath);
    try {
      return await _fs.readFile(filePath);
    } on app_errors.FileSystemException catch (e) {
      dLog('[ApplyRepositoryImpl] readFileContent failed: $e');
      return null;
    }
  }

  @override
  Future<String?> readOriginalForDiff(String absolutePath, String projectPath) async {
    ApplyRepository.assertWithinProject(absolutePath, projectPath);
    try {
      return await _fs.readFile(absolutePath);
    } on app_errors.FileSystemException catch (e) {
      if (e.originalError is PathNotFoundException) return null;
      dLog('[ApplyRepositoryImpl] readOriginalForDiff failed: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<bool> isExternallyModified(String filePath, String storedChecksum) async {
    try {
      final current = await _fs.readFile(filePath);
      return ApplyRepository.sha256OfString(current) != storedChecksum;
    } on app_errors.FileSystemException catch (e) {
      if (e.originalError is PathNotFoundException) return true;
      dLog('[ApplyRepositoryImpl] isExternallyModified read failed: ${e.runtimeType}');
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
