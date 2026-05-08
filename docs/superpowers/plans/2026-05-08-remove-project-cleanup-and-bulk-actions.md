# Remove-project cleanup & per-project bulk actions — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove a project completely (incl. archived sessions), reset the chat view when the active project is removed, and add per-project bulk archive/delete actions to the sidebar.

**Architecture:** Bottom-up plumbing of a new `deleteSessionsByProject(projectId)` method through Datasource → Repository → Service → Notifier (Drift transaction at the bottom). Two new bulk Action methods built on the existing `getSessionsByProject` (active-only). Two new confirmation dialogs follow the existing `RemoveProjectDialog` shape. Existing failure type and error-flow are sufficient — no new variants.

**Tech Stack:** Flutter, Riverpod (`@riverpod` codegen), Drift (SQLite), Freezed sealed unions, GoRouter.

**Spec:** [docs/superpowers/specs/2026-05-08-remove-project-cleanup-and-bulk-actions-design.md](../specs/2026-05-08-remove-project-cleanup-and-bulk-actions-design.md)

---

## File Structure

**New files:**

- `lib/features/project_sidebar/widgets/archive_all_conversations_dialog.dart` — confirm dialog for "Archive all conversations" per project.
- `lib/features/project_sidebar/widgets/delete_all_conversations_dialog.dart` — destructive confirm dialog for "Delete all conversations" per project.

**Modified files (top→bottom of the dependency rule):**

- `lib/data/_core/app_database.dart` — `SessionDao.deleteSessionsByProject(...)`.
- `lib/data/session/datasource/session_datasource.dart` — interface method.
- `lib/data/session/datasource/session_datasource_drift.dart` — drift impl.
- `lib/data/session/repository/session_repository.dart` — interface method.
- `lib/data/session/repository/session_repository_impl.dart` — passthrough.
- `lib/services/session/session_service.dart` — passthrough.
- `lib/features/project_sidebar/notifiers/project_sidebar_actions.dart` — `removeProject` cleanup, two new bulk methods.
- `lib/features/project_sidebar/widgets/remove_project_dialog.dart` — navigate to `/chat` after success.
- `lib/features/project_sidebar/widgets/project_context_menu.dart` — two new menu items + plumbing.
- `lib/features/project_sidebar/widgets/project_tile.dart` — propagate new callbacks.
- `lib/features/project_sidebar/project_sidebar.dart` — wire new dialogs.
- `test/features/project_sidebar/project_sidebar_actions_test.dart` — coverage for active-state reset + bulk methods.

---

## Task 0: Create worktree

**Files:** none (workspace setup).

- [ ] **Step 1: Create the feature worktree**

Run from the repo root:

```bash
git worktree add .worktrees/feat/2026-05-08-remove-project-cleanup-and-bulk-actions \
  -b feat/2026-05-08-remove-project-cleanup-and-bulk-actions
cd .worktrees/feat/2026-05-08-remove-project-cleanup-and-bulk-actions
```

All subsequent task commands run from inside that worktree directory.

- [ ] **Step 2: Verify worktree set up**

Run: `git worktree list`
Expected: shows `.worktrees/feat/2026-05-08-remove-project-cleanup-and-bulk-actions` on branch `feat/2026-05-08-remove-project-cleanup-and-bulk-actions`.

---

## Task 1: Add `deleteSessionsByProject` through the data stack

**Files:**
- Modify: `lib/data/_core/app_database.dart` (`SessionDao` class, add method)
- Modify: `lib/data/session/datasource/session_datasource.dart` (add interface method)
- Modify: `lib/data/session/datasource/session_datasource_drift.dart` (impl)
- Modify: `lib/data/session/repository/session_repository.dart` (add interface method)
- Modify: `lib/data/session/repository/session_repository_impl.dart` (impl passthrough)
- Modify: `lib/services/session/session_service.dart` (impl passthrough)

No new tests in this task — coverage lives at the notifier layer (Task 3) where the existing fake-based tests exercise the full path. The DAO method is a small, mechanical drift query; touching it with a unit test would require setting up an in-memory database when no other DAO tests exist in the repo (YAGNI).

- [ ] **Step 1: Add DAO method**

In `lib/data/_core/app_database.dart`, inside the `SessionDao` class (after `deleteAllSessionsAndMessages`, around line 149), add:

