abstract interface class ProjectFsDatasource {
  bool exists(String path);
  Future<void> createDirectory(String path);
}
