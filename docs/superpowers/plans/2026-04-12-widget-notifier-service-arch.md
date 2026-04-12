# Widget → Notifier → Service Architecture: Error-Handling Completion

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all try/catch from business-logic calls in widgets; migrate every command notifier to `AsyncNotifier<void>` + typed failure union so errors flow as `AsyncError` state, never as rethrown exceptions.

**Architecture:** Widgets read `ref.watch(notifierProvider).isLoading` for spinners and `ref.listen(notifierProvider, ...)` for snackbars/dialogs. Notifiers catch service exceptions and map them to a `sealed class {Notifier}Failure` before emitting `AsyncError`. Widgets never import `lib/services/` exception types.

**Tech Stack:** Flutter/Dart, Riverpod (`riverpod_annotation`), `freezed`, `riverpod_annotation` code-gen, `diff_match_patch`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-04-12-widget-notifier-service-arch-design.md`

---

## File Map

**New files (create):**
- `lib/features/chat/notifiers/code_apply_failure.dart` — `CodeApplyFailure` sealed freezed class
- `lib/features/chat/notifiers/code_diff_provider.dart` — `@riverpod Future<DiffResult?> codeDiff(...)` provider + `DiffResult` freezed class
- `lib/features/branch_picker/branch_picker_failure.dart` — `BranchPickerFailure` sealed freezed class
- `lib/features/branch_picker/branch_picker_state.dart` — `BranchPickerState` freezed class
- `lib/features/project_sidebar/project_sidebar_failure.dart` — `ProjectSidebarFailure` sealed freezed class
- `lib/features/chat/notifiers/pr_card_action_failure.dart` — `PrCardActionFailure` sealed freezed class
- `lib/features/settings/settings_actions_failure.dart` — `SettingsActionsFailure` sealed freezed class
- `lib/shell/notifiers/git_actions_failure.dart` — `GitActionsFailure` sealed freezed class
- `lib/features/chat/notifiers/create_pr_failure.dart` — `CreatePrFailure` sealed freezed class

**Modified files:**
- `lib/services/git/git_service.dart` — add `listLocalBranches`, `worktreeBranches`, `checkout`, `createBranch`
- `lib/features/branch_picker/branch_picker_notifier.dart` — convert plain class → `AsyncNotifier<BranchPickerState>`
- `lib/features/chat/notifiers/code_apply_actions.dart` — `AsyncNotifier<void>` + failure union + `readFileContent`
- `lib/features/chat/notifiers/create_pr_actions.dart` — `AsyncNotifier<void>` + failure union
- `lib/features/chat/notifiers/pr_notifier.dart` — add `actionError` to `PrCardState`, stop rethrowing in `approve`/`merge`
- `lib/features/project_sidebar/project_sidebar_actions.dart` — `AsyncNotifier<void>` + failure union
- `lib/features/onboarding/notifiers/github_auth_notifier.dart` — `signOut` catches internally, no rethrow
- `lib/features/settings/settings_notifier.dart` — `testApiKey` catches internally; `saveApiKey` emits failure union
- `lib/shell/notifiers/git_actions.dart` — `AsyncNotifier<void>` + failure union for `initGit`, `commit`, `push`, `pull`
- `lib/shell/widgets/top_action_bar.dart` — remove 9 business try/catch → `ref.listen`; replace 2× `firstWhere` with `firstWhereOrNull`
- `lib/features/chat/widgets/message_bubble.dart` — replace `_applyChange` try/catch → `ref.listen`; replace `_loadDiff` → `ref.watch(codeDiffProvider)`
- `lib/features/chat/widgets/changes_panel.dart` — remove File.readAsString; revert try/catch → `ref.listen`
- `lib/features/chat/widgets/pr_card.dart` — `_approve`/`_merge` try/catch → `ref.listen` on `actionError`
- `lib/features/branch_picker/widgets/branch_picker_popover.dart` — remove all typed catches; drive from `AsyncNotifier` state
- `lib/features/onboarding/widgets/github_step.dart` — `_connectOAuth`/`_testPat` try/catch → redundant (already AsyncError)
- `lib/features/onboarding/widgets/api_keys_step.dart` — remove try/catch; drive from notifier state
- `lib/features/onboarding/widgets/add_project_step.dart` — `_addProject` → `ref.listen`
- `lib/features/project_sidebar/widgets/remove_project_dialog.dart` — `_submit` → `ref.listen`
- `lib/features/project_sidebar/widgets/relocate_project_dialog.dart` — `_submit` → `ref.listen`
- `lib/features/chat/widgets/chat_input_bar.dart` — remove catch, add `ref.listen`
- `lib/features/chat/widgets/message_list.dart` — remove empty catch
- `CLAUDE.md` — add "Error Handling & State Emission" section
- `README.md` — add "Layered architecture" subsection

**Test files (create/modify):**
- `test/features/chat/notifiers/code_apply_actions_test.dart`
- `test/features/chat/notifiers/create_pr_actions_test.dart`
- `test/features/chat/notifiers/pr_notifier_test.dart`
- `test/features/branch_picker/branch_picker_notifier_test.dart` (modify existing)
- `test/features/project_sidebar/project_sidebar_actions_test.dart`
- `test/features/onboarding/github_auth_notifier_test.dart`
- `test/features/settings/settings_actions_test.dart`
- `test/shell/notifiers/git_actions_test.dart`

---

## Task 1: Extend CLAUDE.md with Error-Handling rules

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add "Error Handling & State Emission" section to CLAUDE.md**

Open `CLAUDE.md` (worktree copy) and add this section after the existing `## Riverpod usage rules` section:

