import '../git_live_state.dart';

abstract interface class GitLiveStateDatasource {
  Future<GitLiveState> fetchLiveState(String projectPath);
  Future<int?> fetchBehindCount(String projectPath);
  bool isGitRepo(String projectPath);
}
