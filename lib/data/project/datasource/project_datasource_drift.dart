import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/_core/app_database.dart';
import 'project_datasource.dart';

part 'project_datasource_drift.g.dart';

@Riverpod(keepAlive: true)
ProjectDatasource projectDatasource(Ref ref) => ProjectDatasourceDrift(ref.watch(appDatabaseProvider));

class ProjectDatasourceDrift implements ProjectDatasource {
  ProjectDatasourceDrift(this._db);
  final AppDatabase _db;

  @override
  Stream<List<WorkspaceProjectRow>> watchAllProjectRows() => _db.projectDao.watchAllProjects();

  @override
  Future<List<WorkspaceProjectRow>> getAllProjectRows() => _db.projectDao.getAllProjects();

  @override
  Future<WorkspaceProjectRow?> getProjectRow(String id) => _db.projectDao.getProject(id);

  @override
  Future<WorkspaceProjectRow?> getProjectRowByPath(String path) => _db.projectDao.getProjectByPath(path);

  @override
  Future<void> upsertProjectRow(WorkspaceProjectsCompanion row) => _db.projectDao.upsertProject(row);

  @override
  Future<void> updateProjectRow(String id, WorkspaceProjectsCompanion companion) =>
      _db.projectDao.updateProject(id, companion);

  @override
  Future<void> deleteProjectRow(String id) => _db.projectDao.deleteProject(id);

  @override
  Future<void> deleteAllProjectRows() => _db.projectDao.deleteAllProjects();
}
