# Phase 9 — Live Git Status Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **⚠️ Rebase note — Phase 6 adjustment.** Task 7 Step 7 adds `ref.invalidate(gitLiveStateProvider(...))` + `ref.invalidate(behindCountProvider(...))` after `_doPush`, `_doPull`, and `_runCommit`. That enumeration predates Phase 6. When rebasing onto a Phase-6-merged `main`, **also add the same two invalidations once after `_doPushAll` completes successfully** (once per fan-out, not per remote). See Phase 6b's "Cross-reference: Phase 9 rebase note" section for context.

**Goal:** Replace frozen Drift-persisted git state with a reactive `gitLiveStateProvider`, add a searchable branch picker popover, and wire action-button enabled states to live repo data.

**Architecture:** A new `GitLiveState` value object and `gitLiveStateProvider(projectPath)` family provider replace the persisted `isGit`/`currentBranch` fields on `Project`. Cheap git ops (branch, hasUncommitted, aheadCount) refresh on window focus and after each mutation; behindCount fetches on a 5-minute timer + post-push/pull. The branch picker is a `CompositedTransformFollower` overlay anchored to the status bar branch label.

**Tech Stack:** Flutter, Riverpod (`riverpod_annotation`), `dart:io` (`Process.run`, `FileSystemEntity`), Drift (schema migration v5), `GitService` from phase 3.

**Prerequisite:** `feat/2026-04-10-phase3-stub-button-functionality` must be merged to `main` before branching. Phase 8 (`feat/2026-04-10-phase8-missing-project-detection`) is parallel-safe — can land in either order.

**Worktree setup:**
```bash
git worktree add .worktrees/feat/2026-04-11-phase9-live-git-status -b feat/2026-04-11-phase9-live-git-status
cd .worktrees/feat/2026-04-11-phase9-live-git-status
```

---

## File Map

| Status | File | Responsibility |
|--------|------|----------------|
| **Create** | `lib/services/git/git_live_state.dart` | `GitLiveState` value object |
| **Create** | `lib/services/git/git_live_state_provider.dart` | `gitLiveStateProvider` + `behindCountProvider` (Riverpod) |
| **Create** | `lib/shell/widgets/app_lifecycle_observer.dart` | Widget wrapping `ChatShell`; invalidates providers on window focus |
| **Create** | `lib/features/branch_picker/branch_picker_notifier.dart` | Plain Dart class: `listLocalBranches`, `worktreeBranches`, `checkout`, `createBranch` |
| **Create** | `lib/features/branch_picker/widgets/branch_picker_popover.dart` | Searchable overlay popover widget |
| **Create** | `test/services/project/git_detector_test.dart` | Tests for `isGitRepo` worktree fix |
| **Create** | `test/services/git/git_live_state_provider_test.dart` | Tests for `gitLiveStateProvider` |
| **Create** | `test/features/branch_picker/branch_picker_notifier_test.dart` | Tests for branch list, checkout, create-branch |
| Modify | `lib/services/project/git_detector.dart` | Fix `isGitRepo` to accept `.git` file (worktrees) |
| Modify | `lib/data/models/project.dart` | Remove `isGit`, `currentBranch` fields |
| Modify | `lib/data/datasources/local/app_database.dart` | Schema v5: orphan `isGit`/`currentBranch` columns |
| Modify | `lib/services/project/project_service.dart` | Remove git fields from `addExistingFolder`, `_projectFromRow`; delete `refreshGitStatus` |
| Modify | `lib/shell/chat_shell.dart` | Wrap content with `AppLifecycleObserver` |
| Modify | `lib/shell/widgets/status_bar.dart` | Read from `gitLiveStateProvider`; branch label opens picker |
| Modify | `lib/features/project_sidebar/widgets/project_tile.dart` | Live branch tooltip; active project green highlight |
| Modify | `lib/shell/widgets/top_action_bar.dart` | Commit/Push/Pull/PR enabled states; invalidate on mutation |

---

## Task 1: Fix `GitDetector.isGitRepo` for git worktrees

**Files:**
- Modify: `lib/services/project/git_detector.dart`
- Create: `test/services/project/git_detector_test.dart`

- [ ] **Step 1.1: Write the failing tests**

  Create `test/services/project/git_detector_test.dart`:

  ```dart
  import 'dart:io';

  import 'package:flutter_test/flutter_test.dart';

  import 'package:code_bench_app/services/project/git_detector.dart';

  void main() {
    late Directory tmpDir;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('git_detector_test_');
    });

    tearDown(() async {
      await tmpDir.delete(recursive: true);
    });

    group('GitDetector.isGitRepo', () {
      test('returns false when no .git entry exists', () {
        expect(GitDetector.isGitRepo(tmpDir.path), isFalse);
      });

      test('returns true when .git is a directory (normal repo)', () async {
        await Directory('${tmpDir.path}/.git').create();
        expect(GitDetector.isGitRepo(tmpDir.path), isTrue);
      });

      test('returns true when .git is a file (worktree)', () async {
        await File('${tmpDir.path}/.git')
            .writeAsString('gitdir: ../.git/worktrees/foo');
        expect(GitDetector.isGitRepo(tmpDir.path), isTrue);
      });
    });
  }
  ```

- [ ] **Step 1.2: Run to confirm failures**

  ```bash
  flutter test test/services/project/git_detector_test.dart
  ```

  Expected: 2 failures (directory + file cases), 1 pass (no .git).

- [ ] **Step 1.3: Fix `isGitRepo` in `git_detector.dart`**

  Replace the entire file:

  ```dart
  import 'dart:io';

  class GitDetector {
    static bool isGitRepo(String directoryPath) {
      final type = FileSystemEntity.typeSync('$directoryPath/.git');
      return type == FileSystemEntityType.directory ||
          type == FileSystemEntityType.file; // worktree: .git is a file
    }

    static String? getCurrentBranch(String directoryPath) {
      if (!isGitRepo(directoryPath)) return null;
      try {
        final result = Process.runSync(
          'git',
          ['rev-parse', '--abbrev-ref', 'HEAD'],
          workingDirectory: directoryPath,
        );
        if (result.exitCode == 0) {
          return (result.stdout as String).trim();
        }
        return null;
      } catch (_) {
        return null;
      }
    }
  }
  ```

- [ ] **Step 1.4: Run tests — expect all pass**

  ```bash
  flutter test test/services/project/git_detector_test.dart
  ```

  Expected: 3 passing.

