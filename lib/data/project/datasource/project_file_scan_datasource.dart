abstract interface class ProjectFileScanDatasource {
  Future<List<String>> scanCodeFiles(String rootPath);
}
