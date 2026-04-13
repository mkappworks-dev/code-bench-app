import '../../../data/_core/app_database.dart';

abstract interface class ProjectDatasource {
  Stream<List<WorkspaceProjectRow>> watchAllProjectRows();
  Future<List<WorkspaceProjectRow>> getAllProjectRows();
  Future<WorkspaceProjectRow?> getProjectRow(String id);
  Future<WorkspaceProjectRow?> getProjectRowByPath(String path);
  Future<void> upsertProjectRow(WorkspaceProjectsCompanion row);
  Future<void> updateProjectRow(String id, WorkspaceProjectsCompanion companion);
  Future<void> deleteProjectRow(String id);
  Future<void> deleteAllProjectRows();
}