```markdown
## Error Handling & State Emission

### Rule 1 — Widget try/catch policy

**Forbidden** in `lib/features/**/widgets/**` and `lib/shell/widgets/**` around any business-logic call (notifier method calls, service calls, async I/O).

**Permitted only** around these widget-layer APIs:
- `launchUrl(...)` from `url_launcher`
- `Clipboard.setData(...)` / `Clipboard.getData()`

Enforcement: code review greps for `try\s*\{` in widget files. Any match must wrap a `launchUrl` or `Clipboard` call — no exceptions.

### Rule 2 — Actions notifier shape

Every command notifier (`*Actions` suffix) extends `AsyncNotifier<void>`. Template:

```dart
@Riverpod(keepAlive: true)
class FooActions extends _$FooActions {
  @override
  FutureOr<void> build() {}

  FooFailure _asFailure(Object e) => switch (e) {
    SpecificException() => const FooFailure.specificError(),
    _ => FooFailure.unknown(e),
  };

  Future<void> doThing(String arg) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(someServiceProvider).doThing(arg);
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
}
```

Widgets drive loading via `ref.watch(fooActionsProvider).isLoading` and errors via `ref.listen`:

```dart
ref.listen(fooActionsProvider, (prev, next) {
  if (next is! AsyncError) return;
  final failure = next.error;
  if (failure is! FooFailure) return;
  switch (failure) {
    case _SpecificError(): showErrorSnackBar(context, 'Specific error message'); break;
    case _Unknown(): showErrorSnackBar(context, 'Unexpected error'); break;
  }
});
```

### Rule 3 — Typed failure unions

Each Actions/Notifier that can fail owns a `freezed` sealed class named `{Notifier}Failure`:

```dart
@freezed
sealed class FooFailure with _$FooFailure {
  const factory FooFailure.specificError([String? detail]) = _SpecificError;
  const factory FooFailure.unknown(Object error) = _Unknown;
}
```

Widgets never `import '../../services/...'` for exception types — they only `switch` on the local failure type. The `switch` must be exhaustive (Dart enforces this at compile time).

### Rule 4 — Family-provider escalation

Default to a single `AsyncValue<void>` slot per Actions notifier. Only escalate to a `family` provider when a **named, concrete** concurrency scenario exists (documented in the notifier's doc comment). Unapproved family usage is rejected in code review.

See canonical examples:
- Actions: `lib/features/chat/notifiers/code_apply_actions.dart`
- Widget: `lib/features/chat/widgets/message_bubble.dart` (`ref.listen` pattern)
```

- [ ] **Step 2: Commit**

```bash
cd .worktrees/tech/2026-04-12-widget-notifier-service-arch
git add CLAUDE.md
git commit -m "docs(claude): add error-handling and state-emission architecture rules"
```

---

## Task 2: Add branch operations to GitService

`BranchPickerNotifier` currently calls `Process.run` directly — a hard violation of the dependency rule. These operations move into `GitService` first so `BranchPickerNotifier` can call them through a proper service.

**Files:**
- Modify: `lib/services/git/git_service.dart`
- Modify: `test/features/branch_picker/branch_picker_notifier_test.dart`

- [ ] **Step 1: Write failing tests for new GitService methods**

Add to `test/features/branch_picker/branch_picker_notifier_test.dart` (in a new `group('GitService branch ops')`):

```dart
import 'package:code_bench_app/services/git/git_service.dart';

group('GitService branch ops', () {
  late Directory repoDir;
  late GitService git;

  setUp(() async {
    repoDir = await _initRepo(); // reuses existing helper
    git = GitService(repoDir.path);
  });

  tearDown(() => repoDir.delete(recursive: true));

  test('listLocalBranches returns current branch first', () async {
    await Process.run('git', ['checkout', '-b', 'feat/x'], workingDirectory: repoDir.path);
    await Process.run('git', ['checkout', 'main'], workingDirectory: repoDir.path);
    final branches = await git.listLocalBranches();
    expect(branches.first, equals('main'));
    expect(branches, contains('feat/x'));
  });

  test('worktreeBranches is empty for plain repo', () async {
    final wt = await git.worktreeBranches();
    expect(wt, isEmpty);
  });

  test('checkout switches branch', () async {
    await Process.run('git', ['checkout', '-b', 'feat/y'], workingDirectory: repoDir.path);
    await Process.run('git', ['checkout', 'main'], workingDirectory: repoDir.path);
    await git.checkout('feat/y');
    final branch = await git.currentBranch();
    expect(branch, equals('feat/y'));
  });

  test('checkout rejects flag-shaped branch name', () async {
    expect(() => git.checkout('--orphan'), throwsArgumentError);
  });

  test('createBranch creates and switches to new branch', () async {
    await git.createBranch('new-branch');
    final branch = await git.currentBranch();
    expect(branch, equals('new-branch'));
  });

  test('createBranch rejects flag-shaped name', () async {
    expect(() => git.createBranch('--bad'), throwsArgumentError);
  });
});
```

- [ ] **Step 2: Run to verify tests fail**

```bash
cd .worktrees/tech/2026-04-12-widget-notifier-service-arch
flutter test test/features/branch_picker/branch_picker_notifier_test.dart
```
Expected: FAIL — `listLocalBranches`, `worktreeBranches`, `checkout`, `createBranch` not found on `GitService`.

- [ ] **Step 3: Add branch operations to GitService**

In `lib/services/git/git_service.dart`, add these methods to the `GitService` class after the existing `listRemotes` method:

```dart
/// Returns local branch names, current branch first, then alphabetical.
Future<List<String>> listLocalBranches() async {
  final result = await Process.run(
    'git', ['branch', '--format=%(refname:short)'],
    workingDirectory: projectPath,
  );
  if (result.exitCode != 0) return const [];
  final all = (result.stdout as String)
      .trim()
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final current = await _currentBranch();
  if (current != null) {
    all.remove(current);
    return [current, ...all..sort()];
  }
  return all..sort();
}

/// Returns the set of branch names checked out in other git worktrees.
Future<Set<String>> worktreeBranches() async {
  final result = await Process.run(
    'git', ['worktree', 'list', '--porcelain'],
    workingDirectory: projectPath,
  );
  if (result.exitCode != 0) return const {};
  final blocks = (result.stdout as String).trim().split(RegExp(r'\n\n+'));
  final branches = <String>{};
  for (int i = 1; i < blocks.length; i++) {
    for (final line in blocks[i].split('\n')) {
      if (line.startsWith('branch ')) {
        final ref = line.substring('branch '.length).trim();
        branches.add(ref.replaceFirst('refs/heads/', ''));
      }
    }
  }
  return branches;
}

/// Runs `git checkout [branch]`.
/// Throws [ArgumentError] for invalid names, [GitException] on git failure.
Future<void> checkout(String branch) async {
  if (branch.isEmpty) throw ArgumentError('Branch name must not be empty.');
  if (branch.startsWith('-')) {
    sLog('[GitService] flag-shaped checkout branch rejected: "$branch"');
    throw ArgumentError('Branch name must not start with a dash.');
  }
  final result = await Process.run(
    'git', ['checkout', branch],
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
  if (name.startsWith('-')) throw ArgumentError('Branch name must not start with a dash.');
  if (name.contains(' ')) throw ArgumentError('Branch name must not contain spaces.');
  final result = await Process.run(
    'git', ['checkout', '-b', name],
    workingDirectory: projectPath,
  );
  if (result.exitCode != 0) {
    throw GitException((result.stderr as String).trim());
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/branch_picker/branch_picker_notifier_test.dart
```
Expected: the new `GitService branch ops` group passes. Existing `BranchPickerNotifier` tests may still fail — that's OK, Task 3 fixes them.

- [ ] **Step 5: Commit**

```bash
git add lib/services/git/git_service.dart test/features/branch_picker/branch_picker_notifier_test.dart
git commit -m "feat(git): add listLocalBranches, worktreeBranches, checkout, createBranch to GitService"
```

---

## Task 3: BranchPickerNotifier → AsyncNotifier<BranchPickerState>

`BranchPickerNotifier` is a plain class calling `Process.run` directly — violating the dependency rule. Convert it to a proper `AsyncNotifier` backed by `GitService`.

**Files:**
- Create: `lib/features/branch_picker/branch_picker_state.dart`
- Create: `lib/features/branch_picker/branch_picker_failure.dart`
- Modify: `lib/features/branch_picker/branch_picker_notifier.dart`
- Modify: `test/features/branch_picker/branch_picker_notifier_test.dart`

- [ ] **Step 1: Create BranchPickerState**

Create `lib/features/branch_picker/branch_picker_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'branch_picker_state.freezed.dart';

@freezed
abstract class BranchPickerState with _$BranchPickerState {
  const factory BranchPickerState({
    @Default([]) List<String> branches,
    @Default({}) Set<String> worktreeBranches,
  }) = _BranchPickerState;
}
```

- [ ] **Step 2: Create BranchPickerFailure**

Create `lib/features/branch_picker/branch_picker_failure.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'branch_picker_failure.freezed.dart';

@freezed
sealed class BranchPickerFailure with _$BranchPickerFailure {
  /// git binary missing or working directory deleted.
  const factory BranchPickerFailure.gitUnavailable() = _GitUnavailable;
  /// Branch name fails validation (empty or starts with dash).
  const factory BranchPickerFailure.invalidName(String reason) = _InvalidName;
  /// `git checkout` failed (e.g. uncommitted changes would be overwritten).
  const factory BranchPickerFailure.checkoutConflict(String message) = _CheckoutConflict;
  /// `git checkout -b` failed (branch already exists, etc.).
  const factory BranchPickerFailure.createFailed(String message) = _CreateFailed;
  const factory BranchPickerFailure.unknown(Object error) = _Unknown;
}
```

- [ ] **Step 3: Write failing tests for new notifier shape**

Replace the existing `BranchPickerNotifier` group in `test/features/branch_picker/branch_picker_notifier_test.dart` with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/features/branch_picker/branch_picker_notifier.dart';
import 'package:code_bench_app/features/branch_picker/branch_picker_failure.dart';

// Keep existing _initRepo helper and GitService branch ops group.

group('BranchPickerNotifier (AsyncNotifier)', () {
  late Directory repoDir;

  setUp(() async { repoDir = await _initRepo(); });
  tearDown(() => repoDir.delete(recursive: true));

  ProviderContainer _container(String path) {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('build loads branches successfully', () async {
    final c = _container(repoDir.path);
    final state = await c.read(branchPickerProvider(repoDir.path).future);
    expect(state.branches, isNotEmpty);
    expect(state.branches.first, equals('main'));
    expect(state.worktreeBranches, isEmpty);
  });

  test('checkout transitions to loading then success', () async {
    final c = _container(repoDir.path);
    await c.read(branchPickerProvider(repoDir.path).future);
    await Process.run('git', ['branch', 'feat/test'], workingDirectory: repoDir.path);
    await c.read(branchPickerProvider(repoDir.path).notifier).checkout('feat/test');
    expect(c.read(branchPickerProvider(repoDir.path)).hasError, isFalse);
  });

  test('checkout with flag-shaped name emits BranchPickerFailure.invalidName', () async {
    final c = _container(repoDir.path);
    await c.read(branchPickerProvider(repoDir.path).future);
    await c.read(branchPickerProvider(repoDir.path).notifier).checkout('--orphan');
    final state = c.read(branchPickerProvider(repoDir.path));
    expect(state.hasError, isTrue);
    expect(state.error, isA<BranchPickerFailure>());
    expect(state.error, isA<_InvalidName>());
  });

  test('createBranch emits failure for duplicate name', () async {
    final c = _container(repoDir.path);
    await c.read(branchPickerProvider(repoDir.path).future);
    await c.read(branchPickerProvider(repoDir.path).notifier).createBranch('main');
    final state = c.read(branchPickerProvider(repoDir.path));
    expect(state.hasError, isTrue);
    expect(state.error, isA<BranchPickerFailure>());
  });
});
```

- [ ] **Step 4: Run to verify tests fail**

```bash
flutter test test/features/branch_picker/branch_picker_notifier_test.dart
```
Expected: FAIL — `BranchPickerNotifier` has wrong shape, `branchPickerProvider` not an AsyncNotifier.

- [ ] **Step 5: Rewrite BranchPickerNotifier**

Replace the entire content of `lib/features/branch_picker/branch_picker_notifier.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../services/git/git_service.dart';
import 'branch_picker_failure.dart';
import 'branch_picker_state.dart';

part 'branch_picker_notifier.g.dart';

@riverpod
class BranchPickerNotifier extends _$BranchPickerNotifier {
  @override
  Future<BranchPickerState> build(String projectPath) async {
    final git = ref.read(gitServiceProvider(projectPath));
    final branches = await git.listLocalBranches();
    final wtBranches = await git.worktreeBranches();
    return BranchPickerState(branches: branches, worktreeBranches: wtBranches);
  }

  BranchPickerFailure _asFailure(Object e) => switch (e) {
    ArgumentError(:final message) => BranchPickerFailure.invalidName(message?.toString() ?? 'Invalid branch name'),
    GitException(:final message) when message.contains('would be overwritten') =>
        BranchPickerFailure.checkoutConflict('Checkout failed — stash or commit your changes first.'),
    GitException(:final message) => BranchPickerFailure.createFailed(message),
    _ => BranchPickerFailure.gitUnavailable(),
  };

  Future<void> checkout(String branch) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(gitServiceProvider(projectPath)).checkout(branch);
        // Reload branch list after successful checkout.
        return await ref.read(gitServiceProvider(projectPath)).listLocalBranches().then(
          (branches) async {
            final wt = await ref.read(gitServiceProvider(projectPath)).worktreeBranches();
            return BranchPickerState(branches: branches, worktreeBranches: wt);
          },
        );
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> createBranch(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(gitServiceProvider(projectPath)).createBranch(name);
        final branches = await ref.read(gitServiceProvider(projectPath)).listLocalBranches();
        final wt = await ref.read(gitServiceProvider(projectPath)).worktreeBranches();
        return BranchPickerState(branches: branches, worktreeBranches: wt);
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
}
```

- [ ] **Step 6: Run build_runner for new freezed + g.dart files**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Run tests to verify they pass**

```bash
flutter test test/features/branch_picker/branch_picker_notifier_test.dart
```
Expected: all groups pass.

- [ ] **Step 8: Commit generated files with source**

```bash
dart format lib/features/branch_picker/ lib/services/git/git_service.dart
git add lib/features/branch_picker/ lib/services/git/git_service.dart test/features/branch_picker/
git commit -m "refactor(branch-picker): convert BranchPickerNotifier to AsyncNotifier with typed failure union"
```

---

## Task 4: CodeApplyActions → AsyncNotifier<void> + CodeApplyFailure + codeDiff provider

**Files:**
- Create: `lib/features/chat/notifiers/code_apply_failure.dart`
- Create: `lib/features/chat/notifiers/code_diff_provider.dart`
- Modify: `lib/features/chat/notifiers/code_apply_actions.dart`
- Create: `test/features/chat/notifiers/code_apply_actions_test.dart`

- [ ] **Step 1: Create CodeApplyFailure**

Create `lib/features/chat/notifiers/code_apply_failure.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'code_apply_failure.freezed.dart';

@freezed
sealed class CodeApplyFailure with _$CodeApplyFailure {
  /// Project folder was deleted or moved off disk.
  const factory CodeApplyFailure.projectMissing() = _ProjectMissing;
  /// Attempted to write outside the project root.
  const factory CodeApplyFailure.outsideProject() = _OutsideProject;
  /// Low-level disk write failure.
  const factory CodeApplyFailure.diskWrite(String message) = _DiskWrite;
  /// File could not be read for conflict view.
  const factory CodeApplyFailure.fileRead(String path) = _FileRead;
  const factory CodeApplyFailure.unknown(Object error) = _Unknown;
}
```

- [ ] **Step 2: Create codeDiff provider**

Create `lib/features/chat/notifiers/code_diff_provider.dart`:

```dart
import 'dart:io';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/apply/apply_service.dart';

part 'code_diff_provider.freezed.dart';
part 'code_diff_provider.g.dart';

@freezed
abstract class DiffResult with _$DiffResult {
  const factory DiffResult({
    required String? originalContent,
    required List<Diff> diffs,
  }) = _DiffResult;
}

/// Computes a diff between the on-disk file and [newContent].
/// Returns `null` on any error (outside-project, unreadable file, etc.).
/// Widgets use `AsyncValue.when` to drive loading/error/data states.
@riverpod
Future<DiffResult?> codeDiff(
  Ref ref, {
  required String absolutePath,
  required String projectPath,
  required String newContent,
}) async {
  try {
    final original = await ApplyService.readOriginalForDiff(absolutePath, projectPath);
    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(original ?? '', newContent);
    dmp.diffCleanupSemantic(diffs);
    return DiffResult(originalContent: original, diffs: diffs);
  } on StateError {
    return null; // outside project — widget shows "outside project" error state
  } on IOException {
    return null; // unreadable — widget shows "could not read file"
  } catch (_) {
    return null;
  }
}
```

- [ ] **Step 3: Write failing tests for CodeApplyActions**

Create `test/features/chat/notifiers/code_apply_actions_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:code_bench_app/features/chat/notifiers/code_apply_actions.dart';
import 'package:code_bench_app/features/chat/notifiers/code_apply_failure.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';

class MockApplyService extends Mock implements ApplyService {}

void main() {
  late MockApplyService mockService;

  setUp(() {
    mockService = MockApplyService();
    registerFallbackValue(const AppliedChange(
      id: 'id', sessionId: 's', messageId: 'm',
      filePath: '/f', originalContent: '', newContent: '',
      additions: 0, deletions: 0,
    ));
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      applyServiceProvider.overrideWithValue(mockService),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('applyChange', () {
    test('happy path — state becomes AsyncData', () async {
      when(() => mockService.applyChange(
        filePath: any(named: 'filePath'),
        projectPath: any(named: 'projectPath'),
        newContent: any(named: 'newContent'),
        sessionId: any(named: 'sessionId'),
        messageId: any(named: 'messageId'),
      )).thenAnswer((_) async {});

      final c = makeContainer();
      await c.read(codeApplyActionsProvider.notifier).applyChange(
        projectId: 'p', filePath: '/p/f.dart',
        projectPath: '/p', newContent: 'x',
        sessionId: 's', messageId: 'm',
      );
      expect(c.read(codeApplyActionsProvider), isA<AsyncData<void>>());
    });

    test('ProjectMissingException → CodeApplyFailure.projectMissing', () async {
      when(() => mockService.applyChange(
        filePath: any(named: 'filePath'),
        projectPath: any(named: 'projectPath'),
        newContent: any(named: 'newContent'),
        sessionId: any(named: 'sessionId'),
        messageId: any(named: 'messageId'),
      )).thenThrow(const ProjectMissingException('p'));

      final c = makeContainer();
      await c.read(codeApplyActionsProvider.notifier).applyChange(
        projectId: 'p', filePath: '/p/f.dart',
        projectPath: '/p', newContent: 'x',
        sessionId: 's', messageId: 'm',
      );
      final state = c.read(codeApplyActionsProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<_ProjectMissing>());
    });

    test('StateError → CodeApplyFailure.outsideProject', () async {
      when(() => mockService.applyChange(
        filePath: any(named: 'filePath'),
        projectPath: any(named: 'projectPath'),
        newContent: any(named: 'newContent'),
        sessionId: any(named: 'sessionId'),
        messageId: any(named: 'messageId'),
      )).thenThrow(StateError('outside'));

      final c = makeContainer();
      await c.read(codeApplyActionsProvider.notifier).applyChange(
        projectId: 'p', filePath: '/p/f.dart',
        projectPath: '/p', newContent: 'x',
        sessionId: 's', messageId: 'm',
      );
      expect(c.read(codeApplyActionsProvider).error, isA<_OutsideProject>());
    });

    test('FileSystemException → CodeApplyFailure.diskWrite', () async {
      when(() => mockService.applyChange(
        filePath: any(named: 'filePath'),
        projectPath: any(named: 'projectPath'),
        newContent: any(named: 'newContent'),
        sessionId: any(named: 'sessionId'),
        messageId: any(named: 'messageId'),
      )).thenThrow(const FileSystemException('disk full', '/p/f.dart'));

      final c = makeContainer();
      await c.read(codeApplyActionsProvider.notifier).applyChange(
        projectId: 'p', filePath: '/p/f.dart',
        projectPath: '/p', newContent: 'x',
        sessionId: 's', messageId: 'm',
      );
      expect(c.read(codeApplyActionsProvider).error, isA<_DiskWrite>());
    });

    test('ProjectMissingException triggers ProjectSidebarActions.refreshProjectStatus side effect', () async {
      when(() => mockService.applyChange(
        filePath: any(named: 'filePath'),
        projectPath: any(named: 'projectPath'),
        newContent: any(named: 'newContent'),
        sessionId: any(named: 'sessionId'),
        messageId: any(named: 'messageId'),
      )).thenThrow(const ProjectMissingException('proj-1'));

      bool refreshCalled = false;
      final c = ProviderContainer(overrides: [
        applyServiceProvider.overrideWithValue(mockService),
        projectSidebarActionsProvider.overrideWith((ref) {
          final notifier = MockProjectSidebarActions();
          when(() => notifier.refreshProjectStatus(any())).thenAnswer((_) async {
            refreshCalled = true;
          });
          return notifier;
        }),
      ]);
      addTearDown(c.dispose);

      await c.read(codeApplyActionsProvider.notifier).applyChange(
        projectId: 'proj-1', filePath: '/p/f.dart',
        projectPath: '/p', newContent: 'x',
        sessionId: 's', messageId: 'm',
      );
      await Future<void>.delayed(Duration.zero); // let unawaited fire
      expect(refreshCalled, isTrue);
    });
  });

  group('revertChange', () {
    test('happy path — state becomes AsyncData', () async {
      when(() => mockService.revertChange(
        change: any(named: 'change'),
        isGit: any(named: 'isGit'),
        projectPath: any(named: 'projectPath'),
      )).thenAnswer((_) async {});

      final c = makeContainer();
      await c.read(codeApplyActionsProvider.notifier).revertChange(
        change: const AppliedChange(
          id: 'id', sessionId: 's', messageId: 'm',
          filePath: '/p/f.dart', originalContent: '', newContent: '',
          additions: 0, deletions: 0,
        ),
        isGit: false,
        projectPath: '/p',
      );
      expect(c.read(codeApplyActionsProvider), isA<AsyncData<void>>());
    });

    test('exception → CodeApplyFailure.unknown', () async {
      when(() => mockService.revertChange(
        change: any(named: 'change'),
        isGit: any(named: 'isGit'),
        projectPath: any(named: 'projectPath'),
      )).thenThrow(Exception('boom'));

      final c = makeContainer();
      await c.read(codeApplyActionsProvider.notifier).revertChange(
        change: const AppliedChange(
          id: 'id', sessionId: 's', messageId: 'm',
          filePath: '/p/f.dart', originalContent: '', newContent: '',
          additions: 0, deletions: 0,
        ),
        isGit: false,
        projectPath: '/p',
      );
      expect(c.read(codeApplyActionsProvider).error, isA<_Unknown>());
    });
  });

  group('readFileContent', () {
    test('returns file content on success', () async {
      final dir = await Directory.systemTemp.createTemp();
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/test.dart')..writeAsStringSync('hello');

      final c = makeContainer();
      final content = await c.read(codeApplyActionsProvider.notifier).readFileContent(file.path);
      expect(content, equals('hello'));
    });

    test('throws CodeApplyFailure.fileRead for missing file', () async {
      final c = makeContainer();
      expect(
        () => c.read(codeApplyActionsProvider.notifier).readFileContent('/nonexistent/file.dart'),
        throwsA(isA<_FileRead>()),
      );
    });
  });
}
```

- [ ] **Step 4: Run to verify tests fail**

```bash
flutter test test/features/chat/notifiers/code_apply_actions_test.dart
```
Expected: FAIL — `CodeApplyActions` has wrong shape.

- [ ] **Step 5: Rewrite CodeApplyActions**

Replace `lib/features/chat/notifiers/code_apply_actions.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/models/applied_change.dart';
import '../../../features/project_sidebar/project_sidebar_actions.dart';
import '../../../services/apply/apply_service.dart';
import 'code_apply_failure.dart';

part 'code_apply_actions.g.dart';

@Riverpod(keepAlive: true)
class CodeApplyActions extends _$CodeApplyActions {
  @override
  FutureOr<void> build() {}

  CodeApplyFailure _asApplyFailure(Object e) => switch (e) {
    ProjectMissingException() => const CodeApplyFailure.projectMissing(),
    StateError() => const CodeApplyFailure.outsideProject(),
    FileSystemException(:final message) => CodeApplyFailure.diskWrite(message),
    _ => CodeApplyFailure.unknown(e),
  };

  Future<void> applyChange({
    required String projectId,
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(applyServiceProvider).applyChange(
          filePath: filePath,
          projectPath: projectPath,
          newContent: newContent,
          sessionId: sessionId,
          messageId: messageId,
        );
      } on ProjectMissingException catch (e, st) {
        unawaited(
          ref.read(projectSidebarActionsProvider.notifier)
              .refreshProjectStatus(projectId)
              .catchError((Object err) =>
                  dLog('[CodeApplyActions] sidebar refresh after projectMissing failed: $err')),
        );
        Error.throwWithStackTrace(_asApplyFailure(e), st);
      } catch (e, st) {
        Error.throwWithStackTrace(_asApplyFailure(e), st);
      }
    });
  }

  Future<void> revertChange({
    required AppliedChange change,
    required bool isGit,
    required String projectPath,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(applyServiceProvider).revertChange(
          change: change, isGit: isGit, projectPath: projectPath,
        );
      } catch (e, st) {
        Error.throwWithStackTrace(CodeApplyFailure.unknown(e), st);
      }
    });
  }

  /// Reads raw file content for the conflict-merge view.
  /// Throws [CodeApplyFailure.fileRead] on IO failure.
  Future<String> readFileContent(String path) async {
    try {
      return await File(path).readAsString();
    } on IOException {
      throw CodeApplyFailure.fileRead(path);
    }
  }
}
```

- [ ] **Step 6: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Run tests to verify they pass**

```bash
flutter test test/features/chat/notifiers/code_apply_actions_test.dart
```
Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
dart format lib/features/chat/notifiers/
git add lib/features/chat/notifiers/ test/features/chat/notifiers/code_apply_actions_test.dart
git commit -m "refactor(apply): CodeApplyActions → AsyncNotifier<void> with CodeApplyFailure union + codeDiff provider"
```

---

## Task 5: PrCardNotifier — in-band actionError for approve/merge

`PrCardNotifier` is an `AsyncNotifier<PrCardState>` (not void), so action failures use the same in-band `pollError` pattern already in `PrCardState`.

**Files:**
- Modify: `lib/features/chat/notifiers/pr_notifier.dart`
- Create: `test/features/chat/notifiers/pr_notifier_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/chat/notifiers/pr_notifier_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:code_bench_app/features/chat/notifiers/pr_notifier.dart';
import 'package:code_bench_app/services/github/github_api_service.dart';
import 'package:code_bench_app/core/errors/app_exception.dart';

class MockGitHubApiService extends Mock implements GitHubApiService {}

void main() {
  late MockGitHubApiService mockApi;

  setUp(() { mockApi = MockGitHubApiService(); });

  Map<String, dynamic> _prPayload({bool merged = false}) => {
    'number': 1, 'title': 'Test PR', 'state': 'open',
    'merged': merged, 'merged_at': null,
    'head': {'ref': 'feat/x', 'sha': 'abc123'},
    'base': {'ref': 'main'},
    'commits': 1, 'html_url': 'https://github.com/o/r/pull/1',
  };

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      githubApiServiceProvider.overrideWith((ref) async => mockApi),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('approve', () {
    test('success — approved flag set, no actionError', () async {
      when(() => mockApi.getPullRequest('o', 'r', 1))
          .thenAnswer((_) async => _prPayload());
      when(() => mockApi.getCheckRuns('o', 'r', 'abc123'))
          .thenAnswer((_) async => []);
      when(() => mockApi.approvePullRequest('o', 'r', 1))
          .thenAnswer((_) async {});

      final c = makeContainer();
      await c.read(prCardProvider('o', 'r', 1).future);
      await c.read(prCardProvider('o', 'r', 1).notifier).approve();
      final state = c.read(prCardProvider('o', 'r', 1)).value!;
      expect(state.approved, isTrue);
      expect(state.actionError, isNull);
    });

    test('NetworkException → actionError set, approved stays false', () async {
      when(() => mockApi.getPullRequest('o', 'r', 1))
          .thenAnswer((_) async => _prPayload());
      when(() => mockApi.getCheckRuns('o', 'r', 'abc123'))
          .thenAnswer((_) async => []);
      when(() => mockApi.approvePullRequest('o', 'r', 1))
          .thenThrow(const NetworkException('forbidden', statusCode: 403));

      final c = makeContainer();
      await c.read(prCardProvider('o', 'r', 1).future);
      await c.read(prCardProvider('o', 'r', 1).notifier).approve();
      final state = c.read(prCardProvider('o', 'r', 1)).value!;
      expect(state.approved, isFalse);
      expect(state.actionError, isNotNull);
      expect(state.actionError, contains('Permission denied'));
    });
  });

  group('merge', () {
    test('NetworkException 405 → actionError with merge-conflict message', () async {
      when(() => mockApi.getPullRequest('o', 'r', 1))
          .thenAnswer((_) async => _prPayload());
      when(() => mockApi.getCheckRuns('o', 'r', 'abc123'))
          .thenAnswer((_) async => []);
      when(() => mockApi.mergePullRequest('o', 'r', 1))
          .thenThrow(const NetworkException('conflict', statusCode: 409));

      final c = makeContainer();
      await c.read(prCardProvider('o', 'r', 1).future);
      await c.read(prCardProvider('o', 'r', 1).notifier).merge();
      final state = c.read(prCardProvider('o', 'r', 1)).value!;
      expect(state.merged, isFalse);
      expect(state.actionError, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run to verify tests fail**

```bash
flutter test test/features/chat/notifiers/pr_notifier_test.dart
```
Expected: FAIL — `actionError` field doesn't exist on `PrCardState`.

- [ ] **Step 3: Update PrCardState and PrCardNotifier**

In `lib/features/chat/notifiers/pr_notifier.dart`, add `actionError` to `PrCardState` and update `approve`/`merge` to catch internally:

```dart
class PrCardState {
  const PrCardState({
    required this.pr,
    required this.checkRuns,
    required this.approved,
    required this.merged,
    this.pollError,
    this.actionError,   // ← add this
  });

  final Map<String, dynamic> pr;
  final List<Map<String, dynamic>> checkRuns;
  final bool approved;
  final bool merged;
  final String? pollError;
  final String? actionError;  // ← add this

  PrCardState copyWith({
    Map<String, dynamic>? pr,
    List<Map<String, dynamic>>? checkRuns,
    bool? approved,
    bool? merged,
    String? pollError,
    bool clearPollError = false,
    String? actionError,        // ← add this
    bool clearActionError = false,  // ← add this
  }) => PrCardState(
    pr: pr ?? this.pr,
    checkRuns: checkRuns ?? this.checkRuns,
    approved: approved ?? this.approved,
    merged: merged ?? this.merged,
    pollError: clearPollError ? null : (pollError ?? this.pollError),
    actionError: clearActionError ? null : (actionError ?? this.actionError),  // ← add
  );
}
```

Update `approve()` and `merge()` in `PrCardNotifier` to stop rethrowing:

```dart
Future<void> approve() async {
  final svc = await ref.read(githubApiServiceProvider.future);
  if (svc == null) return;
  final current = state.value;
  if (current != null) state = AsyncData(current.copyWith(clearActionError: true));
  try {
    await svc.approvePullRequest(owner, repo, prNumber);
    final updated = state.value;
    if (updated != null) state = AsyncData(updated.copyWith(approved: true));
  } catch (e) {
    dLog('[PrCardNotifier] approve failed: ${e.runtimeType}');
    final updated = state.value;
    if (updated != null) {
      state = AsyncData(updated.copyWith(actionError: _friendlyError(e)));
    }
  }
}

Future<void> merge() async {
  final svc = await ref.read(githubApiServiceProvider.future);
  if (svc == null) return;
  final current = state.value;
  if (current != null) state = AsyncData(current.copyWith(clearActionError: true));
  try {
    await svc.mergePullRequest(owner, repo, prNumber);
    final updated = state.value;
    if (updated != null) state = AsyncData(updated.copyWith(merged: true));
    await refresh();
  } catch (e) {
    dLog('[PrCardNotifier] merge failed: ${e.runtimeType}');
    final updated = state.value;
    if (updated != null) {
      state = AsyncData(updated.copyWith(actionError: _friendlyError(e)));
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/chat/notifiers/pr_notifier_test.dart
```
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
dart format lib/features/chat/notifiers/pr_notifier.dart
git add lib/features/chat/notifiers/pr_notifier.dart test/features/chat/notifiers/pr_notifier_test.dart
git commit -m "refactor(pr): PrCardNotifier approve/merge emit actionError instead of rethrowing"
```

---

## Task 6: ProjectSidebarActions → AsyncNotifier<void> + ProjectSidebarFailure

**Files:**
- Create: `lib/features/project_sidebar/project_sidebar_failure.dart`
- Modify: `lib/features/project_sidebar/project_sidebar_actions.dart`
- Create: `test/features/project_sidebar/project_sidebar_actions_test.dart`

- [ ] **Step 1: Create ProjectSidebarFailure**

Create `lib/features/project_sidebar/project_sidebar_failure.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_sidebar_failure.freezed.dart';

@freezed
sealed class ProjectSidebarFailure with _$ProjectSidebarFailure {
  const factory ProjectSidebarFailure.duplicatePath(String path) = _DuplicatePath;
  const factory ProjectSidebarFailure.invalidPath(String reason) = _InvalidPath;
  const factory ProjectSidebarFailure.storageError(String message) = _StorageError;
  const factory ProjectSidebarFailure.unknown(Object error) = _Unknown;
}
```

- [ ] **Step 2: Write failing tests**

Create `test/features/project_sidebar/project_sidebar_actions_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:code_bench_app/features/project_sidebar/project_sidebar_actions.dart';
import 'package:code_bench_app/features/project_sidebar/project_sidebar_failure.dart';
import 'package:code_bench_app/services/project/project_service.dart';
import 'package:code_bench_app/services/session/session_service.dart';

class MockProjectService extends Mock implements ProjectService {}
class MockSessionService extends Mock implements SessionService {}

void main() {
  late MockProjectService mockProjects;
  late MockSessionService mockSessions;

  setUp(() {
    mockProjects = MockProjectService();
    mockSessions = MockSessionService();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      projectServiceProvider.overrideWithValue(mockProjects),
      sessionServiceProvider.overrideWithValue(mockSessions),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('addExistingFolder', () {
    test('happy path — state becomes AsyncData', () async {
      when(() => mockProjects.addExistingFolder(any()))
          .thenAnswer((_) async => fakeProject());

      final c = makeContainer();
      await c.read(projectSidebarActionsProvider.notifier).addExistingFolder('/some/path');
      expect(c.read(projectSidebarActionsProvider), isA<AsyncData<void>>());
    });

    test('DuplicateProjectPathException → ProjectSidebarFailure.duplicatePath', () async {
      when(() => mockProjects.addExistingFolder(any()))
          .thenThrow(DuplicateProjectPathException('/some/path'));

      final c = makeContainer();
      await c.read(projectSidebarActionsProvider.notifier).addExistingFolder('/some/path');
      final state = c.read(projectSidebarActionsProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<_DuplicatePath>());
    });

    test('ArgumentError → ProjectSidebarFailure.invalidPath', () async {
      when(() => mockProjects.addExistingFolder(any()))
          .thenThrow(ArgumentError('folder does not exist'));

      final c = makeContainer();
      await c.read(projectSidebarActionsProvider.notifier).addExistingFolder('/bad/path');
      expect(c.read(projectSidebarActionsProvider).error, isA<_InvalidPath>());
    });
  });

  group('removeProject', () {
    test('happy path — state becomes AsyncData', () async {
      when(() => mockProjects.removeProject(any())).thenAnswer((_) async {});
      when(() => mockSessions.getSessionsByProject(any())).thenAnswer((_) async => []);

      final c = makeContainer();
      await c.read(projectSidebarActionsProvider.notifier).removeProject('proj-1');
      expect(c.read(projectSidebarActionsProvider), isA<AsyncData<void>>());
    });

    test('exception → ProjectSidebarFailure.unknown', () async {
      when(() => mockProjects.removeProject(any())).thenThrow(Exception('db error'));

      final c = makeContainer();
      await c.read(projectSidebarActionsProvider.notifier).removeProject('proj-1');
      expect(c.read(projectSidebarActionsProvider).error, isA<_Unknown>());
    });
  });
}
```

- [ ] **Step 3: Run to verify tests fail**

```bash
flutter test test/features/project_sidebar/project_sidebar_actions_test.dart
```
Expected: FAIL — `ProjectSidebarActions` still rethrowing.

- [ ] **Step 4: Update ProjectSidebarActions**

In `lib/features/project_sidebar/project_sidebar_actions.dart`, change the class declaration and update mutating methods:

```dart
@Riverpod(keepAlive: true)
class ProjectSidebarActions extends _$ProjectSidebarActions {
  @override
  FutureOr<void> build() {}

  ProjectSidebarFailure _asFailure(Object e) => switch (e) {
    DuplicateProjectPathException(:final path) => ProjectSidebarFailure.duplicatePath(path),
    ArgumentError(:final message) => ProjectSidebarFailure.invalidPath(message?.toString() ?? 'Invalid path'),
    _ => ProjectSidebarFailure.unknown(e),
  };

  Future<void> addExistingFolder(String path) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await _projects.addExistingFolder(path);
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> relocateProject(String id, String path) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await _projects.relocateProject(id, path);
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> removeProject(String id, {bool deleteSessions = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        if (deleteSessions) {
          final sessions = await _sessions.getSessionsByProject(id);
          for (final s in sessions) {
            await _sessions.deleteSession(s.sessionId);
          }
        }
        await _projects.removeProject(id);
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
  // Keep refreshProjectStatus, refreshProjectStatuses, updateProjectActions,
  // getSessionsByProject, createSession, archiveSession, deleteSession,
  // updateSessionTitle, refreshGitState, projectExistsOnDisk,
  // resolveDroppedDirectory, refreshArchivedSessions unchanged.
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
flutter test test/features/project_sidebar/project_sidebar_actions_test.dart
```

- [ ] **Step 6: Commit**

```bash
dart format lib/features/project_sidebar/
git add lib/features/project_sidebar/ test/features/project_sidebar/
git commit -m "refactor(sidebar): ProjectSidebarActions → AsyncNotifier<void> with ProjectSidebarFailure"
```

---

## Task 7: GitHubAuthNotifier + SettingsActions + CreatePrActions

**Files:**
- Modify: `lib/features/onboarding/notifiers/github_auth_notifier.dart`
- Create: `lib/features/settings/settings_actions_failure.dart`
- Modify: `lib/features/settings/settings_notifier.dart`
- Create: `lib/features/chat/notifiers/create_pr_failure.dart`
- Modify: `lib/features/chat/notifiers/create_pr_actions.dart`
- Create: `test/features/onboarding/github_auth_notifier_test.dart`
- Create: `test/features/settings/settings_actions_test.dart`
- Create: `test/features/chat/notifiers/create_pr_actions_test.dart`

- [ ] **Step 1: Fix GitHubAuthNotifier.signOut — no rethrow**

In `lib/features/onboarding/notifiers/github_auth_notifier.dart`, replace `signOut`:

```dart
/// Clears account state optimistically. If the token delete fails,
/// logs and swallows — the UI already shows "signed out" and there is
/// no recovery action available to the user.
Future<void> signOut() async {
  state = const AsyncData(null);
  try {
    await ref.read(githubAuthServiceProvider).signOut();
  } catch (e, st) {
    dLog('[GitHubAuthNotifier] signOut cleanup failed: $e\n$st');
    // State already cleared — swallow so the widget sees clean state.
  }
}
```

- [ ] **Step 2: Write failing test for signOut**

Create `test/features/onboarding/github_auth_notifier_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:code_bench_app/features/onboarding/notifiers/github_auth_notifier.dart';
import 'package:code_bench_app/services/github/github_auth_service.dart';

class MockGitHubAuthService extends Mock implements GitHubAuthNotifierService {}

void main() {
  late MockGitHubAuthService mockAuth;

  setUp(() { mockAuth = MockGitHubAuthService(); });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      githubAuthServiceProvider.overrideWithValue(mockAuth),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('signOut sets state to AsyncData(null) even when service throws', () async {
    when(() => mockAuth.getStoredAccount()).thenAnswer((_) async => null);
    when(() => mockAuth.signOut()).thenThrow(Exception('storage locked'));

    final c = makeContainer();
    await c.read(gitHubAuthProvider.future);
    await c.read(gitHubAuthProvider.notifier).signOut();
    final state = c.read(gitHubAuthProvider);
    expect(state.hasError, isFalse);
    expect(state.value, isNull);
  });

  test('authenticate failure → AsyncError state', () async {
    when(() => mockAuth.getStoredAccount()).thenAnswer((_) async => null);
    when(() => mockAuth.authenticate()).thenThrow(Exception('oauth cancelled'));

    final c = makeContainer();
    await c.read(gitHubAuthProvider.future);
    await c.read(gitHubAuthProvider.notifier).authenticate();
    expect(c.read(gitHubAuthProvider).hasError, isTrue);
  });
}
```

- [ ] **Step 3: Create SettingsActionsFailure + update SettingsActions.testApiKey**

Create `lib/features/settings/settings_actions_failure.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_actions_failure.freezed.dart';

@freezed
sealed class SettingsActionsFailure with _$SettingsActionsFailure {
  const factory SettingsActionsFailure.storageFailed(String providerName) = _StorageFailed;
  const factory SettingsActionsFailure.unknown(Object error) = _Unknown;
}
```

In `lib/features/settings/settings_notifier.dart`, update `SettingsActions`:

```dart
// testApiKey: catch internally and return false — never throws
Future<bool> testApiKey(AIProvider provider, String key) async {
  try {
    return await ref.read(apiKeyTestServiceProvider).testKey(provider, key);
  } catch (e) {
    dLog('[SettingsActions] testApiKey(${provider.name}) failed: ${e.runtimeType}');
    return false;
  }
}

// saveApiKey: emit SettingsActionsFailure on error
Future<void> saveApiKey(String provider, String key) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    try {
      await ref.read(settingsServiceProvider).writeApiKey(provider, key);
    } catch (e, st) {
      Error.throwWithStackTrace(SettingsActionsFailure.storageFailed(provider), st);
    }
  });
}
```

Also make `SettingsActions` extend `AsyncNotifier<void>`:
```dart
@Riverpod(keepAlive: true)
class SettingsActions extends _$SettingsActions {
  @override
  FutureOr<void> build() {}
  // ... rest of methods
}
```

- [ ] **Step 4: Write failing SettingsActions tests**

Create `test/features/settings/settings_actions_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:code_bench_app/features/settings/settings_notifier.dart';
import 'package:code_bench_app/features/settings/settings_actions_failure.dart';
import 'package:code_bench_app/services/settings/settings_service.dart';
import 'package:code_bench_app/services/ai/api_key_test_service.dart';
import 'package:code_bench_app/data/models/ai_model.dart';

class MockSettingsService extends Mock implements SettingsService {}
class MockApiKeyTestService extends Mock implements ApiKeyTestService {}

void main() {
  late MockSettingsService mockSettings;
  late MockApiKeyTestService mockTest;

  setUp(() {
    mockSettings = MockSettingsService();
    mockTest = MockApiKeyTestService();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      settingsServiceProvider.overrideWithValue(mockSettings),
      apiKeyTestServiceProvider.overrideWithValue(mockTest),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('testApiKey', () {
    test('returns true on success', () async {
      when(() => mockTest.testKey(any(), any())).thenAnswer((_) async => true);
      final c = makeContainer();
      final result = await c.read(settingsActionsProvider.notifier).testApiKey(AIProvider.anthropic, 'key');
      expect(result, isTrue);
    });

    test('returns false on service exception — never throws', () async {
      when(() => mockTest.testKey(any(), any())).thenThrow(Exception('network error'));
      final c = makeContainer();
      final result = await c.read(settingsActionsProvider.notifier).testApiKey(AIProvider.anthropic, 'key');
      expect(result, isFalse);
    });
  });

  group('saveApiKey', () {
    test('happy path — state becomes AsyncData', () async {
      when(() => mockSettings.writeApiKey(any(), any())).thenAnswer((_) async {});
      final c = makeContainer();
      await c.read(settingsActionsProvider.notifier).saveApiKey('anthropic', 'sk-123');
      expect(c.read(settingsActionsProvider), isA<AsyncData<void>>());
    });

    test('storage failure → SettingsActionsFailure.storageFailed', () async {
      when(() => mockSettings.writeApiKey(any(), any())).thenThrow(Exception('keychain locked'));
      final c = makeContainer();
      await c.read(settingsActionsProvider.notifier).saveApiKey('anthropic', 'sk-123');
      final state = c.read(settingsActionsProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<_StorageFailed>());
      final failure = state.error as _StorageFailed;
      expect(failure.providerName, equals('anthropic'));
    });
  });
}
```

- [ ] **Step 5: Create CreatePrFailure + update CreatePrActions**

Create `lib/features/chat/notifiers/create_pr_failure.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_pr_failure.freezed.dart';

@freezed
sealed class CreatePrFailure with _$CreatePrFailure {
  const factory CreatePrFailure.notAuthenticated() = _NotAuthenticated;
  const factory CreatePrFailure.network(String message) = _Network;
  const factory CreatePrFailure.permissionDenied() = _PermissionDenied;
  const factory CreatePrFailure.unknown(Object error) = _Unknown;
}
```

Update `lib/features/chat/notifiers/create_pr_actions.dart` — convert `listBranches` and `createPullRequest` to `AsyncNotifier<void>` pattern. Since `listBranches` returns a value, keep it as a regular async method (not state-emitting) but wrap exceptions:

```dart
@Riverpod(keepAlive: true)
class CreatePrActions extends _$CreatePrActions {
  @override
  FutureOr<void> build() {}

  CreatePrFailure _asFailure(Object e) => switch (e) {
    AuthException() => const CreatePrFailure.notAuthenticated(),
    NetworkException(statusCode: 403) => const CreatePrFailure.permissionDenied(),
    NetworkException(:final message) => CreatePrFailure.network(message),
    _ => CreatePrFailure.unknown(e),
  };

  Future<bool> hasToken() async {
    final svc = await ref.read(githubApiServiceProvider.future);
    return svc != null;
  }

  /// Returns branches or emits AsyncError with CreatePrFailure.
  Future<List<String>?> listBranches(String owner, String repo) async {
    state = const AsyncLoading();
    List<String>? result;
    state = await AsyncValue.guard(() async {
      try {
        final svc = await ref.read(githubApiServiceProvider.future);
        if (svc == null) throw const AuthException('Not signed in to GitHub');
        result = await svc.listBranches(owner, repo);
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return result;
  }

  Future<String?> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    required bool draft,
  }) async {
    state = const AsyncLoading();
    String? url;
    state = await AsyncValue.guard(() async {
      try {
        final svc = await ref.read(githubApiServiceProvider.future);
        if (svc == null) throw const AuthException('Not signed in to GitHub');
        url = await svc.createPullRequest(
          owner: owner, repo: repo, title: title,
          body: body, head: head, base: base, draft: draft,
        );
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return url;
  }
}
```

- [ ] **Step 6: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Run all new tests**

```bash
flutter test test/features/onboarding/github_auth_notifier_test.dart test/features/settings/settings_actions_test.dart
```
Expected: all pass.

- [ ] **Step 8: Commit**

```bash
dart format lib/features/onboarding/notifiers/ lib/features/settings/ lib/features/chat/notifiers/
git add lib/features/onboarding/notifiers/ lib/features/settings/ lib/features/chat/notifiers/create_pr_actions.dart lib/features/chat/notifiers/create_pr_failure.dart lib/features/chat/notifiers/create_pr_failure.freezed.dart lib/features/chat/notifiers/create_pr_failure.g.dart
git add test/features/onboarding/ test/features/settings/
git commit -m "refactor(auth/settings/pr): AsyncNotifier<void> + failure unions for GitHubAuth, SettingsActions, CreatePrActions"
```

---

## Task 8: GitActions → AsyncNotifier<void> + GitActionsFailure

**Files:**
- Create: `lib/shell/notifiers/git_actions_failure.dart`
- Modify: `lib/shell/notifiers/git_actions.dart`
- Create: `test/shell/notifiers/git_actions_test.dart`

- [ ] **Step 1: Create GitActionsFailure**

Create `lib/shell/notifiers/git_actions_failure.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'git_actions_failure.freezed.dart';

@freezed
sealed class GitActionsFailure with _$GitActionsFailure {
  const factory GitActionsFailure.gitError(String message) = _GitError;
  const factory GitActionsFailure.noUpstream(String branch) = _NoUpstream;
  const factory GitActionsFailure.authFailed() = _AuthFailed;
  const factory GitActionsFailure.conflict() = _Conflict;
  /// git binary missing or working directory deleted.
  const factory GitActionsFailure.gitUnavailable() = _GitUnavailable;
  const factory GitActionsFailure.unknown(Object error) = _Unknown;
}
```

- [ ] **Step 2: Write failing tests**

Create `test/shell/notifiers/git_actions_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:code_bench_app/shell/notifiers/git_actions.dart';
import 'package:code_bench_app/shell/notifiers/git_actions_failure.dart';
import 'package:code_bench_app/services/git/git_service.dart';

class MockGitService extends Mock implements GitService {}

void main() {
  late MockGitService mockGit;

  setUp(() { mockGit = MockGitService(); });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      gitServiceProvider.overrideWithValue(mockGit),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('commit', () {
    test('happy path — state becomes AsyncData', () async {
      when(() => mockGit.commit(any())).thenAnswer((_) async => 'abc123');
      final c = makeContainer();
      await c.read(gitActionsProvider.notifier).commit('/path', 'feat: add thing');
      expect(c.read(gitActionsProvider), isA<AsyncData<void>>());
    });

    test('GitException → GitActionsFailure.gitError', () async {
      when(() => mockGit.commit(any())).thenThrow(GitException('nothing to commit'));
      final c = makeContainer();
      await c.read(gitActionsProvider.notifier).commit('/path', 'msg');
      expect(c.read(gitActionsProvider).error, isA<_GitError>());
    });
  });

  group('push', () {
    test('GitNoUpstreamException → GitActionsFailure.noUpstream', () async {
      when(() => mockGit.push()).thenThrow(const GitNoUpstreamException('main'));
      final c = makeContainer();
      await c.read(gitActionsProvider.notifier).push('/path');
      expect(c.read(gitActionsProvider).error, isA<_NoUpstream>());
    });

    test('GitAuthException → GitActionsFailure.authFailed', () async {
      when(() => mockGit.push()).thenThrow(GitAuthException('auth failed'));
      final c = makeContainer();
      await c.read(gitActionsProvider.notifier).push('/path');
      expect(c.read(gitActionsProvider).error, isA<_AuthFailed>());
    });
  });

  group('pull', () {
    test('GitConflictException → GitActionsFailure.conflict', () async {
      when(() => mockGit.pull()).thenThrow(GitConflictException('conflict'));
      final c = makeContainer();
      await c.read(gitActionsProvider.notifier).pull('/path');
      expect(c.read(gitActionsProvider).error, isA<_Conflict>());
    });
  });
}
```

- [ ] **Step 3: Run to verify tests fail**

```bash
flutter test test/shell/notifiers/git_actions_test.dart
```
Expected: FAIL.

- [ ] **Step 4: Update GitActions**

Replace `lib/shell/notifiers/git_actions.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../services/git/git_service.dart';
import 'git_actions_failure.dart';

part 'git_actions.g.dart';

@Riverpod(keepAlive: true)
class GitActions extends _$GitActions {
  @override
  FutureOr<void> build() {}

  GitService _git(String projectPath) => ref.read(gitServiceProvider(projectPath));

  GitActionsFailure _asFailure(Object e) => switch (e) {
    GitNoUpstreamException(:final branch) => GitActionsFailure.noUpstream(branch ?? ''),
    GitAuthException() => const GitActionsFailure.authFailed(),
    GitConflictException() => const GitActionsFailure.conflict(),
    GitException(:final message) => GitActionsFailure.gitError(message),
    ProcessException() || FileSystemException() => const GitActionsFailure.gitUnavailable(),
    _ => GitActionsFailure.unknown(e),
  };

  Future<String?> initGit(String projectPath) async {
    state = const AsyncLoading();
    String? result;
    state = await AsyncValue.guard(() async {
      try {
        await _git(projectPath).initGit();
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return result;
  }

  Future<String?> commit(String projectPath, String message) async {
    state = const AsyncLoading();
    String? sha;
    state = await AsyncValue.guard(() async {
      try {
        sha = await _git(projectPath).commit(message);
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return sha;
  }

  Future<String?> push(String projectPath) async {
    state = const AsyncLoading();
    String? branch;
    state = await AsyncValue.guard(() async {
      try {
        branch = await _git(projectPath).push();
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return branch;
  }

  Future<void> pushToRemote(String projectPath, String remote) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await _git(projectPath).pushToRemote(remote);
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<({List<String> pushed, List<String> failed})> pushAllRemotes(
    String projectPath, List<GitRemote> remotes,
  ) async {
    final pushed = <String>[];
    final failed = <String>[];
    for (final remote in remotes) {
      try {
        await _git(projectPath).pushToRemote(remote.name);
        pushed.add(remote.name);
      } on Exception catch (e) {
        dLog('[GitActions] pushToRemote(${remote.name}) failed: ${e.runtimeType}');
        failed.add(remote.name);
      }
    }
    return (pushed: pushed, failed: failed);
  }

  Future<int?> pull(String projectPath) async {
    state = const AsyncLoading();
    int? commits;
    state = await AsyncValue.guard(() async {
      try {
        commits = await _git(projectPath).pull();
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return commits;
  }

  Future<List<GitRemote>?> listRemotes(String projectPath) async {
    try {
      return await _git(projectPath).listRemotes();
    } catch (e) {
      dLog('[GitActions] listRemotes failed: ${e.runtimeType}');
      return null; // soft failure — widget falls back to single-remote path
    }
  }

  Future<String?> currentBranch(String projectPath) => _git(projectPath).currentBranch();
  Future<String?> getOriginUrl(String projectPath) => _git(projectPath).getOriginUrl();
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
flutter test test/shell/notifiers/git_actions_test.dart
```

- [ ] **Step 6: Run build_runner + commit**

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib/shell/notifiers/
git add lib/shell/notifiers/ test/shell/notifiers/
git commit -m "refactor(git): GitActions → AsyncNotifier<void> with GitActionsFailure union"
```

---

## Task 9: Migrate top_action_bar.dart

**Files:**
- Modify: `lib/shell/widgets/top_action_bar.dart`

- [ ] **Step 1: Replace firstWhere try/catch with firstWhereOrNull**

Find the two `try { return list.firstWhere(...) } catch (_) { return null/default; }` blocks (lines ~68 and ~80). Replace each with `collection`'s `firstWhereOrNull`:

```dart
// Before:
try { return list.firstWhere((s) => s.sessionId == sessionId).title; } catch (_) { return 'New Chat'; }
// After:
return list.firstWhereOrNull((s) => s.sessionId == sessionId)?.title ?? 'New Chat';

// Before:
try { return list.firstWhere((p) => p.id == projectId); } catch (_) { return null; }
// After:
return list.firstWhereOrNull((p) => p.id == projectId);
```

Ensure `import 'package:collection/collection.dart';` is present.

- [ ] **Step 2: Add ref.listen for GitActionsFailure in _CommitPushButton**

In `_CommitPushButtonState.initState`, add:

```dart
@override
void initState() {
  super.initState();
  unawaited(_loadRemotes());
}
```

Add a `ref.listen` in the `build` method of `_CommitPushButtonState`:

```dart
@override
Widget build(BuildContext context) {
  ref.listen(gitActionsProvider, (prev, next) {
    if (next is! AsyncError || !mounted) return;
    final failure = next.error;
    if (failure is! GitActionsFailure) return;
    final msg = switch (failure) {
      _NoUpstream(:final branch) => 'No upstream branch for $branch. Run `git push -u origin <branch>` in your terminal.',
      _AuthFailed() => 'Push failed — check your git credentials.',
      _Conflict() => 'Pull failed — merge conflict detected. Resolve conflicts in your editor.',
      _GitError(:final message) => message,
      _GitUnavailable() => 'git binary unavailable.',
      _Unknown() => 'Git operation failed.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  });
  // ... rest of build
}
```

- [ ] **Step 3: Remove try/catch from _loadRemotes**

Replace:
```dart
Future<void> _loadRemotes() async {
  List<GitRemote> remotes;
  try {
    remotes = await ref.read(gitActionsProvider.notifier).listRemotes(widget.project.path);
  } on Exception { return; }
  // ...
}
```
With:
```dart
Future<void> _loadRemotes() async {
  final remotes = await ref.read(gitActionsProvider.notifier).listRemotes(widget.project.path);
  if (remotes == null || !mounted) return; // listRemotes returns null on soft failure
  setState(() {
    _remotes = remotes;
    if (remotes.isNotEmpty && !remotes.any((r) => r.name == _selectedRemote)) {
      _selectedRemote = remotes.first.name;
    }
  });
}
```

- [ ] **Step 4: Remove try/catch from _runCommit**

Replace `_runCommit`:
```dart
Future<void> _runCommit(String message) async {
  final sha = await ref.read(gitActionsProvider.notifier).commit(widget.project.path, message);
  if (sha != null && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Committed — $sha')));
    ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.project.path);
  }
  // Errors handled by ref.listen in build().
}
```

- [ ] **Step 5: Remove try/catch from _doPush, keep finally for _pushing state**

Replace `_doPush`:
```dart
Future<void> _doPush() async {
  if (!_ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
  setState(() => _pushing = true);
  try {
    final git = ref.read(gitActionsProvider.notifier);
    final String target;
    if (_remotes.length <= 1) {
      final branch = await git.push(widget.project.path);
      target = 'origin/${branch ?? ''}';
    } else {
      await git.pushToRemote(widget.project.path, _selectedRemote);
      final branch = await git.currentBranch(widget.project.path);
      target = (branch == null || branch.isEmpty) ? _selectedRemote : '$_selectedRemote/$branch';
    }
    if (mounted && !ref.read(gitActionsProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pushed to $target')));
      ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.project.path);
    }
  } finally {
    if (mounted) setState(() => _pushing = false);
  }
}
```

- [ ] **Step 6: Remove try/catch from _doPull, keep finally**

Replace `_doPull`:
```dart
Future<void> _doPull() async {
  if (!_ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
  setState(() => _pulling = true);
  try {
    final n = await ref.read(gitActionsProvider.notifier).pull(widget.project.path);
    if (n != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pulled — $n new commit(s) from origin')));
      ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.project.path);
    }
    // Errors handled by ref.listen in build().
  } finally {
    if (mounted) setState(() => _pulling = false);
  }
}
```

- [ ] **Step 7: Remove try/catch from _InitGitButton**

In the `_InitGitButton.build` method, replace the `try { await gitActions.initGit() } on GitException` block:
```dart
onTap: () async {
  if (!_ensureProjectAvailable(context, ref, project.id, project.path)) return;
  await ref.read(gitActionsProvider.notifier).initGit(project.path);
  if (!context.mounted || ref.read(gitActionsProvider).hasError) return;
  ref.read(projectSidebarActionsProvider.notifier).refreshGitState(project.path);
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Git repository initialized')));
},
```

Note: `_InitGitButton` is a `ConsumerWidget`, not a `ConsumerStatefulWidget`. Add a `ref.listen` via a `Consumer` wrapper around the button, or convert to `ConsumerStatefulWidget` to use `ref.listen` in `didChangeDependencies`. The simplest approach: use `Consumer` wrapper inline.

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  return Consumer(
    builder: (context, ref, _) {
      ref.listen(gitActionsProvider, (prev, next) {
        if (next is! AsyncError || !context.mounted) return;
        final failure = next.error;
        if (failure is! GitActionsFailure) return;
        if (failure is _GitError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to initialize git: ${(failure as _GitError).message}')),
          );
        }
      });
      return _ActionButton( /* ... same as before ... */ );
    },
  );
}
```

- [ ] **Step 8: Remove try/catch from _doCommit AI message generation**

The `_doCommit` method has a `try { await aiSvc.sendMessage() } on NetworkException` block. This is an AI service call from within a widget — technically a layer violation. Scope note: refactoring the AI call into a notifier is out of scope for this migration. The NetworkException try/catch here is the narrowest possible — it swallows only provider-side failures for a non-critical feature (commit message generation). **Leave this try/catch in place** with a comment:

```dart
// ARCH-NOTE: This try/catch is a deliberate exception to the no-widget-catch rule.
// Swallows only NetworkException from the commit-message AI call, which is
// non-critical (we fall back to a default message). Moving the AI call into
// a notifier is tracked as a follow-up.
try {
  final response = await aiSvc.sendMessage(...);
  // ...
} on NetworkException {
  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('AI commit message unavailable — using default.')));
}
```

- [ ] **Step 9: Run flutter analyze**

```bash
flutter analyze lib/shell/widgets/top_action_bar.dart
```
Expected: no issues.

- [ ] **Step 10: Commit**

```bash
dart format lib/shell/widgets/top_action_bar.dart
git add lib/shell/widgets/top_action_bar.dart
git commit -m "refactor(top-bar): replace try/catch with ref.listen on GitActionsFailure"
```

---

## Task 10: Migrate message_bubble.dart

**Files:**
- Modify: `lib/features/chat/widgets/message_bubble.dart`

- [ ] **Step 1: Replace _loadDiff with codeDiffProvider watch**

In `_CodeBlockCardState`, remove the `_diffState`, `_originalContent`, `_diffs`, `_diffError` fields and the `_loadDiff()` method. Add:

```dart
// In build(), watch the diff provider:
final absolutePath = project != null ? p.join(project.path, filename ?? '') : null;
final diffAsync = absolutePath != null
    ? ref.watch(codeDiffProvider(
        absolutePath: absolutePath,
        projectPath: project!.path,
        newContent: widget.code,
      ))
    : null;
