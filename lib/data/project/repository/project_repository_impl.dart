import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/_core/app_database.dart';
import '../../../data/models/project.dart';
import '../../../data/models/project_action.dart';
import '../datasource/project_datasource.dart';
import '../datasource/project_datasource_drift.dart';
import '../datasource/project_fs_datasource.dart';
import '../datasource/project_fs_datasource_io.dart';
import 'project_repository.dart';

part 'project_repository_impl.g.dart';

/// Thrown when attempting to add a project whose folder path is already
/// tracked by another project entry.
class DuplicateProjectPathException implements Exception {
  DuplicateProjectPathException(this.path);
  final String path;

  @override
  String toString() => 'A project at "$path" already exists in Code Bench.';
}

@Riverpod(keepAlive: true)
ProjectRepository projectRepository(Ref ref) {
  return ProjectRepositoryImpl(db: ref.watch(projectDatasourceProvider), fs: ref.watch(projectFsDatasourceProvider));
}

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl({required ProjectDatasource db, required ProjectFsDatasource fs}) : _db = db, _fs = fs;

  final ProjectDatasource _db;
  final ProjectFsDatasource _fs;
  static const _uuid = Uuid();

  @override
  Stream<List<Project>> watchAllProjects() {
    return _db.watchAllProjectRows().map((rows) => rows.map(_toDomain).toList());
  }

  Project _toDomain(WorkspaceProjectRow row) {
    List<ProjectAction> actions = const [];
    // We write this column ourselves as jsonEncode(...) in
    // updateProjectActions, so a decode failure here means either manual
    // DB tampering, a serializer regression, or a schema bug. Log via
    // `sLog` (not `dLog`) so the breadcrumb persists into release builds —
    // otherwise a production user's project rows would silently render
    // with zero actions and the bug would be invisible at triage time.
    try {
      final decoded = jsonDecode(row.actionsJson) as List<dynamic>;
      actions = decoded.map((e) => ProjectAction.fromJson(e as Map<String, dynamic>)).toList();
    } on FormatException catch (e) {
      sLog('[ProjectRepository] actionsJson FormatException for ${row.id}: $e');
    } on TypeError catch (e) {
      sLog('[ProjectRepository] actionsJson TypeError for ${row.id}: $e');
    }

    final status = _fs.exists(row.path) ? ProjectStatus.available : ProjectStatus.missing;

    return Project(
      id: row.id,
      name: row.name,
      path: row.path,
      createdAt: row.createdAt,
      sortOrder: row.sortOrder,
      actions: actions,
      status: status,
    );
  }

  @override
  Future<Project> addExistingFolder(String directoryPath) async {
    if (!_fs.exists(directoryPath)) {
      throw ArgumentError('Directory does not exist: $directoryPath');
    }

    final existing = await _db.getProjectRowByPath(directoryPath);
    if (existing != null) {
      throw DuplicateProjectPathException(directoryPath);
    }

    final id = _uuid.v4();
    final segments = directoryPath.split('/');
    final name = segments.lastWhere((s) => s.isNotEmpty, orElse: () => directoryPath);

    await _db.upsertProjectRow(
      WorkspaceProjectsCompanion(
        id: Value(id),
        name: Value(name),
        path: Value(directoryPath),
        createdAt: Value(DateTime.now()),
        sortOrder: Value(0),
      ),
    );

    return Project(id: id, name: name, path: directoryPath, createdAt: DateTime.now());
  }

  @override
  Future<Project> createNewFolder(String parentPath, String folderName) async {
    final fullPath = '$parentPath/$folderName';
    if (!_fs.exists(fullPath)) {
      await _fs.createDirectory(fullPath);
    }
    return addExistingFolder(fullPath);
  }

  @override
  Future<void> removeProject(String projectId) async {
    // Only removes from the database — does NOT delete the folder from disk
    await _db.deleteProjectRow(projectId);
  }

  @override
  Future<void> updateProjectActions(String projectId, List<ProjectAction> actions) async {
    final json = jsonEncode(actions.map((a) => a.toJson()).toList());
    await _db.updateProjectRow(projectId, WorkspaceProjectsCompanion(actionsJson: Value(json)));
  }

  /// Touches every project row with a no-op write so Drift re-emits the
  /// `watchAllProjects` stream. Call this after operations that may have
  /// changed filesystem state outside the app (e.g. the user deleted a
  /// folder in Finder while Code Bench was running).
  @override
  Future<void> refreshProjectStatuses() async {
    final rows = await _db.getAllProjectRows();
    for (final r in rows) {
      await _db.updateProjectRow(r.id, WorkspaceProjectsCompanion(sortOrder: Value(r.sortOrder)));
    }
  }

  /// Single-project variant of [refreshProjectStatuses]. Call this at the
  /// moment a missing folder is detected (e.g. from the write-button guard
  /// or an `ApplyService` `ProjectMissingException`) so the sidebar flips
  /// to the "missing" visual state without waiting for app resume.
  /// No-ops silently if the project id is unknown.
  @override
  Future<void> refreshProjectStatus(String projectId) async {
    final row = await _db.getProjectRow(projectId);
    if (row == null) return;
    await _db.updateProjectRow(projectId, WorkspaceProjectsCompanion(sortOrder: Value(row.sortOrder)));
  }

  /// Point an existing project at a new folder on disk. Used by the
  /// "Relocate…" action when the user has moved or restored a project
  /// folder under a different path. Git state for the new path is derived
  /// live by `gitLiveStateProvider` — no persisted flags to update.
  @override
  Future<void> relocateProject(String projectId, String newPath) async {
    if (!_fs.exists(newPath)) {
      throw ArgumentError('Directory does not exist: $newPath');
    }

    final existing = await _db.getProjectRowByPath(newPath);
    if (existing != null && existing.id != projectId) {
      throw DuplicateProjectPathException(newPath);
    }

    await _db.updateProjectRow(projectId, WorkspaceProjectsCompanion(path: Value(newPath)));
  }

  /// Deletes every project row. Used by the "Wipe all data" action.
  @override
  Future<void> deleteAllProjects() => _db.deleteAllProjectRows();
}
