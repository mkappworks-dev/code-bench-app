import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart' as app_errors;
import '../../../core/utils/debug_logger.dart';
import '../../filesystem/repository/filesystem_repository.dart';
import '../../filesystem/repository/filesystem_repository_impl.dart';
import 'apply_repository.dart';

part 'apply_repository_impl.g.dart';

/// Timeout for `git checkout --` during revert.
const Duration kGitCheckoutTimeout = Duration(seconds: 15);

typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments, {String? workingDirectory});

@Riverpod(keepAlive: true)
ApplyRepository applyRepository(Ref ref) {
  return ApplyRepositoryImpl(fs: ref.watch(filesystemRepositoryProvider));
}

class ApplyRepositoryImpl implements ApplyRepository {
  ApplyRepositoryImpl({required FilesystemRepository fs, ProcessRunner? processRunner})
    : _fs = fs,
      _processRunner = processRunner ?? Process.run;

  final FilesystemRepository _fs;
  final ProcessRunner _processRunner;

  @override
  Future<String> readFile(String path) async {
    try {
      return await _fs.readFile(path);
    } on app_errors.FileSystemException catch (e) {
      if (e.originalError is PathNotFoundException) {
        throw e.originalError! as PathNotFoundException;
      }
      // Translate to dart:io FileSystemException so callers can use a single
      // exception hierarchy without importing app_errors.
      throw FileSystemException(e.message, path);
    }
  }

  @override
  Future<void> writeFile(String path, String content) async {
    await _fs.createDirectory(p.dirname(path));
    await _fs.writeFile(path, content);
  }

  @override
  Future<void> deleteFile(String path) async {
    await _fs.deleteFile(path);
  }

  @override
  Future<void> gitCheckout(String filePath, String workingDirectory) async {
    final ProcessResult result;
    try {
      result = await _processRunner('git', [
        'checkout',
        '--',
        filePath,
      ], workingDirectory: workingDirectory).timeout(kGitCheckoutTimeout);
    } on TimeoutException {
      dLog('[ApplyRepository] gitCheckout timed out for $filePath');
      throw StateError('git checkout timed out after ${kGitCheckoutTimeout.inSeconds}s');
    }
    if (result.exitCode != 0) {
      dLog('[ApplyRepository] gitCheckout failed (exit ${result.exitCode}): ${result.stderr}');
      throw StateError('git checkout failed (exit ${result.exitCode}): ${result.stderr}');
    }
  }
}
