import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/project/models/project.dart';
import '../../data/project/models/project_action.dart';
import '../../data/project/repository/project_repository.dart';
import '../../data/project/repository/project_repository_impl.dart';
import 'project_exceptions.dart';

export 'project_exceptions.dart';

part 'project_service.g.dart';

@Riverpod(keepAlive: true)
ProjectService projectService(Ref ref) {
  return ProjectService(repo: ref.watch(projectRepositoryProvider));
}

/// Owns duplicate-path detection, relocate policy, and folder-creation
/// orchestration. [ProjectRepository] is reduced to pure I/O.
class ProjectService {
  ProjectService({required ProjectRepository repo}) : _repo = repo;

  final ProjectRepository _repo;

  Stream<List<Project>> watchAllProjects() => _repo.watchAllProjects();

  Future<Project> addExistingFolder(String directoryPath) async {
    final existing = await _repo.watchAllProjects().first;
    if (existing.any((p) => p.path == directoryPath)) {
      throw DuplicateProjectPathException(directoryPath);
    }
    try {
      return await _repo.addExistingFolder(directoryPath);
    } on FileSystemException catch (e) {
      final code = e.osError?.errorCode;
      if (code == 1 || code == 13) {
        dLog('[ProjectService] TCC denied addExistingFolder("$directoryPath") (errno $code)');
        throw ProjectPermissionDeniedException(directoryPath);
      }
      rethrow;
    }
  }

  Future<Project> createNewFolder(String parentPath, String folderName) async {
    final fullPath = '$parentPath/$folderName';
    final existing = await _repo.watchAllProjects().first;
    if (existing.any((p) => p.path == fullPath)) {
      throw DuplicateProjectPathException(fullPath);
    }
    return _repo.createNewFolder(parentPath, folderName);
  }

  Future<void> relocateProject(String projectId, String newPath) async {
    final existing = await _repo.watchAllProjects().first;
    if (existing.any((p) => p.path == newPath && p.id != projectId)) {
      throw DuplicateProjectPathException(newPath);
    }
    return _repo.relocateProject(projectId, newPath);
  }

  Future<void> removeProject(String projectId) => _repo.removeProject(projectId);

  Future<void> updateProjectActions(String projectId, List<ProjectAction> actions) =>
      _repo.updateProjectActions(projectId, actions);

  Future<void> refreshProjectStatuses() => _repo.refreshProjectStatuses();

  Future<void> refreshProjectStatus(String projectId) => _repo.refreshProjectStatus(projectId);

  Future<void> deleteAllProjects() => _repo.deleteAllProjects();

  /// Returns `true` when the folder at [path] currently exists on disk.
  /// Returns `false` (rather than throwing) when macOS TCC denies the read,
  /// since this is used by widgets for fast best-effort availability checks.
  bool projectExistsOnDisk(String path) {
    try {
      return Directory(path).existsSync();
    } on FileSystemException {
      return false;
    }
  }

  /// Resolves [path] to its canonical real path. Throws
  /// [ProjectPermissionDeniedException] when macOS TCC blocks the read, or
  /// [ArgumentError] for other I/O failures and non-directories.
  String resolveDroppedDirectory(String path) {
    final String resolved;
    try {
      resolved = Directory(path).resolveSymbolicLinksSync();
    } on FileSystemException catch (e) {
      // macOS TCC denial reports EPERM (1) or EACCES (13) via OSError.
      final code = e.osError?.errorCode;
      if (code == 1 || code == 13) {
        dLog('[ProjectService] TCC denied access to "$path" (errno $code)');
        throw ProjectPermissionDeniedException(path);
      }
      dLog('[ProjectService] resolveDroppedDirectory failed for "$path": $e');
      throw ArgumentError('That path could not be opened');
    }
    if (!FileSystemEntity.isDirectorySync(resolved)) {
      throw ArgumentError('Please drop a folder, not a file');
    }
    return resolved;
  }
}
