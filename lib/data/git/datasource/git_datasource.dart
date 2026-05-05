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

  /// Returns worktree info for every git worktree OTHER than this datasource's project path.
  Future<({Map<String, String> active, Set<String> stale})> worktreeBranches();
  Future<void> checkout(String branch);
  Future<void> createBranch(String name, {String? baseBranch});
  Future<void> createWorktree(String branchName, String worktreePath, {String? baseBranch});
  Future<List<GitChangedFile>> getChangedFiles();

  Future<List<String>> getBranchChangedFiles();
}

class GitRemote {
  const GitRemote({required this.name, required this.url});
  final String name;
  final String url;
}
