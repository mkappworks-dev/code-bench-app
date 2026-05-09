# Remove-project cleanup & per-project bulk session actions

**Date:** 2026-05-08
**Type:** feat

## Problem

Three related sidebar issues:

1. **Orphaned archives.** `ProjectSidebarActions.removeProject(deleteSessions: true)` calls `getSessionsByProject(id)`, which is backed by `watchSessionsByProject` filtered to `isArchived = false` ([app_database.dart:122](../../../lib/data/_core/app_database.dart#L122-L126)). Archived sessions for a removed project remain in the archive screen showing "No Project".
2. **Stale chat view.** `removeProject` never clears `activeSessionIdProvider` / `activeProjectIdProvider`. When the active project is removed, its (now-deleted) chat session URL stays mounted and the chat view continues to render.
3. **No bulk actions.** Users can only archive/delete sessions one at a time. There is no per-project bulk action in the sidebar.

## Goals

- Removing a project deletes **all** of its sessions (active + archived) and clears the active chat view if the active project was removed.
- Sidebar context menu offers "Archive all conversations" and "Delete all conversations" per project, scoped to **active** sessions only.

## Non-goals

- No bulk action that touches archived sessions from the sidebar — those remain manageable from the archive screen ([archive_actions.dart:64](../../../lib/features/archive/notifiers/archive_actions.dart#L64-L80)).
- No project-rename or other unrelated sidebar redesign.

## Architecture

Bottom-up changes following the dependency rule (Datasource → Repository → Service → Notifier → Widget):

### 1. Datasource — [app_database.dart](../../../lib/data/_core/app_database.dart)

Add to `SessionDao`:

```dart
Future<void> deleteSessionsByProject(String projectId) async {
  await transaction(() async {
    final ids = await (select(chatSessions)..where((t) => t.projectId.equals(projectId)))
        .map((row) => row.sessionId).get();
    if (ids.isEmpty) return;
    await (delete(chatMessages)..where((t) => t.sessionId.isIn(ids))).go();
    await (delete(chatSessions)..where((t) => t.projectId.equals(projectId))).go();
  });
}
```

The query intentionally does **not** filter `isArchived` — both states are deleted in one transaction so a mid-call failure leaves no orphans.

Wire through `SessionDatasource` interface and the drift implementation ([session_datasource_drift.dart](../../../lib/data/session/datasource/session_datasource_drift.dart)).

### 2. Repository — [session_repository.dart](../../../lib/data/session/repository/session_repository.dart)

Add `Future<void> deleteSessionsByProject(String projectId)` to the interface and `SessionRepositoryImpl` — direct passthrough to the datasource.

### 3. Service — [session_service.dart](../../../lib/services/session/session_service.dart)

Add `Future<void> deleteSessionsByProject(String projectId)` — passthrough to repository.

### 4. Notifier — [project_sidebar_actions.dart](../../../lib/features/project_sidebar/notifiers/project_sidebar_actions.dart)

**Modify `removeProject`:**

```dart
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

**Add `archiveAllSessionsForProject`:**

```dart
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
```

**Add `deleteAllSessionsForProject`:** identical shape, calls `deleteSession` instead of `archiveSession`.

`getSessionsByProject` already returns active-only (the underlying `watchSessionsByProject` filter), so both bulk methods scope to active by construction.

### 5. UI

**[project_context_menu.dart](../../../lib/features/project_sidebar/widgets/project_context_menu.dart):** insert two items above the existing divider that precedes the "Remove" item, only when `!isMissing`:

```
Archive all conversations  (icon: AppIcons.archive)
Delete all conversations   (danger style, icon: Icons.delete_sweep)
─────────────────────────
Remove from Code Bench     (danger)
```

`handleAction` switch grows two cases (`'archive_all'`, `'delete_all'`) that call new `onArchiveAll(projectId)` / `onDeleteAll(projectId)` callbacks.

**New widgets** in `lib/features/project_sidebar/widgets/`:

- `archive_all_conversations_dialog.dart` — neutral `AppDialog` (icon: archive), copy: *"Archive all conversations for `<name>`? They'll be moved to the archive and can be restored from there."* Action: "Archive all". Submission calls `projectSidebarActionsProvider.notifier.archiveAllSessionsForProject(projectId)`.
- `delete_all_conversations_dialog.dart` — destructive `AppDialog`, copy: *"This will permanently delete all `<count>` active conversations for `<name>`. Archived conversations are unaffected."* Action: "Delete all". Submission calls `deleteAllSessionsForProject`.

Both dialogs follow the [remove_project_dialog.dart](../../../lib/features/project_sidebar/widgets/remove_project_dialog.dart) pattern: local `_submitting` flag, `ref.listen` on the actions provider for error snack bars, `Navigator.of(context).pop(true)` on success.

`delete_all_conversations_dialog` reads the count via `projectSidebarActionsProvider.notifier.fetchSessionCount(projectId)` — same pattern as `remove_project_dialog` does for its message.

**[remove_project_dialog.dart](../../../lib/features/project_sidebar/widgets/remove_project_dialog.dart):** after success, also call `context.go('/chat')` so the URL doesn't linger on a deleted session. Same logic in both new dialogs (`archive_all_conversations_dialog` and `delete_all_conversations_dialog`) when the active session was in scope: navigate to `/chat` if `ref.read(activeSessionIdProvider) == null` after the action. This matches the existing `_runSessionMutation` flow at [project_sidebar.dart:87-98](../../../lib/features/project_sidebar/project_sidebar.dart#L87-L98), which routes to `/chat` whenever the active session is mutated by single-archive or single-delete.

**[project_tile.dart](../../../lib/features/project_sidebar/widgets/project_tile.dart):** plumb new `onArchiveAll` / `onDeleteAll` callbacks through `ProjectContextMenu.handleAction`.

**[project_sidebar.dart](../../../lib/features/project_sidebar/project_sidebar.dart):** wire `onArchiveAll` / `onDeleteAll` to show the new dialogs.

## Data flow

```
Remove project (active project)
  RemoveProjectDialog.submit
    → removeProject(id, deleteSessions: true)
        → SessionService.deleteSessionsByProject(id)   [active+archived, single txn]
        → ProjectService.removeProject(id)
        → clear activeSessionIdProvider + activeProjectIdProvider
    → Navigator.pop(true)
    → context.go('/chat')

Archive all (project tile)
  ArchiveAllConversationsDialog.submit
    → archiveAllSessionsForProject(projectId)
        → for each active session: SessionService.archiveSession
        → if active session was among them: clear activeSessionIdProvider
    → Navigator.pop(true)
    → if activeSessionId is now null: context.go('/chat')

Delete all (project tile)
  DeleteAllConversationsDialog.submit
    → deleteAllSessionsForProject(projectId)
        → for each active session: SessionService.deleteSession
        → if active session was among them: clear activeSessionIdProvider
    → Navigator.pop(true)
    → if activeSessionId is now null: context.go('/chat')
```

## Error handling

- All new notifier methods follow the canonical Actions shape (`AsyncLoading` → `AsyncValue.guard` → catch → `dLog` → `Error.throwWithStackTrace(_asFailure(e), st)`).
- `_asFailure` already handles `StorageException` and falls through to `unknown` for everything else — sufficient for both bulk methods. No new failure variants.
- Bulk methods use a sequential loop. A failure mid-loop leaves the already-completed mutations applied (consistent with [archive_actions.dart:64](../../../lib/features/archive/notifiers/archive_actions.dart#L64-L80)) — the user retries from the still-present sessions.
- `deleteSessionsByProject` (used by Remove) is a single transaction, so it's all-or-nothing — important since the project removal that follows would otherwise orphan a partial deletion.

## Testing

Unit tests for:

- `SessionDao.deleteSessionsByProject` deletes both active and archived sessions and their messages.
- `ProjectSidebarActions.removeProject` clears `activeSessionIdProvider` + `activeProjectIdProvider` when removing the active project; leaves them untouched otherwise.
- `archiveAllSessionsForProject` and `deleteAllSessionsForProject` clear `activeSessionIdProvider` when the active session is in scope.

Manual QA checklist (per [feedback_post_plan_qa_checklist.md](../../../../.claude/projects/-Users-mk-Downloads-app-Benchlabs-code-bench-app/memory/feedback_post_plan_qa_checklist.md)):

1. Project with active+archived sessions: Remove → archive screen no longer lists those archives.
2. Active project: Remove → chat view shows empty state, URL is `/`.
3. Right-click project → Archive all → confirm → archive screen shows them grouped under that project.
4. Right-click project → Delete all → confirm → sessions gone; archived sessions for the project remain.
5. Delete all on the active project → chat view shows empty state, URL routes to `/`.
6. Missing project: context menu hides Archive all / Delete all (Remove still visible).

## Worktree

```
git worktree add .worktrees/feat/2026-05-08-remove-project-cleanup-and-bulk-actions \
  -b feat/2026-05-08-remove-project-cleanup-and-bulk-actions
```
