import '../datasource/git_datasource.dart';

export '../datasource/git_datasource.dart' show GitRemote;
export '../datasource/git_datasource_process.dart'
    show GitException, GitNoUpstreamException, GitAuthException, GitConflictException;

abstract interface class GitRepository {
  Future<void> initGit(String projectPath);
  Future<String> commit(String projectPath, String message);
  Future<String> push(String projectPath);
  Future<void> pushToRemote(String projectPath, String remote);
  Future<int> pull(String projectPath);
  Future<int?> fetchBehindCount(String projectPath);
  Future<String?> currentBranch(String projectPath);
  Future<String?> getOriginUrl(String projectPath);
  Future<List<GitRemote>> listRemotes(String projectPath);
  Future<List<String>> listLocalBranches(String projectPath);
  Future<Set<String>> worktreeBranches(String projectPath);
  Future<void> checkout(String projectPath, String branch);
  Future<void> createBranch(String projectPath, String name);
  // Live state:
  Future<GitLiveState> fetchLiveState(String projectPath);
  Future<int?> behindCount(String projectPath);
  bool isGitRepo(String projectPath);
}
