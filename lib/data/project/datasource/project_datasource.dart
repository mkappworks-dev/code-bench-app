/// Plain Dart representation of a project row. No Drift dependencies.
/// [ProjectDatasourceDrift] translates between this and Drift-generated types.
class ProjectRow {
  const ProjectRow({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.sortOrder,
    required this.actionsJson,
  });

  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final int sortOrder;
  final String actionsJson;
}

abstract interface class ProjectDatasource {
  Stream<List<ProjectRow>> watchAllProjectRows();
  Future<List<ProjectRow>> getAllProjectRows();
  Future<ProjectRow?> getProjectRow(String id);
  Future<ProjectRow?> getProjectRowByPath(String path);
  Future<void> upsertProject({
    required String id,
    required String name,
    required String path,
    required DateTime createdAt,
    int sortOrder,
  });
  Future<void> updateProjectActions(String id, String actionsJson);
  Future<void> updateProjectPath(String id, String newPath);
  Future<void> updateProjectSortOrder(String id, int sortOrder);
  Future<void> deleteProjectRow(String id);
  Future<void> deleteAllProjectRows();
}