```dart
/// Deletes every session belonging to [projectId] (archived AND active) and
/// their messages, in a single transaction so a mid-call failure leaves no
/// orphans. Used by `removeProject` to fully clean up before the project row
/// itself is dropped.
Future<void> deleteSessionsByProject(String projectId) async {
  await transaction(() async {
    final ids = await ((select(chatSessions)..where((t) => t.projectId.equals(projectId))).map((row) => row.sessionId))
        .get();
    if (ids.isEmpty) return;
    await (delete(chatMessages)..where((t) => t.sessionId.isIn(ids))).go();
    await (delete(chatSessions)..where((t) => t.projectId.equals(projectId))).go();
  });
}
```

- [ ] **Step 2: Add to datasource interface**

In `lib/data/session/datasource/session_datasource.dart`, after `deleteAllSessionsAndMessages()` (line 22), add:

```dart
Future<void> deleteSessionsByProject(String projectId);
```

- [ ] **Step 3: Implement on drift datasource**

In `lib/data/session/datasource/session_datasource_drift.dart`, after `deleteAllSessionsAndMessages` (line 115), add:

```dart
@override
Future<void> deleteSessionsByProject(String projectId) => _db.sessionDao.deleteSessionsByProject(projectId);
```

- [ ] **Step 4: Add to repository interface**

In `lib/data/session/repository/session_repository.dart`, after the `getSessionsByProject` declaration at line 30, add:

```dart
/// Deletes every session for [projectId] — archived AND active — and their
/// messages in one transaction. Used during project removal.
Future<void> deleteSessionsByProject(String projectId);
```

- [ ] **Step 5: Implement on repository**

In `lib/data/session/repository/session_repository_impl.dart`, after `getSessionsByProject` (line 84), add:

```dart
@override
Future<void> deleteSessionsByProject(String projectId) => _ds.deleteSessionsByProject(projectId);
```

- [ ] **Step 6: Expose on service**

In `lib/services/session/session_service.dart`, after `getSessionsByProject` (line 103), add:

```dart
Future<void> deleteSessionsByProject(String projectId) => _session.deleteSessionsByProject(projectId);
```

- [ ] **Step 7: Format and analyze**

Run:
```bash
dart format lib/
flutter analyze
```
Expected: 0 issues.

- [ ] **Step 8: Commit**

```bash
git add lib/data/_core/app_database.dart \
        lib/data/session/datasource/session_datasource.dart \
        lib/data/session/datasource/session_datasource_drift.dart \
        lib/data/session/repository/session_repository.dart \
        lib/data/session/repository/session_repository_impl.dart \
        lib/services/session/session_service.dart
git commit -m "feat(session): add deleteSessionsByProject for full cleanup"
```

---

## Task 2: Update `removeProject` to use the new method and reset active state

**Files:**
- Modify: `lib/features/project_sidebar/notifiers/project_sidebar_actions.dart`

- [ ] **Step 1: Replace the loop and add active-state reset**

In `lib/features/project_sidebar/notifiers/project_sidebar_actions.dart`, replace the `removeProject` method (currently lines 105–124) with:

```dart
/// Removes the project from Code Bench. If [deleteSessions] is true, all
/// sessions linked to the project (archived AND active) are deleted first.
/// When the active project is being removed, also clears the active session
/// and project ids so the chat view falls back to its empty state.
Future<void> removeProject(String id, {bool deleteSessions = false}) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    try {
      if (deleteSessions) {
        await (await _sessions).deleteSessionsByProject(id);
      }
      await _projects.removeProject(id);
      if (ref.read(activeProjectIdProvider) == id) {
        ref.read(activeSessionIdProvider.notifier).set(null);
        ref.read(activeProjectIdProvider.notifier).set(null);
      }
    } catch (e, st) {
      dLog('[ProjectSidebarActions] removeProject failed: $e');
      Error.throwWithStackTrace(_asFailure(e), st);
    }
  });
}
```

The doc comment is updated to reflect the new "archived AND active" scope and the active-state reset behaviour.

- [ ] **Step 2: Format and analyze**

```bash
dart format lib/
flutter analyze
```
Expected: 0 issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/project_sidebar/notifiers/project_sidebar_actions.dart
git commit -m "fix(sidebar): wipe archived sessions and reset active state on remove"
```

---

## Task 3: Add active-state-reset coverage to the sidebar actions test

**Files:**
- Modify: `test/features/project_sidebar/project_sidebar_actions_test.dart`

Add tests around `removeProject`'s new behaviour: clears active session+project when the removed project is active, and leaves them alone otherwise. The fake `_FakeSessionService` is updated to record `deleteSessionsByProject` calls so the test verifies the deletion path is taken when `deleteSessions: true`.

- [ ] **Step 1: Extend `_FakeSessionService`**

In `test/features/project_sidebar/project_sidebar_actions_test.dart`, replace the `_FakeSessionService` class (lines 13–22) with:

```dart
class _FakeSessionService extends Fake implements SessionService {
  final List<String> deleteSessionsByProjectCalls = [];

