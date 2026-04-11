# Live Git Status — Design Spec

**Date:** 2026-04-11
**Plan target:** `docs/superpowers/plans/2026-04-11-phase9-live-git-status.md`
**Worktree:** `.worktrees/feat/2026-04-11-phase9-live-git-status` (branch from `main` after phase 3 merged)

---

## Problem

Three related git-state issues share one root cause: the app has no reactive live-git-state provider.

1. **Stale branch display** — `Project.currentBranch` is written once at `addExistingFolder` time. Switching branches externally leaves the sidebar tooltip and status bar label frozen. Also, `GitDetector.isGitRepo` uses `Directory('$path/.git').existsSync()` which returns `false` for git worktrees (where `.git` is a file, not a directory).
2. **No branch picker** — clicking the branch label in the status bar does nothing.
3. **Action buttons always enabled** — Commit, Push, Pull, and Create PR are never disabled regardless of repo state.

---

## Prerequisites

- `feat/2026-04-10-phase3-stub-button-functionality` merged to `main` — provides `GitService`, `_CommitPushButton`, and the wired action handlers that this plan extends.
- Phase 7 (`feat/2026-04-10-phase7-missing-project-detection`) is a **parallel-safe neighbour** — it adds `ProjectStatus` to `Project` via `_projectFromRow`; this plan removes `isGit`/`currentBranch` from `Project`. Neither conflicts with the other and they can land in either order.

---

## Architecture Decision

`isGit` and `currentBranch` are removed from the Drift schema and the `Project` freezed model entirely. All git state lives in a new Riverpod family provider:

```dart
@riverpod
Future<GitLiveState> gitLiveState(Ref ref, String projectId) async { ... }
```

This keeps `Project` as pure persistent metadata (id, name, path, createdAt, sortOrder) and isolates all git state in one reactive unit.

---

## Section 1: Data Model

### `GitLiveState`

New value object at `lib/services/git/git_live_state.dart`:

```dart
class GitLiveState {
  const GitLiveState({
    required this.isGit,
    this.branch,
    required this.hasUncommitted,
    required this.aheadCount,
    this.behindCount,
    required this.isOnDefaultBranch,
  });

  final bool isGit;
  final String? branch;          // null = detached HEAD or not a git repo
  final bool hasUncommitted;     // git status --porcelain is non-empty
  final int aheadCount;          // commits ahead of upstream (local revlist)
  final int? behindCount;        // null = unknown (fetch failed / no upstream)
  final bool isOnDefaultBranch;  // branch == 'main' || 'master'

  static const notGit = GitLiveState(
    isGit: false,
    hasUncommitted: false,
    aheadCount: 0,
    isOnDefaultBranch: false,
  );
}
```

### `gitLiveStateProvider`

Riverpod `@riverpod` family keyed by `projectId`. On each invocation:

1. Resolve the project path from `projectsProvider`.
2. Call `GitDetector.isGitRepo(path)` — returns `GitLiveState.notGit` if false.
3. Run the cheap git ops in parallel: `git rev-parse --abbrev-ref HEAD`, `git status --porcelain`, `git rev-list --count @{u}..HEAD`. If no upstream is configured, `git rev-list` exits non-zero — treat as `aheadCount = 0` rather than a failure.
4. Set `isOnDefaultBranch = branch == 'main' || branch == 'master'`.
5. `behindCount` is **not** fetched here — it is managed by a sibling `behindCountProvider` on its own slower cadence (see Section 2).
6. On any subprocess failure, return a safe partial state (e.g. `hasUncommitted: false`, `aheadCount: 0`) rather than throwing — git state is informational and should not crash the UI.

### `behindCountProvider`

Separate Riverpod family keyed by `projectId`. Runs `git fetch --quiet` then `git rev-list --count HEAD..origin/<branch>`. Returns `int?` (null on any failure). Refreshed only:
- After a successful push or pull (mutation-triggered).
- By a `Timer.periodic` at 5-minute intervals.

### Changes to `Project`

