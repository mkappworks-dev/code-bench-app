/// Snapshot of a project's live git state, derived on demand from the
/// filesystem rather than persisted to the database.
///
/// ## The "unknown" contract
///
/// [hasUncommitted], [aheadCount], and [behindCount] are **nullable** by
/// design. `null` means "the probe failed" (git binary missing, cwd deleted,
/// permission denied, unexpected non-zero exit) — NOT "clean repo" and NOT
/// "zero commits ahead". UI code must treat `null` as "cannot act" rather
/// than as a falsy default, so that a broken `git status` never silently
/// dims the Commit button on a truly dirty tree. Every probe failure is
/// logged via `sLog` in [gitLiveState] so null at the UI is always
/// attributable.
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

  /// Current branch name. `null` when in detached HEAD state or not a git
  /// repo. Callers that need to act on the branch (e.g. Open PR) must
  /// null-check — detached HEAD is explicitly null, not the literal string
  /// `"HEAD"`.
  final String? branch;

  /// `true` when `git status --porcelain` produced output, `false` when it
  /// was empty, `null` when the probe failed (unknown). Render `null` as
  /// "status unavailable", never as "clean".
  final bool? hasUncommitted;

  /// Number of commits ahead of upstream (`@{u}..HEAD`). `0` when a known
  /// "no upstream" state was observed, `null` when the probe failed.
  /// Render `null` as "unknown", never as "up to date".
  final int? aheadCount;

  /// Commits behind upstream. `null` when unknown (offline, no remote,
  /// fetch failed, probe failed).
  final int? behindCount;

  /// `true` when [branch] is `'main'` or `'master'`. Always `false` when
  /// [branch] is `null` (detached HEAD or unknown).
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