```

Update the diff-card rendering to use `diffAsync.when(loading: ..., error: ..., data: ...)` instead of switching on `_diffState`.

- [ ] **Step 2: Replace _applyChange try/catch with ref.listen**

Remove the try/catch from `_applyChange`. Add a `ref.listen` in the `ConsumerStatefulWidget`'s `didChangeDependencies` or at the top of `build`:

```dart
ref.listen(codeApplyActionsProvider, (prev, next) {
  if (next is! AsyncError || !mounted) return;
  final failure = next.error;
  if (failure is! CodeApplyFailure) return;
  final msg = switch (failure) {
    _ProjectMissing() => 'Project folder is missing. Right-click the project in the sidebar to Relocate or Remove it.',
    _OutsideProject() => 'This file is outside the current project.',
    _DiskWrite(:final message) => 'Could not write file: $message',
    _FileRead(:final path) => 'Could not read file: $path',
    _Unknown() => 'Unable to apply change.',
  };
  showErrorSnackBar(context, msg);
});
```

Update `_applyChange` to remove try/catch:

```dart
Future<void> _applyChange() async {
  final project = _resolveActiveProject();
  if (project == null) { showErrorSnackBar(context, 'No active project.'); return; }
  final filename = _effectiveFilename;
  if (filename == null) { showErrorSnackBar(context, 'No filename set for this code block.'); return; }

  setState(() => _applying = true);
  final absolutePath = p.join(project.path, filename);
  await ref.read(codeApplyActionsProvider.notifier).applyChange(
    projectId: project.id, filePath: absolutePath,
    projectPath: project.path, newContent: widget.code,
    sessionId: widget.sessionId, messageId: widget.messageId,
  );
  if (!mounted) return;
  if (!ref.read(codeApplyActionsProvider).hasError) {
    ref.read(changesPanelVisibleProvider.notifier).show();
    setState(() => _diffState = _DiffCardState.hidden);
  }
  setState(() => _applying = false);
}
```

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze lib/features/chat/widgets/message_bubble.dart
```