Remove `isGit` and `currentBranch` fields from:
- `lib/data/models/project.dart` (freezed model)
- `lib/data/datasources/local/app_database.dart` (Drift table)
- `lib/services/project/project_service.dart` (`addExistingFolder`, `refreshGitStatus`, `_projectFromRow`)

Add a Drift schema migration to drop both columns.

### Fix `GitDetector.isGitRepo`

Replace `Directory('$path/.git').existsSync()` with:

```dart
static bool isGitRepo(String path) {
  final type = FileSystemEntity.typeSync('$path/.git');
  return type == FileSystemEntityType.directory ||
         type == FileSystemEntityType.file; // worktree: .git is a file
}
```

---

## Section 2: Refresh Strategy

### Cheap fields (branch, hasUncommitted, aheadCount, isOnDefaultBranch)

**Focus-triggered:** A new `AppLifecycleObserver` widget wraps `ChatShell` and implements `WidgetsBindingObserver`. On `AppLifecycleState.resumed`, it calls `ref.invalidate(gitLiveStateProvider(id))` for every project currently in `projectsProvider`. Works on macOS, Windows, and Linux.

**Mutation-triggered:** After every in-app git action, the handler invalidates the provider for the affected project:

| Action | Trigger site |
|--------|-------------|
| Commit | `_CommitPushButtonState._runCommit` (after success) |
| Push | `_CommitPushButtonState._doPush` (after success) |
| Pull | `_CommitPushButtonState._doPull` (after success) |
| Checkout branch | `BranchPickerNotifier.checkout` (after success) |
| Create branch | `BranchPickerNotifier.createBranch` (after success) |
| Init git | `_InitGitButton.onTap` (after success) |

### Behind count (behindCount)

Fetched only on: post-push success, post-pull success, and `Timer.periodic(const Duration(minutes: 5))` started inside the provider body and cancelled via `ref.onDispose`. On failure (offline, no upstream) returns `null` — renders as `↓?` in the caret badge.

---

## Section 3: Branch Picker

### Trigger

The branch text in `status_bar.dart` becomes a tappable `GestureDetector`. On tap, it opens `BranchPickerPopover` anchored above it using `CompositedTransformFollower` / `Overlay` (same pattern as `showInstantMenuAnchoredTo`).

### `BranchPickerPopover` widget

File: `lib/features/branch_picker/widgets/branch_picker_popover.dart`

Layout (top → bottom):
1. **Search input** — `TextField` with border radius, filters branch list by substring as user types.
2. **Branch list** — scrollable, max height capped so popover fits above the status bar.
3. **Footer** — "Create new branch…" in normal state; transforms to an inline input on tap.

### Branch list data

`BranchPickerNotifier` (file: `lib/features/branch_picker/branch_picker_notifier.dart`) fetches on open:
- `git branch` — local branches list.
- `git worktree list --porcelain` — to identify worktree-reserved branches.

List sorted: current branch first, then alphabetical.

### Branch row states

| State | Visual | Tappable |
|-------|--------|----------|
| Current branch | Green dot + name + ✓ checkmark, faint green row bg | No (already here) |
| Available branch | Grey dot + name | Yes |
| Worktree-reserved | Grey dot + muted name + amber `worktree` badge | No — tooltip: *"Checked out in another worktree"* |
| Detached HEAD | Current row shows `(detached HEAD)` | No |

### Checkout flow

1. User taps an available branch row.
2. Run `git checkout <branch>` via `GitService`.
3. **Success:** close popover, `ref.invalidate(gitLiveStateProvider(projectId))`.
4. **Failure (uncommitted conflict):** keep popover open, snackbar: *"Checkout failed — stash or commit your changes first."*
5. **Failure (other):** keep popover open, snackbar with sanitised git stderr.

No pre-blocking for uncommitted changes — git decides.

### Create new branch

