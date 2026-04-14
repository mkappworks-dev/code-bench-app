import '../models/git_changed_file.dart';

export '../models/git_live_state.dart';

abstract interface class GitDatasource {
  Future<void> initGit();
  Future<String> commit(String message); // returns short SHA
  Future<String> push(); // returns branch name
  Future<void> pushToRemote(String remote);
  Future<int> pull(); // returns commit count
  Future<int?> fetchBehindCount();
  Future<String?> currentBranch();
  Future<String?> getOriginUrl();
  Future<List<GitRemote>> listRemotes();
  Future<List<String>> listLocalBranches();

  /// Returns a map of branch name → worktree filesystem path for every
  /// git worktree OTHER than the one at this datasource's project path.
  Future<Map<String, String>> worktreeBranches();
  Future<void> checkout(String branch);
  Future<void> createBranch(String name);
  Future<List<GitChangedFile>> getChangedFiles();
}

class GitRemote {
  const GitRemote({required this.name, required this.url});
  final String name;
  final String url;
}