- [ ] **Step 4: Commit**

```bash
dart format lib/features/chat/widgets/message_bubble.dart
git add lib/features/chat/widgets/message_bubble.dart
git commit -m "refactor(message-bubble): replace try/catch with ref.listen on CodeApplyFailure + codeDiffProvider"
```

---

## Task 11: Migrate changes_panel.dart + pr_card.dart

**Files:**
- Modify: `lib/features/chat/widgets/changes_panel.dart`
- Modify: `lib/features/chat/widgets/pr_card.dart`

- [ ] **Step 1: Update changes_panel.dart**

In `_ChangeEntryState._handleRevert`:

1. Remove `File(widget.change.filePath).readAsString()` call. Replace with `ref.read(codeApplyActionsProvider.notifier).readFileContent(path)`:

```dart
Future<void> _handleRevert() async {
  final isEdited = await _editedFuture;
  if (!mounted) return;

  if (!isEdited) {
    await widget.onRevert();
    // Errors from revert are handled by the caller's ref.listen.
    return;
  }

  String currentContent;
  try {
    currentContent = await ref.read(codeApplyActionsProvider.notifier).readFileContent(widget.change.filePath);
  } on CodeApplyFailure {
    currentContent = '(file unreadable)';
  }
  if (!mounted) return;
  // ... rest of dialog show, unchanged
}
```