  @override
  Future<String> createSession({required AIModel model, String? title, String? projectId}) async => 'fake-session';

  @override
  Future<List<ChatSession>> getSessionsByProject(String projectId) async => const [];

  @override
  Future<void> deleteSession(String sessionId) async {}

  @override
  Future<void> archiveSession(String sessionId) async {}

  @override
  Future<void> deleteSessionsByProject(String projectId) async {
    deleteSessionsByProjectCalls.add(projectId);
  }
}
```

- [ ] **Step 2: Plumb the fake-session-service instance into the container**

Replace the `_makeContainer` helper (lines 64–73) with one that returns both the container and the fake session service so tests can inspect calls:

```dart
({ProviderContainer container, _FakeSessionService sessions}) _makeContainer(_FakeProjectService fakeService) {
  final fakeSessions = _FakeSessionService();
  final c = ProviderContainer(
    overrides: [
      projectServiceProvider.overrideWithValue(fakeService),
      sessionServiceProvider.overrideWith((ref) async => fakeSessions),
    ],
  );
  addTearDown(c.dispose);
  return (container: c, sessions: fakeSessions);
}
```

Update existing call sites (`addExistingFolder` group and `removeProject` group at lines 85, 92, 102, 110, 118) to use `_makeContainer(...).container` (rename receiver `c` to keep diffs small):

```dart
final c = _makeContainer(fakeService).container;
```

- [ ] **Step 3: Add new tests in the `removeProject` group**

Add the following tests inside the existing `group('removeProject', ...)` block in `test/features/project_sidebar/project_sidebar_actions_test.dart`, right before the closing `});` of that group:

```dart
test('deleteSessions=true → calls deleteSessionsByProject', () async {
  final harness = _makeContainer(fakeService);
  await harness.container.read(projectSidebarActionsProvider.notifier).removeProject('id-1', deleteSessions: true);
  expect(harness.sessions.deleteSessionsByProjectCalls, ['id-1']);
});

test('removing active project clears active session and project', () async {
  final harness = _makeContainer(fakeService);
  harness.container.read(activeProjectIdProvider.notifier).set('id-1');
  harness.container.read(activeSessionIdProvider.notifier).set('s1');

  await harness.container.read(projectSidebarActionsProvider.notifier).removeProject('id-1');

  expect(harness.container.read(activeProjectIdProvider), isNull);
  expect(harness.container.read(activeSessionIdProvider), isNull);
});

test('removing non-active project leaves active state intact', () async {
  final harness = _makeContainer(fakeService);
  harness.container.read(activeProjectIdProvider.notifier).set('id-active');
  harness.container.read(activeSessionIdProvider.notifier).set('s-active');

  await harness.container.read(projectSidebarActionsProvider.notifier).removeProject('id-other');

  expect(harness.container.read(activeProjectIdProvider), 'id-active');
  expect(harness.container.read(activeSessionIdProvider), 's-active');
});
```

`activeProjectIdProvider` is exported from `project_sidebar_notifier.dart`; `activeSessionIdProvider` from `chat_notifier.dart`. Add these imports near the top of the test file:

```dart
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_notifier.dart';
```

- [ ] **Step 4: Run the test file**

```bash
flutter test test/features/project_sidebar/project_sidebar_actions_test.dart
```

Expected: all tests pass (existing + 3 new).

- [ ] **Step 5: Commit**

```bash
git add test/features/project_sidebar/project_sidebar_actions_test.dart
git commit -m "test(sidebar): cover deleteSessions and active-state reset"
```

---

## Task 4: Add `archiveAllSessionsForProject` and `deleteAllSessionsForProject`

**Files:**
- Modify: `lib/features/project_sidebar/notifiers/project_sidebar_actions.dart`
- Modify: `test/features/project_sidebar/project_sidebar_actions_test.dart`

- [ ] **Step 1: Add the two new notifier methods**

In `lib/features/project_sidebar/notifiers/project_sidebar_actions.dart`, immediately after the existing `archiveSession` method (around line 213), add:

```dart
/// Archives every active session for [projectId]. Mirrors [archiveSession]
/// for the active-id reset: if the currently active session is among the
/// affected ones, the active session id is cleared. Archived sessions for
/// the project are unaffected.
Future<void> archiveAllSessionsForProject(String projectId) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    try {
      final svc = await _sessions;
      final sessions = await svc.getSessionsByProject(projectId);
      final activeId = ref.read(activeSessionIdProvider);
      for (final s in sessions) {
        await svc.archiveSession(s.sessionId);
      }
      if (activeId != null && sessions.any((s) => s.sessionId == activeId)) {
        ref.read(activeSessionIdProvider.notifier).set(null);
      }
    } catch (e, st) {
      dLog('[ProjectSidebarActions] archiveAllSessionsForProject failed: $e');
      Error.throwWithStackTrace(_asFailure(e), st);
    }
  });
}

