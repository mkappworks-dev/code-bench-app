import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/_core/app_database.dart';
import 'project_datasource.dart';

part 'project_datasource_drift.g.dart';

@Riverpod(keepAlive: true)
ProjectDatasource projectDatasource(Ref ref) => ProjectDatasourceDrift(ref.watch(appDatabaseProvider));

class ProjectDatasourceDrift implements ProjectDatasource {
  ProjectDatasourceDrift(this._db);
  final AppDatabase _db;

  ProjectRow _toRow(WorkspaceProjectRow row) => ProjectRow(
    id: row.id,
    name: row.name,
    path: row.path,
    createdAt: row.createdAt,
    sortOrder: row.sortOrder,
    actionsJson: row.actionsJson,
  );

  @override
  Stream<List<ProjectRow>> watchAllProjectRows() =>
      _db.projectDao.watchAllProjects().map((rows) => rows.map(_toRow).toList());

  @override
  Future<List<ProjectRow>> getAllProjectRows() async => (await _db.projectDao.getAllProjects()).map(_toRow).toList();

  @override
  Future<ProjectRow?> getProjectRow(String id) async {
    final row = await _db.projectDao.getProject(id);
    return row == null ? null : _toRow(row);
  }

  @override
  Future<ProjectRow?> getProjectRowByPath(String path) async {
    final row = await _db.projectDao.getProjectByPath(path);
    return row == null ? null : _toRow(row);
  }

  @override
  Future<void> upsertProject({
    required String id,
    required String name,
    required String path,
    required DateTime createdAt,
    int sortOrder = 0,
  }) => _db.projectDao.upsertProject(
    WorkspaceProjectsCompanion(
      id: Value(id),
      name: Value(name),
      path: Value(path),
      createdAt: Value(createdAt),
      sortOrder: Value(sortOrder),
    ),
  );

  @override
  Future<void> updateProjectActions(String id, String actionsJson) =>
      _db.projectDao.updateProject(id, WorkspaceProjectsCompanion(actionsJson: Value(actionsJson)));

  @override
  Future<void> updateProjectPath(String id, String newPath) =>
      _db.projectDao.updateProject(id, WorkspaceProjectsCompanion(path: Value(newPath)));

  @override
  Future<void> updateProjectSortOrder(String id, int sortOrder) =>
      _db.projectDao.updateProject(id, WorkspaceProjectsCompanion(sortOrder: Value(sortOrder)));

  @override
  Future<void> deleteProjectRow(String id) => _db.projectDao.deleteProject(id);

  @override
  Future<void> deleteAllProjectRows() => _db.projectDao.deleteAllProjects();
}