- [ ] **Step 1.5: Commit**

  ```bash
  dart format lib/services/project/git_detector.dart test/services/project/git_detector_test.dart
  git add lib/services/project/git_detector.dart test/services/project/git_detector_test.dart
  git commit -m "fix: recognise .git file as valid git repo (worktree support)"
  ```

---

## Task 2: `GitLiveState` value object

**Files:**
- Create: `lib/services/git/git_live_state.dart`

- [ ] **Step 2.1: Create `lib/services/git/git_live_state.dart`**

  ```dart
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
    static const notGit = GitLiveState(
      isGit: false,
      hasUncommitted: false,
      aheadCount: 0,
      isOnDefaultBranch: false,
    );

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
  ```

- [ ] **Step 2.2: Commit**

  ```bash
  dart format lib/services/git/git_live_state.dart
  git add lib/services/git/git_live_state.dart
  git commit -m "feat: add GitLiveState value object"
  ```

---

## Task 3: `gitLiveStateProvider` and `behindCountProvider`

**Files:**
- Create: `lib/services/git/git_live_state_provider.dart`
- Create: `test/services/git/git_live_state_provider_test.dart`

- [ ] **Step 3.1: Write the failing tests**

  Create `test/services/git/git_live_state_provider_test.dart`:

  ```dart
  import 'dart:io';

  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';

  import 'package:code_bench_app/services/git/git_live_state_provider.dart';

  Future<Directory> _initGitRepo() async {
    final dir = await Directory.systemTemp.createTemp('git_live_test_');
    await Process.run('git', ['init'], workingDirectory: dir.path);
    await Process.run(
      'git', ['config', 'user.email', 'test@test.com'],
      workingDirectory: dir.path,
    );
    await Process.run(
      'git', ['config', 'user.name', 'Test'],
      workingDirectory: dir.path,
    );
    // Create initial commit so HEAD is valid
    await File('${dir.path}/readme.txt').writeAsString('hello');
    await Process.run('git', ['add', '.'], workingDirectory: dir.path);
    await Process.run(
      'git', ['commit', '-m', 'init'],
      workingDirectory: dir.path,
    );
    return dir;
  }

  void main() {
    group('gitLiveStateProvider', () {
      test('returns notGit for a non-git directory', () async {
        final dir = await Directory.systemTemp.createTemp('non_git_');
        addTearDown(() => dir.delete(recursive: true));

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state =
            await container.read(gitLiveStateProvider(dir.path).future);
        expect(state.isGit, isFalse);
        expect(state.hasUncommitted, isFalse);
        expect(state.aheadCount, equals(0));
      });

      test('returns correct state for a clean git repo', () async {
        final dir = await _initGitRepo();
        addTearDown(() => dir.delete(recursive: true));

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state =
            await container.read(gitLiveStateProvider(dir.path).future);
        expect(state.isGit, isTrue);
        expect(state.branch, isNotNull);
        expect(state.hasUncommitted, isFalse);
        expect(state.aheadCount, equals(0));
      });

      test('hasUncommitted is true when working tree has changes', () async {
        final dir = await _initGitRepo();
        addTearDown(() => dir.delete(recursive: true));

        await File('${dir.path}/new_file.txt').writeAsString('change');

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state =
            await container.read(gitLiveStateProvider(dir.path).future);
        expect(state.hasUncommitted, isTrue);
      });

      test('isOnDefaultBranch is true on main', () async {
        final dir = await _initGitRepo();
        addTearDown(() => dir.delete(recursive: true));

        // Rename branch to 'main' if git defaulted to something else
        await Process.run(
          'git', ['checkout', '-b', 'main'],
          workingDirectory: dir.path,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state =
            await container.read(gitLiveStateProvider(dir.path).future);
        expect(state.isOnDefaultBranch, isTrue);
      });

      test('isOnDefaultBranch is false on a feature branch', () async {
        final dir = await _initGitRepo();
        addTearDown(() => dir.delete(recursive: true));

        await Process.run(
          'git', ['checkout', '-b', 'feat/test'],
          workingDirectory: dir.path,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state =
            await container.read(gitLiveStateProvider(dir.path).future);
        expect(state.isOnDefaultBranch, isFalse);
      });
    });

    group('behindCountProvider', () {
      test('returns null when no upstream is configured', () async {
        final dir = await _initGitRepo();
        addTearDown(() => dir.delete(recursive: true));

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // No remote → fetchBehindCount returns null
        final count =
            await container.read(behindCountProvider(dir.path).future);
        expect(count, isNull);
      });
    });
  }
  ```