/// Permanently deletes every active session for [projectId]. Archived
/// sessions are unaffected. Clears the active session id when the active
/// session is among the deleted ones.
Future<void> deleteAllSessionsForProject(String projectId) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    try {
      final svc = await _sessions;
      final sessions = await svc.getSessionsByProject(projectId);
      final activeId = ref.read(activeSessionIdProvider);
      for (final s in sessions) {
        await svc.deleteSession(s.sessionId);
      }
      if (activeId != null && sessions.any((s) => s.sessionId == activeId)) {
        ref.read(activeSessionIdProvider.notifier).set(null);
      }
    } catch (e, st) {
      dLog('[ProjectSidebarActions] deleteAllSessionsForProject failed: $e');
      Error.throwWithStackTrace(_asFailure(e), st);
    }
  });
}
```

- [ ] **Step 2: Add tests for the two new methods**

In `test/features/project_sidebar/project_sidebar_actions_test.dart`, fully replace `_FakeSessionService` (the class added in Task 3 Step 1) with the version below. It seeds `getSessionsByProject` with caller-supplied data and records archive/delete calls so tests can assert on them:

```dart
class _FakeSessionService extends Fake implements SessionService {
  final List<String> deleteSessionsByProjectCalls = [];
  final List<String> archiveCalls = [];
  final List<String> deleteCalls = [];
  final Map<String, List<ChatSession>> sessionsByProject = {};

  @override
  Future<String> createSession({required AIModel model, String? title, String? projectId}) async => 'fake-session';

  @override
  Future<List<ChatSession>> getSessionsByProject(String projectId) async =>
      sessionsByProject[projectId] ?? const [];

  @override
  Future<void> deleteSession(String sessionId) async {
    deleteCalls.add(sessionId);
  }

  @override
  Future<void> archiveSession(String sessionId) async {
    archiveCalls.add(sessionId);
  }

  @override
  Future<void> deleteSessionsByProject(String projectId) async {
    deleteSessionsByProjectCalls.add(projectId);
  }
}
```

Then add a new top-level group (sibling to `group('removeProject', ...)`):

```dart
group('bulk session actions', () {
  ChatSession _session(String id, {String project = 'p1'}) => ChatSession(
        sessionId: id,
        title: id,
        modelId: 'm',
        providerId: 'p',
        projectId: project,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

  test('archiveAllSessionsForProject — archives every session and clears active id when included', () async {
    final harness = _makeContainer(fakeService);
    harness.sessions.sessionsByProject['p1'] = [_session('s1'), _session('s2')];
    harness.container.read(activeSessionIdProvider.notifier).set('s2');

    await harness.container.read(projectSidebarActionsProvider.notifier).archiveAllSessionsForProject('p1');

    expect(harness.sessions.archiveCalls, ['s1', 's2']);
    expect(harness.container.read(activeSessionIdProvider), isNull);
  });

  test('archiveAllSessionsForProject — leaves unrelated active session intact', () async {
    final harness = _makeContainer(fakeService);
    harness.sessions.sessionsByProject['p1'] = [_session('s1')];
    harness.container.read(activeSessionIdProvider.notifier).set('elsewhere');

    await harness.container.read(projectSidebarActionsProvider.notifier).archiveAllSessionsForProject('p1');

    expect(harness.sessions.archiveCalls, ['s1']);
    expect(harness.container.read(activeSessionIdProvider), 'elsewhere');
  });

  test('deleteAllSessionsForProject — deletes every session and clears active id when included', () async {
    final harness = _makeContainer(fakeService);
    harness.sessions.sessionsByProject['p1'] = [_session('s1'), _session('s2')];
    harness.container.read(activeSessionIdProvider.notifier).set('s1');

    await harness.container.read(projectSidebarActionsProvider.notifier).deleteAllSessionsForProject('p1');

    expect(harness.sessions.deleteCalls, ['s1', 's2']);
    expect(harness.container.read(activeSessionIdProvider), isNull);
  });

  test('deleteAllSessionsForProject — empty session list short-circuits', () async {
    final harness = _makeContainer(fakeService);

    await harness.container.read(projectSidebarActionsProvider.notifier).deleteAllSessionsForProject('p1');

    expect(harness.sessions.deleteCalls, isEmpty);
    expect(harness.container.read(projectSidebarActionsProvider), isA<AsyncData<void>>());
  });
});
```

- [ ] **Step 3: Run the test file**

```bash
flutter test test/features/project_sidebar/project_sidebar_actions_test.dart
```

Expected: all tests pass (the two new groups plus existing).

- [ ] **Step 4: Format and analyze**

```bash
dart format lib/ test/
flutter analyze
```
Expected: 0 issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/project_sidebar/notifiers/project_sidebar_actions.dart \
        test/features/project_sidebar/project_sidebar_actions_test.dart
git commit -m "feat(sidebar): bulk archive and delete sessions per project"
```

---

## Task 5: Add `ArchiveAllConversationsDialog`

**Files:**
- Create: `lib/features/project_sidebar/widgets/archive_all_conversations_dialog.dart`

- [ ] **Step 1: Create the dialog**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../data/project/models/project.dart';
import '../notifiers/project_sidebar_actions.dart';
import '../notifiers/project_sidebar_failure.dart';

class ArchiveAllConversationsDialog extends ConsumerStatefulWidget {
  const ArchiveAllConversationsDialog({super.key, required this.project});

  final Project project;

  static Future<bool?> show(BuildContext context, Project project) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ArchiveAllConversationsDialog(project: project),
    );
  }

  @override
  ConsumerState<ArchiveAllConversationsDialog> createState() => _ArchiveAllConversationsDialogState();
}

