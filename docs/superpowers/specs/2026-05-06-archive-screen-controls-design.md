# Archive Screen Controls — Design Spec

**Date:** 2026-05-06  
**Status:** Approved

## Overview

Add expand/collapse grouping, per-session delete, and project-level unarchive-all / delete-all to the Archive screen. Also add a confirmation dialog to the project-sidebar single-session delete flow, which currently deletes immediately without confirmation.

---

## Goals

1. Archive screen groups archived sessions by project with collapsible sections.
2. Smart default expansion: one project group → expanded; more than one → all collapsed.
3. Users can delete a single archived session (with confirmation dialog).
4. Users can unarchive or delete **all** archived sessions for a project at once.
5. Sidebar session delete also gets a confirmation dialog (consistency).

## Out of Scope

- Removing the project itself from Code Bench (only archived sessions are affected).
- Persisting expand/collapse state across app restarts.
- Any changes to active (non-archived) sessions.

---

## Section 1: Data & Actions Layer

### `ArchiveActions` — new methods

File: `lib/features/archive/notifiers/archive_actions.dart`

Three new methods, each following the existing `AsyncValue.guard` + `_asFailure` pattern:

| Method | Delegates to | Notes |
|---|---|---|
| `deleteSession(String id)` | `SessionService.deleteSession` | Single-session permanent delete |
| `unarchiveAllForProject(List<String> sessionIds)` | `SessionService.unarchiveSession` in a loop | Sequential; no confirmation needed (reversible) |
| `deleteAllForProject(List<String> sessionIds)` | `SessionService.deleteSession` in a loop | Sequential; confirmed by caller before calling |

`ArchiveFailure` is **unchanged** — the existing `ArchiveStorageError` and `ArchiveUnknownError` variants cover all three paths.

---

## Section 2: New `ArchiveProjectGroup` Widget

File: `lib/features/archive/widgets/archive_project_group.dart`

Replaces the flat `ProjectHeader` + session list rendering in `ArchiveScreen`.

### Constructor

```dart
ArchiveProjectGroup({
  required String projectName,
  required List<ChatSession> sessions,
  required bool initiallyExpanded,
})
```

### State

`late bool _expanded = widget.initiallyExpanded` — toggled by the header chevron via `setState`.

### Header row (always visible)

Left to right:
1. **Chevron icon** — rotates 90° when expanded (animated). Tapping toggles `_expanded`.
2. **Folder icon** + **project name** (uppercase, muted style — matching existing `ProjectHeader`).
3. `Spacer()`
4. **Action chips** — visible on hover only (`MouseRegion`), appear as a `Row`:
   - **"Unarchive All"** — teal accent chip (restore icon, same style as the existing Unarchive chip in `ArchivedSessionCard`). Calls `unarchiveAllForProject` directly, no confirmation.
   - **"Delete All"** — destructive chip (trash icon, `c.error` text + `c.destructiveBorder` border). Opens confirmation dialog before calling `deleteAllForProject`.

### "Delete All" confirmation dialog

Uses `AppDialog` with `AppDialogIconType.destructive`:
- **Title:** `Delete all archived conversations for "[Project Name]"?`
- **Body:** `This will permanently delete [N] archived conversation(s). This cannot be undone.`
- **Actions:** Cancel + destructive "Delete All"

### Collapsed state

Only the header row is rendered. Session cards are hidden.

### Expanded state

Session cards render below the header in the same style as today.

---

## Section 3: `ArchivedSessionCard` — Delete Button

File: `lib/features/archive/widgets/archived_session_card.dart`

A **Delete** chip is added to the right of the existing Unarchive chip. Both are always visible (not hover-only), matching the current Unarchive button's visibility behaviour.

- **Style:** same chip shape as Unarchive; `c.error` text, `c.destructiveBorder` border, trash icon at 12px, on hover background uses `c.error.withValues(alpha: 0.08)`.
- **Flow:** tap → `AppDialog` confirmation (destructive):
  - **Title:** `Delete archived conversation?`
  - **Subtitle (session name pill):** the session's title, displayed as a muted chip below the title to give the user clear context on what they're deleting
  - **Body:** `This will permanently delete the conversation and all its messages. This cannot be undone.`
  - **Actions:** Cancel + destructive "Delete"
  - On confirm → `archiveActionsProvider.notifier.deleteSession(session.sessionId)`.

---

## Section 4: `ArchiveScreen` — Wiring & Snackbars

File: `lib/features/archive/archive_screen.dart`

### List rendering

Replaces the flat loop with `ArchiveProjectGroup` instances:

```dart
for (final entry in groups.entries)
  ArchiveProjectGroup(
    projectName: projectMap[entry.key] ?? 'No Project',
    sessions: entry.value,
    initiallyExpanded: groups.length == 1,
  ),
```

### `_pendingAction` enum

`_ArchiveScreenState` tracks a `_ArchivePendingAction?` field (local, not a provider) set immediately before each action call:

```dart
enum _ArchivePendingAction { unarchive, unarchiveAll, delete, deleteAll }
```

### Snackbar messages

The existing `ref.listen` on `archiveActionsProvider` reads `_pendingAction` to show the right success message:

| `_pendingAction` | Success snackbar text |
|---|---|
| `unarchive` | "Session unarchived" |
| `unarchiveAll` | "All sessions unarchived" |
| `delete` | "Session deleted" |
| `deleteAll` | "All archived sessions deleted" |

Error handling is unchanged — any `ArchiveFailure` shows the existing generic error snackbar.

---

## Section 5: Sidebar Session Delete — Confirmation Dialog

File: `lib/features/project_sidebar/widgets/conversation_tile.dart` (or wherever the delete session tap handler lives)

The project sidebar's "Delete conversation" action currently calls `deleteSession` immediately. Add a confirmation `AppDialog` (destructive style) before calling it:

- **Title:** `Delete this conversation?`
- **Body:** `This cannot be undone.`
- **Actions:** Cancel + destructive "Delete"
- On confirm → existing `projectSidebarActionsProvider.notifier.deleteSession(id)` call.

No changes to `ProjectSidebarActions` or `ProjectSidebarFailure`.

---

## Files Changed

| File | Change |
|---|---|
| `lib/features/archive/notifiers/archive_actions.dart` | Add `deleteSession`, `unarchiveAllForProject`, `deleteAllForProject` |
| `lib/features/archive/widgets/archive_project_group.dart` | **New** — collapsible project group widget |
| `lib/features/archive/widgets/archived_session_card.dart` | Add Delete chip + confirmation dialog |
| `lib/features/archive/archive_screen.dart` | Wire `ArchiveProjectGroup`; add `_pendingAction` enum + snackbar logic |
| `lib/features/project_sidebar/widgets/conversation_tile.dart` | Add confirmation dialog before delete |

No new providers, no new failure types, no generated files.
