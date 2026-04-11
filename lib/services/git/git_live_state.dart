/// Snapshot of a project's live git state, derived on demand from the
/// filesystem rather than persisted to the database.
class GitLiveState {
  const GitLiveState({
    required this.isGit,
    this.branch,
    required this.hasUncommitted,
    required this.aheadCount,
    this.behindCount,
    required this.isOnDefaultBranch,
  });

  /// Whether the project path is a git repository (or worktree).
  final bool isGit;

  /// Current branch name. `null` when in detached HEAD state or not a git repo.
  final String? branch;

  /// `true` when `git status --porcelain` produces any output.
  final bool hasUncommitted;

  /// Number of commits ahead of upstream (`@{u}..HEAD`). 0 when no upstream.
  final int aheadCount;

  /// Commits behind upstream. `null` when unknown (offline, no remote, fetch failed).
  final int? behindCount;

  /// `true` when [branch] is `'main'` or `'master'`.
  final bool isOnDefaultBranch;

  /// Returned when the path is not a git repository.
  static const notGit = GitLiveState(isGit: false, hasUncommitted: false, aheadCount: 0, isOnDefaultBranch: false);

  GitLiveState copyWith({
    bool? isGit,
    String? branch,
    bool? hasUncommitted,
    int? aheadCount,
    int? behindCount,
    bool? isOnDefaultBranch,
  }) {
    return GitLiveState(
      isGit: isGit ?? this.isGit,
      branch: branch ?? this.branch,
      hasUncommitted: hasUncommitted ?? this.hasUncommitted,
      aheadCount: aheadCount ?? this.aheadCount,
      behindCount: behindCount ?? this.behindCount,
      isOnDefaultBranch: isOnDefaultBranch ?? this.isOnDefaultBranch,
    );
  }
}