- [ ] **Step 3.2: Run to confirm failures**

  ```bash
  flutter test test/services/git/git_live_state_provider_test.dart
  ```

  Expected: compilation error (file doesn't exist yet).

- [ ] **Step 3.3: Create `lib/services/git/git_live_state_provider.dart`**

  ```dart
  import 'dart:async';
  import 'dart:io';

  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import 'git_live_state.dart';
  import 'git_service.dart';
  import '../project/git_detector.dart';

  part 'git_live_state_provider.g.dart';

  /// Live git state for [projectPath]. Covers cheap, local-only operations.
  /// Refresh triggers: window focus (via [AppLifecycleObserver]) and after
  /// every in-app git mutation (commit, push, pull, checkout, init-git).
  @riverpod
  Future<GitLiveState> gitLiveState(Ref ref, String projectPath) async {
    if (!GitDetector.isGitRepo(projectPath)) return GitLiveState.notGit;

    final gitSvc = GitService(projectPath);

    final results = await Future.wait([
      gitSvc.currentBranch(),
      _hasUncommitted(projectPath),
      _aheadCount(projectPath),
    ]);

    final branch = results[0] as String?;
    final hasUncommitted = results[1] as bool;
    final aheadCount = results[2] as int;

    return GitLiveState(
      isGit: true,
      branch: branch,
      hasUncommitted: hasUncommitted,
      aheadCount: aheadCount,
      isOnDefaultBranch: branch == 'main' || branch == 'master',
    );
  }

  /// Behind count for [projectPath]. Runs `git fetch` — network call.
  /// Refreshes on a 5-minute timer and after post-push/pull mutations.
  @riverpod
  Future<int?> behindCount(Ref ref, String projectPath) async {
    final timer = Timer.periodic(const Duration(minutes: 5), (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);

    if (!GitDetector.isGitRepo(projectPath)) return null;
    return GitService(projectPath).fetchBehindCount();
  }

  Future<bool> _hasUncommitted(String projectPath) async {
    final result = await Process.run(
      'git',
      ['status', '--porcelain'],
      workingDirectory: projectPath,
    );
    if (result.exitCode != 0) return false;
    return (result.stdout as String).trim().isNotEmpty;
  }

  /// Returns commits ahead of upstream. Returns 0 if no upstream is set
  /// (git exits non-zero in that case).
  Future<int> _aheadCount(String projectPath) async {
    final result = await Process.run(
      'git',
      ['rev-list', '--count', '@{u}..HEAD', '--'],
      workingDirectory: projectPath,
    );
    if (result.exitCode != 0) return 0;
    return int.tryParse((result.stdout as String).trim()) ?? 0;
  }
  ```

- [ ] **Step 3.4: Run code generation**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `lib/services/git/git_live_state_provider.g.dart` created.

- [ ] **Step 3.5: Run tests — expect all pass**

  ```bash
  flutter test test/services/git/git_live_state_provider_test.dart
  ```

  Expected: 6 passing. (The `behindCount` test may be slow due to `git fetch` timeout — acceptable.)

- [ ] **Step 3.6: Commit**

  ```bash
  dart format lib/services/git/ test/services/git/
  git add lib/services/git/git_live_state_provider.dart \
          lib/services/git/git_live_state_provider.g.dart \
          test/services/git/git_live_state_provider_test.dart
  git commit -m "feat: add gitLiveStateProvider and behindCountProvider"
  ```

---

## Task 4: `AppLifecycleObserver` — refresh on window focus

**Files:**
- Create: `lib/shell/widgets/app_lifecycle_observer.dart`
- Modify: `lib/shell/chat_shell.dart`

- [ ] **Step 4.1: Create `lib/shell/widgets/app_lifecycle_observer.dart`**

  ```dart
  import 'package:flutter/widgets.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../features/project_sidebar/project_sidebar_notifier.dart';
  import '../../services/git/git_live_state_provider.dart';

  /// Wraps its child and invalidates [gitLiveStateProvider] for every tracked
  /// project whenever the app window regains focus. Works on macOS, Windows,
  /// and Linux via [AppLifecycleState.resumed].
  class AppLifecycleObserver extends ConsumerStatefulWidget {
    const AppLifecycleObserver({super.key, required this.child});

    final Widget child;

    @override
    ConsumerState<AppLifecycleObserver> createState() =>
        _AppLifecycleObserverState();
  }

  class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
      with WidgetsBindingObserver {
    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addObserver(this);
    }

    @override
    void dispose() {
      WidgetsBinding.instance.removeObserver(this);
      super.dispose();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      if (state != AppLifecycleState.resumed) return;
      _invalidateAll();
    }

    void _invalidateAll() {
      final projectsAsync = ref.read(projectsProvider);
      projectsAsync.whenData((projects) {
        for (final project in projects) {
          ref.invalidate(gitLiveStateProvider(project.path));
        }
      });
    }

    @override
    Widget build(BuildContext context) => widget.child;
  }
  ```

- [ ] **Step 4.2: Wrap `ChatShell` content with `AppLifecycleObserver`**

  In `lib/shell/chat_shell.dart`, add the import and wrap the `Material` child:

  ```dart
  import 'widgets/app_lifecycle_observer.dart';
  ```

  In `build()`, change:

  ```dart
  return Material(
    color: ThemeConstants.background,
    child: CallbackShortcuts(
  ```

  to:

  ```dart
  return AppLifecycleObserver(
    child: Material(
      color: ThemeConstants.background,
      child: CallbackShortcuts(
  ```

  And close the extra `)` before the final `);` of the `build` method:

  ```dart
          ),
        ),
      ),
    ),
  );
  ```

- [ ] **Step 4.3: Verify compilation**

  ```bash
  flutter analyze
  ```

  Expected: no new errors.

- [ ] **Step 4.4: Commit**

  ```bash
  dart format lib/shell/
  git add lib/shell/widgets/app_lifecycle_observer.dart lib/shell/chat_shell.dart
  git commit -m "feat: invalidate git live state on window focus"
  ```

---

## Task 5: Update `status_bar.dart` to read from `gitLiveStateProvider`

**Files:**
- Modify: `lib/shell/widgets/status_bar.dart`

- [ ] **Step 5.1: Replace `status_bar.dart`**

  ```dart
  import 'package:collection/collection.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:lucide_icons_flutter/lucide_icons.dart';

  import '../../core/constants/theme_constants.dart';
  import '../../data/models/project.dart';
  import '../../features/chat/chat_notifier.dart';
  import '../../features/project_sidebar/project_sidebar_notifier.dart';
  import '../../services/git/git_live_state.dart';
  import '../../services/git/git_live_state_provider.dart';

  class StatusBar extends ConsumerStatefulWidget {
    const StatusBar({super.key});

    @override
    ConsumerState<StatusBar> createState() => _StatusBarState();
  }

  class _StatusBarState extends ConsumerState<StatusBar> {
    final _branchLabelLink = LayerLink();
    OverlayEntry? _pickerEntry;

    void closePicker() {
      _pickerEntry?.remove();
      _pickerEntry = null;
    }

    @override
    void dispose() {
      _pickerEntry?.remove();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final projectId = ref.watch(activeProjectIdProvider);
      final projectsAsync = ref.watch(projectsProvider);
      final activeSessionId = ref.watch(activeSessionIdProvider);
      final panelVisible = ref.watch(changesPanelVisibleProvider);

      Project? activeProject;
      if (projectId != null) {
        activeProject = projectsAsync.whenOrNull(
          data: (list) => list.firstWhereOrNull((p) => p.id == projectId),
        );
      }

      final allChanges = ref.watch(appliedChangesProvider);
      final changeCount =
          activeSessionId != null ? (allChanges[activeSessionId]?.length ?? 0) : 0;

      // Watch live git state for the active project
      final liveStateAsync = activeProject != null
          ? ref.watch(gitLiveStateProvider(activeProject.path))
          : null;
      final liveState = liveStateAsync?.value;

      return Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          color: ThemeConstants.activityBar,
          border: Border(top: BorderSide(color: ThemeConstants.borderColor)),
        ),
        child: Row(
          children: [
            // Left: Local indicator
            Icon(LucideIcons.hardDrive, size: 10, color: ThemeConstants.faintFg),
            const SizedBox(width: 5),
            Text(
              'Local',
              style: const TextStyle(
                color: ThemeConstants.faintFg,
                fontSize: ThemeConstants.uiFontSizeLabel,
              ),
            ),
            const Spacer(),
            // Centre-right: N changes indicator (hidden when 0)
            if (changeCount > 0) ...[
              GestureDetector(
                onTap: () =>
                    ref.read(changesPanelVisibleProvider.notifier).toggle(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: panelVisible
                            ? ThemeConstants.accent
                            : ThemeConstants.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$changeCount ${changeCount == 1 ? 'change' : 'changes'}',
                      style: TextStyle(
                        color: panelVisible
                            ? ThemeConstants.accent
                            : ThemeConstants.warning,
                        fontSize: ThemeConstants.uiFontSizeLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
            // Right: Git branch (live)
            if (activeProject != null && liveState != null && liveState.isGit) ...[
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: ThemeConstants.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              CompositedTransformTarget(
                link: _branchLabelLink,
                child: GestureDetector(
                  onTap: () => _openPicker(activeProject!, liveState),
                  child: Text(
                    liveState.branch ?? '(detached)',
                    style: const TextStyle(
                      color: ThemeConstants.success,
                      fontSize: ThemeConstants.uiFontSizeLabel,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dotted,
                      decorationColor: ThemeConstants.success,
                    ),
                  ),
                ),
              ),
            ] else if (activeProject != null && liveState != null) ...[
              Text(
                'Not git',
                style: const TextStyle(
                  color: ThemeConstants.faintFg,
                  fontSize: ThemeConstants.uiFontSizeLabel,
                ),
              ),
            ],
          ],
        ),
      );
    }

    void _openPicker(Project project, GitLiveState liveState) {
      // Picker widget added in Task 11 — placeholder keeps code compiling.
      // Tap is wired but does nothing until BranchPickerPopover exists.
    }
  }
  ```

- [ ] **Step 5.2: Verify compilation**

  ```bash
  flutter analyze
  ```

  Expected: no errors.

- [ ] **Step 5.3: Commit**

  ```bash
  dart format lib/shell/widgets/status_bar.dart
  git add lib/shell/widgets/status_bar.dart
  git commit -m "feat: status bar reads live branch from gitLiveStateProvider"
  ```

---

## Task 6: Update `project_tile.dart` — live branch tooltip + active project highlight

**Files:**
- Modify: `lib/features/project_sidebar/widgets/project_tile.dart`

- [ ] **Step 6.1: Add import and replace the git icon + active-project decoration**

  Add imports at top of `project_tile.dart`:

  ```dart
  import '../../../services/git/git_live_state_provider.dart';
  import '../project_sidebar_notifier.dart';
  ```

  In `_ProjectTileState.build()`, add these two watches at the top of the method (after existing ones):

  ```dart
  final activeProjectId = ref.watch(activeProjectIdProvider);
  final liveStateAsync = ref.watch(gitLiveStateProvider(widget.project.path));
  final liveState = liveStateAsync.value;
  final isActive = widget.project.id == activeProjectId;
  ```

  Then update the **project row container decoration** (find the `InkWell` wrapping the row padding):

  The outer `Padding` that wraps the row contents — wrap its parent in a `DecoratedBox` (or set decoration on its existing container if one exists). Specifically, find the `InkWell` at approximately line 69 and wrap its child (the `Padding`) with:

  ```dart
  Container(
    decoration: isActive
        ? BoxDecoration(
            color: ThemeConstants.success.withOpacity(0.06),
            border: const Border(
              left: BorderSide(color: ThemeConstants.success, width: 2),
            ),
          )
        : null,
    child: Padding(
      // existing padding content unchanged
    ),
  ),
  ```

  Then update the **git icon tooltip** (around line 116–121):

  ```dart
  Tooltip(
    message: (liveState?.isGit ?? false)
        ? (liveState?.branch ?? 'git')
        : '',
    child: Icon(
      LucideIcons.gitBranch,
      size: 12,
      color: (liveState?.isGit ?? false)
          ? ThemeConstants.success
          : ThemeConstants.faintFg,
    ),
  ),
  ```

- [ ] **Step 6.2: Verify compilation**

  ```bash
  flutter analyze
  ```

  Expected: no errors.

- [ ] **Step 6.3: Commit**

  ```bash
  dart format lib/features/project_sidebar/widgets/project_tile.dart
  git add lib/features/project_sidebar/widgets/project_tile.dart
  git commit -m "feat: live branch tooltip and active project highlight in sidebar"
  ```

---

## Task 7: Update `top_action_bar.dart` — enabled states + mutation invalidation

**Files:**
- Modify: `lib/shell/widgets/top_action_bar.dart`

- [ ] **Step 7.1: Add import for `gitLiveStateProvider`**

  Add to the imports in `top_action_bar.dart`:

  ```dart
  import '../../services/git/git_live_state_provider.dart';
  ```

- [ ] **Step 7.2: Update `_CommitPushButton` — remove `_behindCount`, watch providers**

  In `_CommitPushButtonState`:

  1. **Remove** the `_behindCount` field and the `_checkBehindCount()` method entirely.
  2. **Remove** the `initState` body (or the `unawaited(_checkBehindCount())` call within it — keep `super.initState()`).
  3. In `build()`, add these at the top:

  ```dart
  final liveStateAsync =
      ref.watch(gitLiveStateProvider(widget.project.path));
  final behindAsync =
      ref.watch(behindCountProvider(widget.project.path));

  final liveState = liveStateAsync.value;
  final behind = behindAsync.value;

  final canCommit = liveState?.hasUncommitted ?? false;
  final canPush = (liveState?.aheadCount ?? 0) > 0;
  final canPull = (behind ?? 0) > 0;
  final canPr = !(liveState?.isOnDefaultBranch ?? true);
  ```

  4. Update the **Commit main button** — replace:

  ```dart
  GestureDetector(
    onTap: busy ? null : _doCommit,
    child: Container(
      // ...
      decoration: BoxDecoration(
        color: busy ? ThemeConstants.accentDark : ThemeConstants.accent,
  ```

  with:

  ```dart
  GestureDetector(
    onTap: (busy || !canCommit) ? null : _doCommit,
    child: Container(
      // ...
      decoration: BoxDecoration(
        color: busy
            ? ThemeConstants.accentDark
            : canCommit
                ? ThemeConstants.accent
                : ThemeConstants.inputSurface,
  ```

  And update the label text colour inside to use `canCommit`:

  ```dart
  Text(
    _pushing
        ? '● Pushing…'
        : _pulling
            ? '● Pulling…'
            : 'Commit',
    style: TextStyle(
      color: canCommit ? Colors.white : ThemeConstants.mutedFg,
      fontSize: ThemeConstants.uiFontSizeSmall,
    ),
  ),
  ```

  Also update the icon colour:

  ```dart
  Icon(
    LucideIcons.gitCommitHorizontal,
    size: 12,
    color: canCommit ? Colors.white : ThemeConstants.mutedFg,
  ),
  ```

  5. Update the **dropdown items** — in `showInstantMenuAnchoredTo`, replace the Push/Pull/Create PR items:

  ```dart
  PopupMenuItem(
    value: 'push',
    height: 32,
    enabled: canPush && !busy,
    child: Text(
      _pushing ? '● Pushing…' : 'Push ↑',
      style: TextStyle(
        color: (canPush && !busy)
            ? ThemeConstants.textSecondary
            : ThemeConstants.faintFg,
        fontSize: ThemeConstants.uiFontSizeSmall,
      ),
    ),
  ),
  PopupMenuItem(
    value: 'pull',
    height: 32,
    enabled: canPull && !busy,
    child: Text(
      canPull ? 'Pull ↓${behind ?? ''}' : 'Pull',
      style: TextStyle(
        color: canPull
            ? ThemeConstants.accent
            : ThemeConstants.faintFg,
        fontSize: ThemeConstants.uiFontSizeSmall,
      ),
    ),
  ),
  const PopupMenuDivider(),
  PopupMenuItem(
    value: 'create_pr',
    height: 32,
    enabled: canPr,
    child: Text(
      'Create PR',
      style: TextStyle(
        color: canPr
            ? ThemeConstants.textSecondary
            : ThemeConstants.faintFg,
        fontSize: ThemeConstants.uiFontSizeSmall,
      ),
    ),
  ),
  ```

  6. Update the **behind badge** in the caret (replace the existing `badgeLabel` logic):

  ```dart
  final String badgeLabel;
  if (behind == null) {
    badgeLabel = ' ↓?';
  } else if (behind > 0) {
    badgeLabel = ' ↓$behind';
  } else {
    badgeLabel = '';
  }
  ```

  7. **Add invalidation after each mutation.** In `_runCommit`, after the success snackbar:

  ```dart
  ref.invalidate(gitLiveStateProvider(widget.project.path));
  ```

  In `_doPush`, inside the try block after the success snackbar:

  ```dart
  ref.invalidate(gitLiveStateProvider(widget.project.path));
  ref.invalidate(behindCountProvider(widget.project.path));
  ```

  In `_doPull`, after `setState(() => _behindCount = 0)` — remove that setState entirely, and instead:

  ```dart
  ref.invalidate(gitLiveStateProvider(widget.project.path));
  ref.invalidate(behindCountProvider(widget.project.path));
  ```

- [ ] **Step 7.3: Verify compilation**

  ```bash
  flutter analyze
  ```

  Expected: no errors.

- [ ] **Step 7.4: Commit**

  ```bash
  dart format lib/shell/widgets/top_action_bar.dart
  git add lib/shell/widgets/top_action_bar.dart
  git commit -m "feat: wire Commit/Push/Pull/PR enabled states to live git provider"
  ```

---

## Task 8: Strip `isGit`/`currentBranch` from `Project` + Drift migration

**Files:**
- Modify: `lib/data/models/project.dart`
- Modify: `lib/data/datasources/local/app_database.dart`
- Modify: `lib/services/project/project_service.dart`

All consumers of `project.isGit` and `project.currentBranch` were migrated in Tasks 5–7. This task removes the source fields.

- [ ] **Step 8.1: Update `lib/data/models/project.dart`**

  Replace the entire file:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'project.freezed.dart';
  part 'project.g.dart';

  @freezed
  abstract class Project with _$Project {
    const factory Project({
      required String id,
      required String name,
      required String path,
      required DateTime createdAt,
      @Default(0) int sortOrder,
    }) = _Project;

    factory Project.fromJson(Map<String, dynamic> json) =>
        _$ProjectFromJson(json);
  }
  ```

- [ ] **Step 8.2: Update `WorkspaceProjects` table in `app_database.dart`**

  Remove `isGit` and `currentBranch` from the `WorkspaceProjects` class:

  ```dart
  @DataClassName('WorkspaceProjectRow')
  class WorkspaceProjects extends Table {
    TextColumn get id => text()();
    TextColumn get name => text()();
    TextColumn get path => text()();
    DateTimeColumn get createdAt => dateTime()();
    IntColumn get sortOrder => integer().withDefault(const Constant(0))();

    @override
    Set<Column> get primaryKey => {id};
  }
  ```

  Bump `schemaVersion` and add the migration:

  ```dart
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(chatSessions, chatSessions.projectId);
            await migrator.deleteTable('workspace_projects');
            await migrator.createTable(workspaceProjects);
          }
          if (from < 3) {
            await migrator.addColumn(chatSessions, chatSessions.isArchived);
          }
          if (from < 4) {
            await migrator.addColumn(
                workspaceProjects, workspaceProjects.actionsJson);
          }
          if (from < 5) {
            // isGit and currentBranch removed from the Dart model.
            // Columns are left as orphans in the SQLite file — harmless,
            // as Drift only selects declared columns.
          }
        },
      );
  ```

- [ ] **Step 8.3: Update `project_service.dart`**

  In `addExistingFolder`, remove the git detection lines and update the companion + return value:

  ```dart
  Future<Project> addExistingFolder(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      throw ArgumentError('Directory does not exist: $directoryPath');
    }

    final id = _uuid.v4();
    final name = dir.uri.pathSegments
        .lastWhere((s) => s.isNotEmpty, orElse: () => directoryPath);

    await _db.projectDao.upsertProject(
      WorkspaceProjectsCompanion(
        id: Value(id),
        name: Value(name),
        path: Value(directoryPath),
        createdAt: Value(DateTime.now()),
        sortOrder: Value(0),
      ),
    );

    return Project(
      id: id,
      name: name,
      path: directoryPath,
      createdAt: DateTime.now(),
    );
  }
  ```

  Update `_projectFromRow`:

  ```dart
  Project _projectFromRow(WorkspaceProjectRow row) {
    return Project(
      id: row.id,
      name: row.name,
      path: row.path,
      createdAt: row.createdAt,
      sortOrder: row.sortOrder,
    );
  }
  ```

  **Delete** the `refreshGitStatus` method entirely.

  Also remove the import of `git_detector.dart` from `project_service.dart` (it's no longer used there).

- [ ] **Step 8.4: Run code generation**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `project.freezed.dart`, `project.g.dart`, `app_database.g.dart` regenerated.

- [ ] **Step 8.5: Verify compilation**

  ```bash
  flutter analyze
  ```

  Expected: no errors. If any file still references `project.isGit` or `project.currentBranch`, fix by switching to `gitLiveStateProvider`.

- [ ] **Step 8.6: Run tests**

  ```bash
  flutter test
  ```

  Expected: all pass.

- [ ] **Step 8.7: Commit**

  ```bash
  dart format lib/data/models/project.dart \
              lib/data/datasources/local/app_database.dart \
              lib/services/project/project_service.dart
  git add lib/data/models/project.dart \
          lib/data/models/project.freezed.dart \
          lib/data/models/project.g.dart \
          lib/data/datasources/local/app_database.dart \
          lib/data/datasources/local/app_database.g.dart \
          lib/services/project/project_service.dart \
          lib/services/project/project_service.g.dart
  git commit -m "refactor: remove persisted isGit/currentBranch; Drift schema v5"
  ```

---

## Task 9: `BranchPickerNotifier` — branch list, checkout, create-branch

**Files:**
- Create: `lib/features/branch_picker/branch_picker_notifier.dart`
- Create: `test/features/branch_picker/branch_picker_notifier_test.dart`

- [ ] **Step 9.1: Write the failing tests**

  Create `test/features/branch_picker/branch_picker_notifier_test.dart`:

  ```dart
  import 'dart:io';

  import 'package:flutter_test/flutter_test.dart';

  import 'package:code_bench_app/features/branch_picker/branch_picker_notifier.dart';
  import 'package:code_bench_app/services/git/git_service.dart';

  Future<Directory> _initRepo({String branchName = 'main'}) async {
    final dir = await Directory.systemTemp.createTemp('bp_notifier_test_');
    await Process.run('git', ['init', '-b', branchName],
        workingDirectory: dir.path);
    await Process.run('git', ['config', 'user.email', 'test@test.com'],
        workingDirectory: dir.path);
    await Process.run('git', ['config', 'user.name', 'Test'],
        workingDirectory: dir.path);
    await File('${dir.path}/readme.txt').writeAsString('hello');
    await Process.run('git', ['add', '.'], workingDirectory: dir.path);
    await Process.run('git', ['commit', '-m', 'init'],
        workingDirectory: dir.path);
    return dir;
  }

  void main() {
    group('BranchPickerNotifier', () {
      late Directory repoDir;
      late BranchPickerNotifier notifier;

      setUp(() async {
        repoDir = await _initRepo();
        notifier = BranchPickerNotifier(repoDir.path);
      });

      tearDown(() async {
        await repoDir.delete(recursive: true);
      });

      test('listLocalBranches includes current branch', () async {
        final branches = await notifier.listLocalBranches();
        expect(branches, isNotEmpty);
        expect(branches.first, equals(await GitService(repoDir.path).currentBranch()));
      });

      test('worktreeBranches is empty for a plain repo', () async {
        final wt = await notifier.worktreeBranches();
        expect(wt, isEmpty);
      });

      test('checkout switches to an existing branch', () async {
        // Create a second branch
        await Process.run('git', ['checkout', '-b', 'feat/test'],
            workingDirectory: repoDir.path);
        await Process.run('git', ['checkout', 'main'],
            workingDirectory: repoDir.path);

        await notifier.checkout('feat/test');

        final current = await GitService(repoDir.path).currentBranch();
        expect(current, equals('feat/test'));
      });

      test('checkout throws GitException on unknown branch', () async {
        expect(
          () => notifier.checkout('no-such-branch'),
          throwsA(isA<GitException>()),
        );
      });

      test('createBranch creates and switches to new branch', () async {
        await notifier.createBranch('feat/new');
        final current = await GitService(repoDir.path).currentBranch();
        expect(current, equals('feat/new'));
      });

      test('createBranch throws GitException on invalid name', () async {
        // Leading dash is rejected client-side
        expect(
          () => notifier.createBranch('-bad'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('createBranch throws GitException on empty name', () async {
        expect(
          () => notifier.createBranch(''),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  }
  ```

- [ ] **Step 9.2: Run to confirm failures**

  ```bash
  flutter test test/features/branch_picker/branch_picker_notifier_test.dart
  ```

  Expected: compilation error (file doesn't exist yet).

- [ ] **Step 9.3: Create `lib/features/branch_picker/branch_picker_notifier.dart`**

  ```dart
  import 'dart:io';

  import '../../services/git/git_service.dart';

  /// Plain Dart class that handles git operations for the branch picker.
  /// Instantiated per-popover; not a Riverpod provider.
  class BranchPickerNotifier {
    BranchPickerNotifier(this.projectPath);

    final String projectPath;

    /// Returns local branch names, current branch first, then alphabetical.
    Future<List<String>> listLocalBranches() async {
      final result = await Process.run(
        'git',
        ['branch', '--format=%(refname:short)'],
        workingDirectory: projectPath,
      );
      if (result.exitCode != 0) return [];
      final all = (result.stdout as String)
          .trim()
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final current = await GitService(projectPath).currentBranch();
      if (current != null) {
        all.remove(current);
        return [current, ...all..sort()];
      }
      return all..sort();
    }

    /// Returns the set of branch names checked out in other worktrees.
    Future<Set<String>> worktreeBranches() async {
      final result = await Process.run(
        'git',
        ['worktree', 'list', '--porcelain'],
        workingDirectory: projectPath,
      );
      if (result.exitCode != 0) return {};

      final lines = (result.stdout as String).trim().split('\n');
      final branches = <String>{};
      String? currentWorktreePath;

      for (final line in lines) {
        if (line.startsWith('worktree ')) {
          currentWorktreePath = line.substring('worktree '.length).trim();
        } else if (line.startsWith('branch ')) {
          final branchRef = line.substring('branch '.length).trim();
          final shortName = branchRef.replaceFirst('refs/heads/', '');
          // Exclude the main worktree (same path as projectPath)
          if (currentWorktreePath != null &&
              currentWorktreePath != projectPath) {
            branches.add(shortName);
          }
        }
      }
      return branches;
    }

    /// Runs `git checkout [branch]`.
    /// Throws [GitException] on failure (includes uncommitted-conflict message).
    Future<void> checkout(String branch) async {
      final result = await Process.run(
        'git',
        ['checkout', branch],
        workingDirectory: projectPath,
      );
      if (result.exitCode != 0) {
        throw GitException(
          (result.stderr as String).trim().isNotEmpty
              ? (result.stderr as String).trim()
              : 'git checkout failed',
        );
      }
    }

    /// Validates [name] and runs `git checkout -b [name]`.
    /// Throws [ArgumentError] for invalid names, [GitException] on git failure.
    Future<void> createBranch(String name) async {
      if (name.isEmpty) throw ArgumentError('Branch name must not be empty.');
      if (name.startsWith('-')) {
        throw ArgumentError('Branch name must not start with a dash.');
      }
      if (name.contains(' ')) {
        throw ArgumentError('Branch name must not contain spaces.');
      }

      final result = await Process.run(
        'git',
        ['checkout', '-b', name],
        workingDirectory: projectPath,
      );
      if (result.exitCode != 0) {
        throw GitException((result.stderr as String).trim());
      }
    }
  }
  ```

- [ ] **Step 9.4: Run tests — expect all pass**

  ```bash
  flutter test test/features/branch_picker/branch_picker_notifier_test.dart
  ```

  Expected: 7 passing.

- [ ] **Step 9.5: Commit**

  ```bash
  dart format lib/features/branch_picker/branch_picker_notifier.dart \
              test/features/branch_picker/branch_picker_notifier_test.dart
  git add lib/features/branch_picker/branch_picker_notifier.dart \
          test/features/branch_picker/branch_picker_notifier_test.dart
  git commit -m "feat: add BranchPickerNotifier (list, checkout, create-branch)"
  ```

---

## Task 10: `BranchPickerPopover` widget

**Files:**
- Create: `lib/features/branch_picker/widgets/branch_picker_popover.dart`

- [ ] **Step 10.1: Create `lib/features/branch_picker/widgets/branch_picker_popover.dart`**

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:lucide_icons_flutter/lucide_icons.dart';

  import '../../../core/constants/theme_constants.dart';
  import '../../../services/git/git_live_state_provider.dart';
  import '../../../services/git/git_service.dart';
  import '../branch_picker_notifier.dart';

  class BranchPickerPopover extends ConsumerStatefulWidget {
    const BranchPickerPopover({
      super.key,
      required this.layerLink,
      required this.projectPath,
      required this.currentBranch,
      required this.onClose,
    });

    final LayerLink layerLink;
    final String projectPath;
    final String? currentBranch;
    final VoidCallback onClose;

    @override
    ConsumerState<BranchPickerPopover> createState() =>
        _BranchPickerPopoverState();
  }

  class _BranchPickerPopoverState extends ConsumerState<BranchPickerPopover> {
    late final BranchPickerNotifier _notifier;
    final _filterController = TextEditingController();
    final _createController = TextEditingController();
    final _filterFocus = FocusNode();
    final _createFocus = FocusNode();

    List<String> _branches = [];
    Set<String> _worktreeBranches = {};
    bool _loading = true;
    bool _createMode = false;

    @override
    void initState() {
      super.initState();
      _notifier = BranchPickerNotifier(widget.projectPath);
      _filterController.addListener(() => setState(() {}));
      _load();
    }

    @override
    void dispose() {
      _filterController.dispose();
      _createController.dispose();
      _filterFocus.dispose();
      _createFocus.dispose();
      super.dispose();
    }

    Future<void> _load() async {
      final branches = await _notifier.listLocalBranches();
      final wtBranches = await _notifier.worktreeBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
          _worktreeBranches = wtBranches;
          _loading = false;
        });
        _filterFocus.requestFocus();
      }
    }

    Future<void> _checkout(String branch) async {
      try {
        await _notifier.checkout(branch);
        if (mounted) {
          ref.invalidate(gitLiveStateProvider(widget.projectPath));
          widget.onClose();
        }
      } on GitException catch (e) {
        if (mounted) {
          final msg = e.message.contains('would be overwritten')
              ? 'Checkout failed — stash or commit your changes first.'
              : 'Checkout failed: ${e.message}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
          );
        }
      }
    }

    Future<void> _createBranch() async {
      final name = _createController.text.trim();
      try {
        await _notifier.createBranch(name);
        if (mounted) {
          ref.invalidate(gitLiveStateProvider(widget.projectPath));
          widget.onClose();
        }
      } on ArgumentError catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message.toString())),
          );
        }
      } on GitException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${e.message}')),
          );
        }
      }
    }

    List<String> get _filtered {
      final q = _filterController.text.toLowerCase();
      if (q.isEmpty) return _branches;
      return _branches.where((b) => b.toLowerCase().contains(q)).toList();
    }

    @override
    Widget build(BuildContext context) {
      return Stack(
        children: [
          // Dismiss on outside tap
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          // Popover
          CompositedTransformFollower(
            link: widget.layerLink,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.bottomRight,
            offset: const Offset(0, -4),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {}, // stop propagation
                child: Container(
                  width: 250,
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: ThemeConstants.panelBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ThemeConstants.deepBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SearchBar(
                        controller: _filterController,
                        focusNode: _filterFocus,
                      ),
                      Flexible(
                        child: _loading
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                itemCount: _filtered.length,
                                itemBuilder: (ctx, i) {
                                  final branch = _filtered[i];
                                  final isCurrent =
                                      branch == widget.currentBranch;
                                  final isWorktree =
                                      _worktreeBranches.contains(branch);
                                  return _BranchRow(
                                    branch: branch,
                                    isCurrent: isCurrent,
                                    isWorktree: isWorktree,
                                    onTap: (isCurrent || isWorktree)
                                        ? null
                                        : () => _checkout(branch),
                                  );
                                },
                              ),
                      ),
                      _Footer(
                        createMode: _createMode,
                        controller: _createController,
                        focusNode: _createFocus,
                        currentBranch: widget.currentBranch,
                        onEnterCreateMode: () {
                          setState(() => _createMode = true);
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _createFocus.requestFocus(),
                          );
                        },
                        onCreateSubmit: _createBranch,
                        onCreateCancel: () {
                          setState(() {
                            _createMode = false;
                            _createController.clear();
                          });
                          _filterFocus.requestFocus();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────────

  class _SearchBar extends StatelessWidget {
    const _SearchBar({required this.controller, required this.focusNode});

    final TextEditingController controller;
    final FocusNode focusNode;

    @override
    Widget build(BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: ThemeConstants.uiFontSizeLabel,
          ),
          decoration: InputDecoration(
            hintText: 'Filter branches…',
            hintStyle: const TextStyle(
              color: ThemeConstants.faintFg,
              fontSize: ThemeConstants.uiFontSizeLabel,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 6, right: 4),
              child: Icon(LucideIcons.search,
                  size: 11, color: ThemeConstants.faintFg),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            filled: true,
            fillColor: ThemeConstants.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: ThemeConstants.deepBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: ThemeConstants.deepBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: ThemeConstants.accent),
            ),
          ),
        ),
      );
    }
  }

  class _BranchRow extends StatelessWidget {
    const _BranchRow({
      required this.branch,
      required this.isCurrent,
      required this.isWorktree,
      required this.onTap,
    });

    final String branch;
    final bool isCurrent;
    final bool isWorktree;
    final VoidCallback? onTap;

    @override
    Widget build(BuildContext context) {
      final canTap = onTap != null;
      return Tooltip(
        message: isWorktree ? 'Checked out in another worktree' : '',
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            color: isCurrent
                ? ThemeConstants.success.withOpacity(0.07)
                : Colors.transparent,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent ? ThemeConstants.success : Colors.transparent,
                    border: isCurrent
                        ? null
                        : Border.all(color: ThemeConstants.faintFg),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    branch,
                    style: TextStyle(
                      color: isCurrent
                          ? ThemeConstants.success
                          : canTap
                              ? ThemeConstants.textSecondary
                              : ThemeConstants.faintFg,
                      fontSize: ThemeConstants.uiFontSizeLabel,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrent)
                  const Icon(LucideIcons.check,
                      size: 10, color: ThemeConstants.success),
                if (isWorktree)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1F0A),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'worktree',
                      style: TextStyle(
                        color: Color(0xFFE8A228),
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }

  class _Footer extends StatelessWidget {
    const _Footer({
      required this.createMode,
      required this.controller,
      required this.focusNode,
      required this.currentBranch,
      required this.onEnterCreateMode,
      required this.onCreateSubmit,
      required this.onCreateCancel,
    });

    final bool createMode;
    final TextEditingController controller;
    final FocusNode focusNode;
    final String? currentBranch;
    final VoidCallback onEnterCreateMode;
    final VoidCallback onCreateSubmit;
    final VoidCallback onCreateCancel;

    @override
    Widget build(BuildContext context) {
      return Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: ThemeConstants.borderColor)),
        ),
        child: createMode ? _createInput() : _createButton(),
      );
    }

    Widget _createButton() {
      return InkWell(
        onTap: onEnterCreateMode,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            children: const [
              Icon(LucideIcons.plus, size: 11, color: ThemeConstants.faintFg),
              SizedBox(width: 6),
              Text(
                'Create new branch…',
                style: TextStyle(
                  color: ThemeConstants.faintFg,
                  fontSize: ThemeConstants.uiFontSizeLabel,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _createInput() {
      return KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              onCreateCancel();
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.gitBranch,
                      size: 11, color: ThemeConstants.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onSubmitted: (_) => onCreateSubmit(),
                      style: const TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: ThemeConstants.uiFontSizeLabel,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.only(bottom: 2),
                        border: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: ThemeConstants.success),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: ThemeConstants.success),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: ThemeConstants.success),
                        ),
                        hintText: 'branch-name',
                        hintStyle: TextStyle(
                          color: ThemeConstants.faintFg,
                          fontSize: ThemeConstants.uiFontSizeLabel,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '↵ create · esc cancel',
                    style: TextStyle(
                      color: ThemeConstants.faintFg,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              if (currentBranch != null) ...[
                const SizedBox(height: 3),
                Text(
                  'from $currentBranch',
                  style: const TextStyle(
                    color: ThemeConstants.faintFg,
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 10.2: Verify compilation**

  ```bash
  flutter analyze
  ```

  Expected: no errors.

- [ ] **Step 10.3: Commit**

  ```bash
  dart format lib/features/branch_picker/widgets/branch_picker_popover.dart
  git add lib/features/branch_picker/widgets/branch_picker_popover.dart
  git commit -m "feat: add BranchPickerPopover widget"
  ```

---

## Task 11: Wire status bar branch tap → open picker

**Files:**
- Modify: `lib/shell/widgets/status_bar.dart`

- [ ] **Step 11.1: Add the `BranchPickerPopover` import**

  Add to the imports in `status_bar.dart`:

  ```dart
  import '../../features/branch_picker/widgets/branch_picker_popover.dart';
  ```

- [ ] **Step 11.2: Implement `_openPicker`**

  Replace the placeholder `_openPicker` method added in Task 5:

  ```dart
  void _openPicker(Project project, GitLiveState liveState) {
    if (_pickerEntry != null) {
      closePicker();
      return;
    }
    _pickerEntry = OverlayEntry(
      builder: (ctx) => BranchPickerPopover(
        layerLink: _branchLabelLink,
        projectPath: project.path,
        currentBranch: liveState.branch,
        onClose: closePicker,
      ),
    );
    Overlay.of(context).insert(_pickerEntry!);
    setState(() {}); // rebuild so the branch label stays visible under the overlay
  }
  ```

- [ ] **Step 11.3: Verify compilation**

  ```bash
  flutter analyze
  ```

  Expected: no errors.

- [ ] **Step 11.4: Run full test suite**

  ```bash
  flutter test
  ```

  Expected: all pass.

- [ ] **Step 11.5: Final format check**

  ```bash
  dart format lib/ test/
  flutter analyze
  ```

  Expected: no formatting changes, no analysis issues.

- [ ] **Step 11.6: Commit**

  ```bash
  git add lib/shell/widgets/status_bar.dart
  git commit -m "feat: wire branch label tap to open BranchPickerPopover"
  ```

---

## Done

All tasks complete. The app now has:

- Live branch display in the status bar and sidebar tooltip (refreshes on focus + mutation)
- Searchable branch picker popover with worktree-reserved branch detection
- Inline "create new branch" footer input
- Commit/Push/Pull/Create PR buttons enabled only when the action is meaningful
- Active project green highlight in the sidebar
- `isGit`/`currentBranch` removed from `Project` and Drift (schema v5)
- `GitDetector.isGitRepo` recognises git worktrees

After running through the app manually, proceed with the post-plan UI QA checklist.
