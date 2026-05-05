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

  /// Returns active and stale worktree information for every git worktree
  /// OTHER than the one at this datasource's project path.
  ///
  /// [active] maps branch name → worktree path for healthy worktrees.
  /// [stale] is the set of branch names locked to prunable worktrees
  /// (the worktree directory no longer exists on disk).
  Future<({Map<String, String> active, Set<String> stale})> worktreeBranches();
  Future<void> checkout(String branch);
  Future<void> createBranch(String name, {String? baseBranch});
  Future<void> createWorktree(String branchName, String worktreePath, {String? baseBranch});
  Future<List<GitChangedFile>> getChangedFiles();

  /// Returns the set of file paths changed in the current branch vs the remote
  /// default branch. Tries `origin/main` then `origin/master`; falls back to
  /// `git diff --name-only HEAD` when neither remote ref exists. Deduplicates
  /// across commits (a file renamed and edited in two commits appears once).
  Future<List<String>> getBranchChangedFiles();
}

class GitRemote {
  const GitRemote({required this.name, required this.url});
  final String name;
  final String url;
}