class _ArchiveAllConversationsDialogState extends ConsumerState<ArchiveAllConversationsDialog> {
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(projectSidebarActionsProvider.notifier).archiveAllSessionsForProject(widget.project.id);
      if (!mounted) return;
      if (!ref.read(projectSidebarActionsProvider).hasError) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(projectSidebarActionsProvider, (_, next) {
      if (!_submitting) return;
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      if (failure is! ProjectSidebarFailure) return;
      AppSnackBar.show(
        context,
        'Failed to archive conversations — please try again.',
        type: AppSnackBarType.error,
      );
    });

    return AppDialog(
      icon: AppIcons.archive,
      iconType: AppDialogIconType.teal,
      title: 'Archive all conversations for "${widget.project.name}"?',
      maxWidth: 480,
      content: Builder(
        builder: (context) {
          final c = AppColors.of(context);
          return Text(
            'All active conversations for this project will be moved to the archive. '
            'You can restore them from the archive at any time.',
            style: TextStyle(color: c.mutedFg, fontSize: 11),
          );
        },
      ),
      actions: [
        AppDialogAction.cancel(onPressed: _submitting ? () {} : () => Navigator.of(context).pop(false)),
        AppDialogAction.primary(
          label: _submitting ? 'Archiving…' : 'Archive all',
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Format and analyze**

```bash
dart format lib/
flutter analyze
```
Expected: 0 issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/project_sidebar/widgets/archive_all_conversations_dialog.dart
git commit -m "feat(sidebar): add ArchiveAllConversationsDialog"
```

---

## Task 6: Add `DeleteAllConversationsDialog`

**Files:**
- Create: `lib/features/project_sidebar/widgets/delete_all_conversations_dialog.dart`

The dialog asks for a count to make the wording concrete (mirrors how `RemoveProjectDialog` already uses `fetchSessionCount`-style queries). It also routes to `/chat` after success when the active session was wiped.

- [ ] **Step 1: Create the dialog**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../data/project/models/project.dart';
import '../../chat/notifiers/chat_notifier.dart';
import '../notifiers/project_sidebar_actions.dart';
import '../notifiers/project_sidebar_failure.dart';

class DeleteAllConversationsDialog extends ConsumerStatefulWidget {
  const DeleteAllConversationsDialog({super.key, required this.project});

  final Project project;

  static Future<bool?> show(BuildContext context, Project project) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteAllConversationsDialog(project: project),
    );
  }

  @override
  ConsumerState<DeleteAllConversationsDialog> createState() => _DeleteAllConversationsDialogState();
}

class _DeleteAllConversationsDialogState extends ConsumerState<DeleteAllConversationsDialog> {
  bool _submitting = false;
  late final Future<int> _countFuture =
      ref.read(projectSidebarActionsProvider.notifier).fetchSessionCount(widget.project.id);

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(projectSidebarActionsProvider.notifier).deleteAllSessionsForProject(widget.project.id);
      if (!mounted) return;
      if (ref.read(projectSidebarActionsProvider).hasError) return;
      Navigator.of(context).pop(true);
      if (ref.read(activeSessionIdProvider) == null && context.mounted) {
        context.go('/chat');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(projectSidebarActionsProvider, (_, next) {
      if (!_submitting) return;
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      if (failure is! ProjectSidebarFailure) return;
      AppSnackBar.show(
        context,
        'Failed to delete conversations — please try again.',
        type: AppSnackBarType.error,
      );
    });

    return AppDialog(
      icon: AppIcons.trash,
      iconType: AppDialogIconType.destructive,
      title: 'Delete all conversations for "${widget.project.name}"?',
      maxWidth: 480,
      content: Builder(
        builder: (context) {
          final c = AppColors.of(context);
          return FutureBuilder<int>(
            future: _countFuture,
            builder: (_, snap) {
              final count = snap.data ?? 0;
              final phrase = count == 1 ? '1 active conversation' : '$count active conversations';
              return Text(
                'This will permanently delete $phrase for this project. '
                'Archived conversations are unaffected.',
                style: TextStyle(color: c.mutedFg, fontSize: 11),
              );
            },
          );
        },
      ),
      actions: [
        AppDialogAction.cancel(onPressed: _submitting ? () {} : () => Navigator.of(context).pop(false)),
        AppDialogAction.destructive(
          label: _submitting ? 'Deleting…' : 'Delete all',
          onPressed: _submitting ? () {} : _submit,
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Format and analyze**

```bash
dart format lib/
flutter analyze
```
Expected: 0 issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/project_sidebar/widgets/delete_all_conversations_dialog.dart
git commit -m "feat(sidebar): add DeleteAllConversationsDialog"
```

---

## Task 7: Add menu items to `ProjectContextMenu`

**Files:**
- Modify: `lib/features/project_sidebar/widgets/project_context_menu.dart`

- [ ] **Step 1: Add the two new items**

In `lib/features/project_sidebar/widgets/project_context_menu.dart`, edit the items list inside `show(...)` (currently lines 32–47). Replace the entire `items: [ ... ]` block with:

```dart
items: [
  if (!isMissing) ...[
    _buildItem('open_finder', 'Open in Finder', Icons.folder_open_outlined, c),
    _buildItem('copy_path', 'Copy path', Icons.copy_outlined, c),
    const PopupMenuDivider(),
    _buildItem('new_conversation', 'New conversation', Icons.add, c),
    const PopupMenuDivider(),
    _buildItem('archive_all', 'Archive all conversations', AppIcons.archive, c),
    _buildDangerItem('delete_all', 'Delete all conversations', c, icon: Icons.delete_sweep),
    const PopupMenuDivider(),
  ] else ...[
    _buildItem('copy_path', 'Copy path', Icons.copy_outlined, c),
    const PopupMenuDivider(),
    _buildItem('relocate', 'Relocate…', Icons.drive_file_move_outlined, c),
    const PopupMenuDivider(),
  ],
  _buildDangerItem('remove', 'Remove from Code Bench', c),
],
```

This places the two new actions only in the non-missing branch (when a project is missing the user goes through Remove instead, which already does full cleanup).

- [ ] **Step 2: Update `_buildDangerItem` to accept an icon**

`_buildDangerItem` currently hard-codes `Icons.close`. Replace its definition (lines 64–76) with:

```dart
static PopupMenuItem<String> _buildDangerItem(String value, String label, AppColors c, {IconData icon = Icons.close}) {
  return PopupMenuItem<String>(
    value: value,
    height: 32,
    child: Row(
      children: [
        Icon(icon, size: 14, color: c.error),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: c.error, fontSize: 11)),
      ],
    ),
  );
}
```

- [ ] **Step 3: Add `onArchiveAll` / `onDeleteAll` to `handleAction`**

Replace the `handleAction` method signature and body (lines 78–117) with:

```dart
static Future<void> handleAction({
  required String action,
  required String projectId,
  required String projectPath,
  required BuildContext context,
  required Function(String) onRemove,
  required Function(String) onNewConversation,
  required Function(String) onArchiveAll,
  required Function(String) onDeleteAll,
  Function(String)? onRelocate,
}) async {
  switch (action) {
    case 'open_finder':
      try {
        final launched = await launchUrl(Uri.file(projectPath), mode: LaunchMode.platformDefault);
        if (!launched && context.mounted) {
          AppSnackBar.show(context, 'Could not open in Finder.', type: AppSnackBarType.error);
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.show(context, 'Could not open in Finder.', type: AppSnackBarType.error);
        }
      }
    case 'copy_path':
      try {
        await Clipboard.setData(ClipboardData(text: projectPath));
        if (context.mounted) {
          AppSnackBar.show(context, 'Path copied.', type: AppSnackBarType.success);
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.show(context, 'Could not copy path.', type: AppSnackBarType.error);
        }
      }
    case 'new_conversation':
      onNewConversation(projectId);
    case 'relocate':
      onRelocate?.call(projectId);
    case 'archive_all':
      onArchiveAll(projectId);
    case 'delete_all':
      onDeleteAll(projectId);
    case 'remove':
      onRemove(projectId);
  }
}
```

- [ ] **Step 4: Format and analyze**

```bash
dart format lib/
flutter analyze
```
Expected: 0 issues — note the analyzer will surface call-site mismatches in `project_tile.dart`; those are addressed in Task 8.

If the analyzer reports errors only in `project_tile.dart`, that's expected (call site update follows in Task 8). Proceed without committing yet — Tasks 7–9 ship as one wired-up feature.

---

## Task 8: Plumb new callbacks through `ProjectTile`

**Files:**
- Modify: `lib/features/project_sidebar/widgets/project_tile.dart`

- [ ] **Step 1: Add new required callbacks to the constructor**

In `lib/features/project_sidebar/widgets/project_tile.dart`, edit the constructor (lines 17–30) and the field declarations (lines 32–42). After `onRelocate`, add `onArchiveAll` and `onDeleteAll`:

Constructor parameter list:
```dart
const ProjectTile({
  super.key,
  required this.project,
  required this.sessions,
  required this.isExpanded,
  required this.activeSessionId,
  required this.onToggleExpand,
  required this.onSessionTap,
  required this.onRemove,
  required this.onNewConversation,
  required this.onArchive,
  required this.onDelete,
  required this.onRelocate,
  required this.onArchiveAll,
  required this.onDeleteAll,
});
```

Fields:
```dart
final Project project;
final List<ChatSession> sessions;
final bool isExpanded;
final String? activeSessionId;
final VoidCallback onToggleExpand;
final ValueChanged<String> onSessionTap;
final ValueChanged<String> onRemove;
final ValueChanged<String> onNewConversation;
final ValueChanged<String> onArchive;
final ValueChanged<String> onDelete;
final ValueChanged<String> onRelocate;
final ValueChanged<String> onArchiveAll;
final ValueChanged<String> onDeleteAll;
```

- [ ] **Step 2: Pass them to `ProjectContextMenu.handleAction`**

In the `onSecondaryTapUp` body (around lines 79–89), update the `ProjectContextMenu.handleAction` call to forward the new callbacks:

```dart
await ProjectContextMenu.handleAction(
  action: action,
  projectId: widget.project.id,
  projectPath: widget.project.path,
  context: context,
  onRemove: widget.onRemove,
  onNewConversation: widget.onNewConversation,
  onRelocate: widget.onRelocate,
  onArchiveAll: widget.onArchiveAll,
  onDeleteAll: widget.onDeleteAll,
);
```

- [ ] **Step 3: Format and analyze**

```bash
dart format lib/
flutter analyze
```
Expected: errors remain in `project_sidebar.dart` (the only call-site for `ProjectTile`) until Task 9. Proceed.

---

## Task 9: Wire dialogs in `project_sidebar.dart`

**Files:**
- Modify: `lib/features/project_sidebar/project_sidebar.dart`

- [ ] **Step 1: Add imports for the new dialogs**

Near the top of `lib/features/project_sidebar/project_sidebar.dart`, add (alphabetically with the existing imports for the other dialogs):

```dart
import 'widgets/archive_all_conversations_dialog.dart';
import 'widgets/delete_all_conversations_dialog.dart';
```

- [ ] **Step 2: Pass new callbacks to `ProjectTile`**

Locate the `ProjectTile(...)` constructor call (around lines 210–243) and append two new callbacks after `onDelete`:

```dart
onArchiveAll: (id) async {
  final p = projects.firstWhere((p) => p.id == id);
  await ArchiveAllConversationsDialog.show(context, p);
},
onDeleteAll: (id) async {
  final p = projects.firstWhere((p) => p.id == id);
  await DeleteAllConversationsDialog.show(context, p);
},
```

- [ ] **Step 3: Format, analyze, run tests**

```bash
dart format lib/
flutter analyze
flutter test
```
Expected: 0 issues, all tests pass.

- [ ] **Step 4: Commit Tasks 7–9 together**

The three preceding tasks form a single feature surface (menu → tile → dialog). Commit as one:

```bash
git add lib/features/project_sidebar/widgets/project_context_menu.dart \
        lib/features/project_sidebar/widgets/project_tile.dart \
        lib/features/project_sidebar/project_sidebar.dart
git commit -m "feat(sidebar): wire bulk archive/delete actions into context menu"
```

---

## Task 10: Make `RemoveProjectDialog` route to `/chat` after success

**Files:**
- Modify: `lib/features/project_sidebar/widgets/remove_project_dialog.dart`

- [ ] **Step 1: Add the post-success navigation**

In `lib/features/project_sidebar/widgets/remove_project_dialog.dart`, replace the `_submit` method (currently lines 31–42) with:

```dart
Future<void> _submit() async {
  setState(() => _submitting = true);
  try {
    await ref.read(projectSidebarActionsProvider.notifier).removeProject(widget.project.id, deleteSessions: true);
    if (!mounted) return;
    if (ref.read(projectSidebarActionsProvider).hasError) return;
    Navigator.of(context).pop(true);
    if (ref.read(activeSessionIdProvider) == null && context.mounted) {
      context.go('/chat');
    }
  } finally {
    if (mounted) setState(() => _submitting = false);
  }
}
```

Add the imports at the top of the file (alphabetically alongside existing ones):

```dart
import 'package:go_router/go_router.dart';

import '../../chat/notifiers/chat_notifier.dart';
```

The post-success navigation only fires when `activeSessionIdProvider` is `null` — that's the signal that `removeProject` cleared the active project. Otherwise (removing a non-active project) navigation stays untouched.

- [ ] **Step 2: Format, analyze, run tests**

```bash
dart format lib/
flutter analyze
flutter test
```
Expected: 0 issues, all tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/project_sidebar/widgets/remove_project_dialog.dart
git commit -m "fix(sidebar): route to /chat after removing the active project"
```

---

## Task 11: Final verification + manual QA

**Files:** none.

- [ ] **Step 1: Full verification suite**

From the worktree root:

```bash
dart format lib/ test/
flutter analyze
flutter test
```

Expected: 0 issues, all tests pass.

- [ ] **Step 2: Run the macOS app**

```bash
flutter run -d macos
```

- [ ] **Step 3: Manual QA — walk through each scenario in the spec**

Per [memory/feedback_post_plan_qa_checklist.md](../../../../.claude/projects/-Users-mk-Downloads-app-Benchlabs-code-bench-app/memory/feedback_post_plan_qa_checklist.md), verify each item explicitly. Checklist:

1. **Orphan archive cleanup.** Project with at least one active and one archived session → right-click → "Remove from Code Bench" → confirm → open Archive screen → no entries remain for that project.
2. **Active project removal resets chat.** Make a project active by clicking a session → right-click that project → Remove → chat view shows the empty state ("Select a project and start a conversation"); URL bar (if visible) is `/chat`.
3. **Archive all conversations.** Right-click a project with multiple sessions → "Archive all conversations" → confirm → sessions disappear from the sidebar; archive screen lists them grouped under that project.
4. **Delete all conversations.** Right-click a project → "Delete all conversations" → confirm → sessions disappear; archive screen does NOT list them; archived sessions for the project are still there.
5. **Delete all on the active project.** Make a session in project P active → right-click P → Delete all → chat view shows empty state, URL is `/chat`.
6. **Missing project.** Move/rename a project folder on disk → restart app → right-click the missing project → Archive all and Delete all are NOT shown; Remove still works.
7. **Empty project.** Right-click a project with zero active sessions → Delete all → confirm → no error; "0 active conversations" appears in the dialog text.

- [ ] **Step 4: If everything passes, push the branch**

```bash
git push -u origin feat/2026-05-08-remove-project-cleanup-and-bulk-actions
```

(Skip if the user prefers to push later.)

---

## Self-review notes (for the planner, not the executor)

- Spec coverage: every section of the spec maps to at least one task. Datasource transaction → Task 1. Notifier reset of active state → Task 2. Bulk methods → Task 4. Context-menu items + dialogs → Tasks 5–9. Remove dialog navigation → Task 10. Manual QA mirrors the spec's QA list.
- Type consistency: `archiveAllSessionsForProject` / `deleteAllSessionsForProject` are used identically in tests, dialogs, and context-menu wiring. `deleteSessionsByProject` (singular target → multi delete) is used only on the data path. No naming drift.
- The plan deliberately commits Tasks 7–9 together because they are intermediate states that don't compile on their own. Every other task ends in a clean compile + test pass.