2. Remove the inner try/catch around `widget.onRevert()` calls. The `onRevert` callback calls `CodeApplyActions.revertChange`, which now emits `AsyncError` — the parent widget must have a `ref.listen` for it.

3. In `ChangesPanel.build`, add `ref.listen`:
```dart
ref.listen(codeApplyActionsProvider, (prev, next) {
  if (next is! AsyncError || !context.mounted) return;
  final failure = next.error;
  if (failure is! CodeApplyFailure) return;
  showErrorSnackBar(context, switch (failure) {
    _ProjectMissing() => 'Project is missing.',
    _OutsideProject() => 'File is outside the project.',
    _DiskWrite(:final message) => 'Write failed: $message',
    _FileRead() => 'Could not read file.',
    _Unknown() => 'Revert failed. Please try again.',
  });
});
```

- [ ] **Step 2: Update pr_card.dart**

`PrCardNotifier.approve()` and `merge()` now set `state.value!.actionError` instead of rethrowing. Update `_PRCardState`:

1. Remove `_approve` and `_merge` try/catch. They no longer throw:

```dart
Future<void> _approve() async {
  final confirmed = await _confirm(title: 'Approve pull request?', body: '...', actionLabel: 'Approve');
  if (confirmed != true) return;
  await ref.read(_provider.notifier).approve();
  // Success/failure both reflected in prCardProvider state.
  if (mounted && !ref.read(_provider).value!.approved) return; // error shown via actionError banner
  if (mounted) _showSnack('Approved');
}

Future<void> _merge() async {
  final confirmed = await _confirm(title: 'Merge pull request?', body: '...', actionLabel: 'Merge', destructive: true);
  if (confirmed != true) return;
  await ref.read(_provider.notifier).merge();
  if (mounted && ref.read(_provider).value?.actionError == null) {
    _showSnack('Merged');
    _pollTimer?.cancel();
  }
}
```

