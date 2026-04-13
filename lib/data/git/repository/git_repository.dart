/// Thin I/O facade — primitives only.
/// All composite git operations live in GitService.
abstract interface class GitRepository {
  Future<void> initGit(String projectPath);
  Future<String?> currentBranch(String projectPath);
  Future<String?> getOriginUrl(String projectPath);
  bool isGitRepo(String projectPath);
}
