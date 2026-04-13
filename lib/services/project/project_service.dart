import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/models/project.dart';
import '../../data/models/project_action.dart';
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
    return _repo.addExistingFolder(directoryPath);
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

  // ── Filesystem helpers ────────────────────────────────────────────────────

  /// Returns `true` when the folder at [path] currently exists on disk.
  bool projectExistsOnDisk(String path) => Directory(path).existsSync();

  /// Resolves [path] to its canonical real path and confirms it is a
  /// directory. Returns the resolved path on success.
  ///
  /// Throws [ArgumentError] with a user-facing message on failure.
  String resolveDroppedDirectory(String path) {
    final String resolved;
    try {
      resolved = Directory(path).resolveSymbolicLinksSync();
    } catch (e) {
      dLog('[ProjectService] resolveDroppedDirectory failed for "$path": $e');
      throw ArgumentError('That path could not be opened');
    }
    if (!FileSystemEntity.isDirectorySync(resolved)) {
      throw ArgumentError('Please drop a folder, not a file');
    }
    return resolved;
  }
}