2. In `_buildCard`, add an `actionError` banner below the existing `pollError` banner:

```dart
if (s.actionError != null) ...[
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: ThemeConstants.error.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: ThemeConstants.error.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, size: 11, color: ThemeConstants.error),
        const SizedBox(width: 6),
        Expanded(child: Text(s.actionError!, style: const TextStyle(color: ThemeConstants.error, fontSize: 10))),
      ],
    ),
  ),
  const SizedBox(height: 8),
],
```

3. Keep the `_openOnGitHub` try/catch around `launchUrl` — this is the allowed carve-out.

4. Remove the `_friendlyError` method from `_PRCardState` (it's now only in `PrCardNotifier`).

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze lib/features/chat/widgets/changes_panel.dart lib/features/chat/widgets/pr_card.dart
```

- [ ] **Step 4: Commit**

```bash
dart format lib/features/chat/widgets/changes_panel.dart lib/features/chat/widgets/pr_card.dart
git add lib/features/chat/widgets/changes_panel.dart lib/features/chat/widgets/pr_card.dart
git commit -m "refactor(changes/pr): replace widget try/catch with ref.listen + actionError state"
```

---

## Task 12: Migrate branch_picker_popover.dart

**Files:**
- Modify: `lib/features/branch_picker/widgets/branch_picker_popover.dart`

- [ ] **Step 1: Rewrite to use AsyncNotifier state**

`BranchPickerNotifier` is now an `AsyncNotifier<BranchPickerState>`. The popover now watches its provider instead of maintaining `_branches`, `_worktreeBranches`, `_loading`, `_loadError` local state.

Key changes:

1. Remove `_branches`, `_worktreeBranches`, `_loading`, `_loadError` fields and `_load()` method.

2. In `initState`, remove `_load()` call — the provider loads automatically on first watch.

3. Add `ref.listen` in `build` for `BranchPickerFailure`:

```dart
ref.listen(branchPickerProvider(widget.projectPath), (prev, next) {
  if (next is! AsyncError || !mounted) return;
  final failure = next.error;
  if (failure is! BranchPickerFailure) return;
  switch (failure) {
    case _InvalidName(:final reason):
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
    case _CheckoutConflict(:final message):
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 4)));
      // Reload after conflict so branch list reflects current state.
      ref.invalidate(branchPickerProvider(widget.projectPath)); // allowed: notifier method
      // Actually route through a notifier refresh — call build() to reload:
      ref.read(branchPickerProvider(widget.projectPath).notifier); // triggers rebuild
    case _CreateFailed(:final message):
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $message')));
    case _GitUnavailable():
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read branches — is git installed and the folder available?')));
    case _Unknown():
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branch operation failed.')));
  }
});
```

4. Replace the branch-list rendering with:

```dart
final branchAsync = ref.watch(branchPickerProvider(widget.projectPath));

