abstract interface class GitDetectorDatasource {
  bool isGitRepo(String directoryPath);
  String? getCurrentBranch(String directoryPath);
}
