import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart' as app_errors;
import '../../filesystem/repository/filesystem_repository.dart';
import '../../filesystem/repository/filesystem_repository_impl.dart';
import '../apply_exceptions.dart';
import '../datasource/apply_git_datasource_process.dart';
import 'apply_repository.dart';

part 'apply_repository_impl.g.dart';

@Riverpod(keepAlive: true)
ApplyRepository applyRepository(Ref ref) {
  return ApplyRepositoryImpl(fs: ref.watch(filesystemRepositoryProvider));
}

class ApplyRepositoryImpl implements ApplyRepository {
  ApplyRepositoryImpl({required FilesystemRepository fs, ApplyGitDatasource? git})
    : _fs = fs,
      _git = git ?? ApplyGitDatasource();

  final FilesystemRepository _fs;
  final ApplyGitDatasource _git;

  /// Returns file content, or `null` if the file does not exist.
  /// Throws [ApplyDiskException] for other I/O failures.
  @override
  Future<String?> readFile(String path) async {
    try {
      return await _fs.readFile(path);
    } on app_errors.FileNotFoundException {
      return null;
    } on app_errors.FileSystemException catch (e) {
      throw ApplyDiskException(e.message);
    }
  }

  @override
  Future<void> writeFile(String path, String content) async {
    try {
      await _fs.createDirectory(p.dirname(path));
      await _fs.writeFile(path, content);
    } on app_errors.FileSystemException catch (e) {
      throw ApplyDiskException(e.message);
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    try {
      await _fs.deleteFile(path);
    } on app_errors.FileSystemException catch (e) {
      throw ApplyDiskException(e.message);
    }
  }

  @override
  Future<void> gitCheckout(String filePath, String workingDirectory) => _git.gitCheckout(filePath, workingDirectory);
}