1. User taps footer "Create new branch…".
2. Footer transforms to inline `TextField` (pre-focused) with a `⎇` icon, the typed name, and a `↵ create · esc cancel` hint. Below the input: `from <currentBranch>` in muted text.
3. **Enter:** run `git checkout -b <name>`, close popover on success, snackbar on error.
4. **Escape:** revert footer to normal text. Second Escape closes the popover.
5. Branch name is validated client-side: non-empty, no spaces, does not start with `-`.

---

## Section 4: Action Button Enabled States

`_CommitPushButton` drops its local `_behindCount` field. All enabled states are derived from `gitLiveStateProvider` and `behindCountProvider`:

| Control | Enabled condition | Disabled condition |
|---------|------------------|--------------------|
| Commit (main button) | `hasUncommitted == true` | working tree clean |
| Push (dropdown item) | `aheadCount > 0` | `aheadCount == 0` |
| Pull (dropdown item) | `behindCount != null && behindCount! > 0` | `behindCount == 0 or null` |
| Create PR (dropdown item) | `!isOnDefaultBranch` | `isOnDefaultBranch` |

**Disabled visual treatment:**
- Commit main button: `ThemeConstants.inputSurface` background, muted text, no tap response.
- Dropdown items: `enabled: false` on `PopupMenuItem` (greyed text, ignores tap).
- `↓N` badge in caret: shown when `behindCount > 0`; `↓?` when `behindCount == null`; hidden when `behindCount == 0`.

`_CommitPushButton` remains a `ConsumerStatefulWidget` (local `_pushing`/`_pulling` booleans still needed for in-progress state).

---

## Section 5: UI Polish

### Active project highlight in sidebar

`project_tile.dart` applies a green left border + faint green background to the row matching `activeProjectIdProvider`:

```dart
// when project.id == activeProjectId
BoxDecoration(
  color: ThemeConstants.success.withOpacity(0.06),
  border: Border(left: BorderSide(color: ThemeConstants.success, width: 2)),
)
```

Hover and expanded states are unchanged.

### Sidebar git icon tooltip — live branch

The `⎇` icon tooltip in `project_tile.dart` switches from `widget.project.currentBranch` to reading `gitLiveStateProvider(project.id).branch`. Renders the live branch name; falls back to `'git'` when `branch == null` (detached HEAD).

---

## File Map

| Status | File | Change |
|--------|------|--------|
| **Create** | `lib/services/git/git_live_state.dart` | `GitLiveState` value object |
| **Create** | `lib/services/git/git_live_state_provider.dart` | `gitLiveStateProvider` + `behindCountProvider` |
| **Create** | `lib/shell/widgets/app_lifecycle_observer.dart` | `AppLifecycleObserver` widget — wraps `ChatShell`, triggers focus-refresh |
| **Create** | `lib/features/branch_picker/widgets/branch_picker_popover.dart` | Searchable popover widget |
| **Create** | `lib/features/branch_picker/branch_picker_notifier.dart` | Branch list + checkout + create-branch logic |
| Modify | `lib/services/project/git_detector.dart` | Fix `isGitRepo` for worktrees |
| Modify | `lib/data/models/project.dart` | Remove `isGit`, `currentBranch` fields |
| Modify | `lib/data/datasources/local/app_database.dart` | Drop columns from Drift table; add migration |
| Modify | `lib/services/project/project_service.dart` | Remove git fields from `addExistingFolder`, `_projectFromRow`; delete `refreshGitStatus` |
| Modify | `lib/shell/widgets/status_bar.dart` | Branch label → tappable; reads from `gitLiveStateProvider` |
| Modify | `lib/shell/widgets/top_action_bar.dart` | Commit/Push/Pull/PR enabled states wired to providers |
| Modify | `lib/features/project_sidebar/widgets/project_tile.dart` | Active project highlight; live branch tooltip |

---

## Out of Scope

- "Create PR" disabled when a PR already exists for the branch (deferred — requires GitHub API, fits a later phase).
- Remote branch listing in the picker (local branches only).
- Stash-and-restore flow on checkout with uncommitted changes (git handles it; UI reports errors).