return branchAsync.when(
  loading: () => const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))),
  error: (e, _) => const Center(child: Text('Could not load branches.', style: TextStyle(fontSize: 11))),
  data: (state) => _buildBranchList(state.branches, state.worktreeBranches),
);
```

5. Update `_checkout` and `_createBranch` to just call the notifier without try/catch:

```dart
Future<void> _checkout(String branch) async {
  await ref.read(branchPickerProvider(widget.projectPath).notifier).checkout(branch);
  if (!mounted || ref.read(branchPickerProvider(widget.projectPath)).hasError) return;
  ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.projectPath);
  widget.onClose();
}

Future<void> _createBranch() async {
  final name = _createController.text.trim();
  await ref.read(branchPickerProvider(widget.projectPath).notifier).createBranch(name);
  if (!mounted || ref.read(branchPickerProvider(widget.projectPath)).hasError) return;
  ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.projectPath);
  widget.onClose();
}
```

Note: `ref.invalidate` in the error listener above is the one case CLAUDE.md exempts — it's re-triggering `build()` on a family provider to reload data after a transient error, not a business-logic mutation. Document with a comment.

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze lib/features/branch_picker/widgets/branch_picker_popover.dart
```

- [ ] **Step 3: Commit**

```bash
dart format lib/features/branch_picker/widgets/branch_picker_popover.dart
git add lib/features/branch_picker/widgets/branch_picker_popover.dart
git commit -m "refactor(branch-picker): popover drives from AsyncNotifier state, no try/catch"
```

---

## Task 13: Migrate onboarding widgets

**Files:**
- Modify: `lib/features/onboarding/widgets/github_step.dart`
- Modify: `lib/features/onboarding/widgets/api_keys_step.dart`
- Modify: `lib/features/onboarding/widgets/add_project_step.dart`

- [ ] **Step 1: github_step.dart — remove redundant try/catch**

`authenticate()` and `signInWithPat()` already use `AsyncValue.guard` and emit `AsyncError`. The `_connectOAuth` and `_testPat` try/catch blocks in the widget are therefore redundant.

Replace `_connectOAuth`:
```dart
Future<void> _connectOAuth() async {
  await ref.read(gitHubAuthProvider.notifier).authenticate();
  // Error state reflected in authAsync; build() switch handles it.
}
```

Replace `_testPat`:
```dart
Future<void> _testPat() async {
  final token = _patController.text.trim();
  if (token.isEmpty) return;
  setState(() => _patValid = null);
  await ref.read(gitHubAuthProvider.notifier).signInWithPat(token);
  if (!mounted) return;
  final authAsync = ref.read(gitHubAuthProvider);
  setState(() => _patValid = authAsync.hasError ? false : authAsync.value != null);
}
```

Replace `_disconnect` try/catch:
```dart
Future<void> _disconnect() async {
  await ref.read(gitHubAuthProvider.notifier).signOut();
  // signOut no longer rethrows — always succeeds from widget's perspective.
}
```

Remove the `isLoading` spinner driven by `authAsync` — it already uses `AsyncLoading()` naturally.

- [ ] **Step 2: api_keys_step.dart — remove try/catch, drive from notifier state**

`_testConnection`: remove try/catch. `testApiKey` now returns false on error, never throws:

```dart
Future<void> _testConnection(AIProvider provider) async {
  final key = _controllers[provider]!.text.trim();
  if (key.isEmpty) return;
  setState(() => _testing[provider] = true);
  final success = await ref.read(settingsActionsProvider.notifier).testApiKey(provider, key);
  if (!mounted) return;
  setState(() {
    _testResults[provider] = success;
    _testing[provider] = false;
  });
}
```

`_saveAll`: remove try/catch. Add `ref.listen` for `SettingsActionsFailure`:

In `build()`, add before the return:
```dart
ref.listen(settingsActionsProvider, (prev, next) {
  if (next is! AsyncError || !mounted) return;
  final failure = next.error;
  if (failure is! SettingsActionsFailure) return;
  switch (failure) {
    case _StorageFailed(:final providerName):
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save $providerName API key — please try again')));
    case _Unknown():
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save API key — please try again')));
  }
});
```

Replace `_saveAll`:
```dart
Future<void> _saveAll() async {
  setState(() => _saving = true);
  final actions = ref.read(settingsActionsProvider.notifier);
  for (final entry in _controllers.entries) {
    final key = entry.value.text.trim();
    if (key.isEmpty) continue;
    await actions.saveApiKey(entry.key.name, key);
    if (ref.read(settingsActionsProvider).hasError) {
      if (mounted) setState(() => _saving = false);
      return; // error shown by ref.listen
    }
  }
  if (!mounted) return;
  setState(() => _saving = false);
  widget.onContinue();
}
```

Remove `bool _saving` driving the spinner — replace with `ref.watch(settingsActionsProvider).isLoading`:
```dart
final isSaving = ref.watch(settingsActionsProvider).isLoading;
// Use isSaving instead of _saving for button disabled state and spinner.
```

(Remove the `_saving` field entirely.)

- [ ] **Step 3: add_project_step.dart — _addProject → ref.listen**

Add `ref.listen` in `build()`:
```dart
ref.listen(projectSidebarActionsProvider, (prev, next) {
  if (next is! AsyncError || !mounted) return;
  final failure = next.error;
  if (failure is! ProjectSidebarFailure) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(switch (failure) {
    _DuplicatePath() => 'This folder is already added as a project.',
    _InvalidPath(:final reason) => reason,
    _StorageError(:final message) => 'Failed to add project: $message',
    _Unknown() => 'Failed to add project.',
  })));
});
```

Replace `_addProject`:
```dart
Future<void> _addProject() async {
  if (_selectedPath == null) return;
  await ref.read(projectSidebarActionsProvider.notifier).addExistingFolder(_selectedPath!);
  if (!mounted || ref.read(projectSidebarActionsProvider).hasError) return;
  widget.onComplete();
}
```

Remove `bool _adding` field — replace with `ref.watch(projectSidebarActionsProvider).isLoading`.

- [ ] **Step 4: Run flutter analyze**

```bash
flutter analyze lib/features/onboarding/widgets/
```

- [ ] **Step 5: Commit**

```bash
dart format lib/features/onboarding/widgets/
git add lib/features/onboarding/widgets/
git commit -m "refactor(onboarding): replace widget try/catch with ref.listen + notifier AsyncValue"
```

---

## Task 14: Migrate sidebar dialogs + chat widgets

**Files:**
- Modify: `lib/features/project_sidebar/widgets/remove_project_dialog.dart`
- Modify: `lib/features/project_sidebar/widgets/relocate_project_dialog.dart`
- Modify: `lib/features/chat/widgets/chat_input_bar.dart`
- Modify: `lib/features/chat/widgets/message_list.dart`

- [ ] **Step 1: remove_project_dialog.dart**

`_loadSessionCount` wraps `getSessionsByProject`. This call doesn't need an AsyncValue slot — it's a one-shot init query. Since `getSessionsByProject` no longer rethrows (it's on `ProjectSidebarActions` which now emits `AsyncError`), the catch can be removed. The catch's job was just to ensure the dialog stayed usable — that still works because `getSessionsByProject` on `ProjectSidebarActions` now swallows errors into state:

```dart
Future<void> _loadSessionCount() async {
  final sessions = await ref.read(projectSidebarActionsProvider.notifier).getSessionsByProject(widget.project.id);
  if (!mounted) return;
  // If sessions is null/empty due to error, the checkbox just won't show — safe.
  setState(() {
    _sessionCount = sessions?.length ?? 0;
    _sessionCountLoaded = true;
  });
}
```

Note: update `getSessionsByProject` on `ProjectSidebarActions` to return `Future<List<ChatSession>?>` (nullable, null on error) instead of rethrowing.

Add `ref.listen` in `build()`:
```dart
ref.listen(projectSidebarActionsProvider, (prev, next) {
  if (next is! AsyncError || !mounted) return;
  final failure = next.error;
  if (failure is! ProjectSidebarFailure) return;
  setState(() => _submitting = false);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(switch (failure) {
    _DuplicatePath() => 'Duplicate project path.',
    _InvalidPath(:final reason) => reason,
    _StorageError(:final message) => 'Failed to remove project: $message',
    _Unknown() => 'Failed to remove project.',
  })));
});
```

Replace `_submit`:
```dart
Future<void> _submit() async {
  setState(() => _submitting = true);
  await ref.read(projectSidebarActionsProvider.notifier)
      .removeProject(widget.project.id, deleteSessions: _alsoDeleteSessions);
  if (!mounted) return;
  if (!ref.read(projectSidebarActionsProvider).hasError) {
    Navigator.of(context).pop(true);
  }
  // Errors shown by ref.listen; _submitting reset there too.
}
```

- [ ] **Step 2: relocate_project_dialog.dart**

Add `ref.listen` for `ProjectSidebarFailure` in `build()`. The widget currently builds a `String? _error` for inline display — keep this pattern but drive it from the failure:

```dart
ref.listen(projectSidebarActionsProvider, (prev, next) {
  if (next is! AsyncError || !mounted) return;
  final failure = next.error;
  if (failure is! ProjectSidebarFailure) return;
  setState(() {
    _submitting = false;
    _error = switch (failure) {
      _InvalidPath(:final reason) => reason,
      _DuplicatePath() => 'A project at that path already exists.',
      _StorageError(:final message) => 'Could not relocate: $message',
      _Unknown() => 'Could not relocate project. Please try again.',
    };
  });
});
```

Replace `_submit`:
```dart
Future<void> _submit() async {
  if (_newPath == null) return;
  setState(() { _submitting = true; _error = null; });
  await ref.read(projectSidebarActionsProvider.notifier).relocateProject(widget.project.id, _newPath!);
  if (!mounted) return;
  if (!ref.read(projectSidebarActionsProvider).hasError) {
    Navigator.of(context).pop(true);
  }
  // Error handled by ref.listen above.
}
```

Also remove the `import '../../services/project/project_service.dart' show DuplicateProjectPathException` line — widgets no longer need service exception types.

- [ ] **Step 3: chat_input_bar.dart**

Remove the `catch(e)` block from `_sendMessage`. Keep the `try/finally` for the `_isSending` state reset:

```dart
Future<void> _sendMessage() async {
  final text = _controller.text.trim();
  if (text.isEmpty) return;
  _controller.clear();
  _sessionDrafts.remove(widget.sessionId);
  setState(() => _isSending = true);
  try {
    final systemPrompt = ref.read(sessionSystemPromptProvider)[widget.sessionId];
    await ref.read(chatMessagesProvider(widget.sessionId).notifier)
        .sendMessage(text, systemPrompt: (systemPrompt?.isNotEmpty ?? false) ? systemPrompt : null);
  } finally {
    if (mounted) {
      setState(() => _isSending = false);
      _focusNode.requestFocus();
    }
  }
}
```

Add `ref.listen` for `chatMessagesProvider` errors in `build()`:
```dart
ref.listen(chatMessagesProvider(widget.sessionId), (prev, next) {
  if (next is! AsyncError || !mounted) return;
  showErrorSnackBar(context, 'Failed to send message. Please try again.');
});
```

- [ ] **Step 4: message_list.dart**

The single try/catch in `_loadMore` is around `loadMore()`. `ChatMessagesNotifier.loadMore` doesn't set `AsyncError` on failure currently — it's a best-effort pagination call. Remove the empty catch and add a comment:

```dart
Future<void> _loadMore(List<ChatMessage> messages) async {
  if (_loadingMore || !_hasMore) return;
  setState(() => _loadingMore = true);
  final offset = messages.length;
  await ref.read(chatMessagesProvider(widget.sessionId).notifier).loadMore(widget.sessionId, offset);
  if (!mounted) return;
  final updated = ref.read(chatMessagesProvider(widget.sessionId)).value;
  if (updated != null && updated.length - messages.length < _pageSize) {
    setState(() => _hasMore = false);
  }
  setState(() => _loadingMore = false);
  // loadMore errors are reflected in chatMessagesProvider AsyncError state,
  // handled by the session-level error display in MessageList.build.
}
```

- [ ] **Step 5: Run flutter analyze**

```bash
flutter analyze lib/features/project_sidebar/widgets/ lib/features/chat/widgets/chat_input_bar.dart lib/features/chat/widgets/message_list.dart
```

- [ ] **Step 6: Commit**

```bash
dart format lib/features/project_sidebar/widgets/ lib/features/chat/widgets/chat_input_bar.dart lib/features/chat/widgets/message_list.dart
git add lib/features/project_sidebar/widgets/ lib/features/chat/widgets/chat_input_bar.dart lib/features/chat/widgets/message_list.dart
git commit -m "refactor(dialogs/chat): replace widget try/catch with ref.listen for sidebar dialogs and chat widgets"
```

---

## Task 15: Run full test suite + build_runner

- [ ] **Step 1: Run build_runner for all generated files**

```bash
cd .worktrees/tech/2026-04-12-widget-notifier-service-arch
dart run build_runner build --delete-conflicting-outputs
```
Expected: completes with no errors.

- [ ] **Step 2: Format all changed files**

```bash
dart format lib/ test/
```

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze
```
Expected: no issues.

- [ ] **Step 4: Run full test suite**

```bash
flutter test
```
Expected: all tests pass.

- [ ] **Step 5: Commit generated files**

```bash
git add lib/ test/
git commit -m "chore: run build_runner and dart format after architecture migration"
```

---

## Task 16: Update README + final commit

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add Layered architecture subsection to README**

In `README.md`, find the existing `## Architecture` → `### State management` section. Add a new subsection *before* it:

```markdown
### Layered architecture

Code Bench enforces a strict one-way dependency graph:

```
Widgets / Screens
      ↓  (ref.watch / ref.read notifier)
  Notifiers   ← the only layer widgets may reach
      ↓  (ref.read service)
  Services    ← Dio, SQLite, Process.run, filesystem
```

**Widgets** are pure state-renderers. They call notifier methods and listen for `AsyncError` state to show snackbars — they never try/catch business-logic calls or import service exception types.

**Notifiers** mediate all commands. `*Actions` notifiers extend `AsyncNotifier<void>`; failures are emitted as `AsyncError` carrying a typed `sealed class {Notifier}Failure`. `*Notifier` classes own reactive `AsyncValue<T>` data state.

**Services** own all I/O: Dio calls, SQLite queries, `Process.run`, `File` reads. They are instantiated via `@riverpod` / `@Riverpod(keepAlive: true)` providers and never constructed directly in widgets or notifiers.

The full rules — naming conventions, error-handling patterns, logging matrix, security guards — are in [`CLAUDE.md`](CLAUDE.md).
```

- [ ] **Step 2: Run flutter analyze one final time**

```bash
flutter analyze
```
Expected: no issues.

- [ ] **Step 3: Final commit**

```bash
dart format README.md
git add README.md
git commit -m "docs(readme): add layered architecture overview with dependency graph"
```

---

## Follow-ups (post-merge, not part of this PR)

- **Revisit `CodeApplyActions` for `family` escalation** if a "Apply all files" bulk feature is shipped — the single `AsyncValue<void>` slot means only the last file's error is visible. Escalate to `family` keyed by `(sessionId, messageId, filePath)`.
- **Revisit `ProjectFileScanActions`** if parallel project scans are introduced.
- **Move AI commit-message call** from `top_action_bar.dart._doCommit` into a dedicated `CommitMessageActions` notifier to eliminate the one remaining allowed-by-exception try/catch.
