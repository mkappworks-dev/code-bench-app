# Code Bench — UI Polish Phase 2: Code Change Cards & Changes Panel

## Overview

Phase 2 introduces two connected features: inline code change cards (diff view triggered from code blocks) and a session-level changes panel that tracks every file the user has applied during a conversation.

The data model is designed so agentic tool calls (Phase 2B, future) slot in as a first-class message type without restructuring anything built here.

This is Phase 2 of a three-phase UI improvement queue. Phase 1 (icon/token/layout polish) and Phase 3 (stub button functionality) are separate specs.

---

## Decisions Made

### 1. Code Change Card Trigger

Code blocks render as plain syntax-highlighted blocks by default. A faint **Diff** button appears in the code block header.

**Condition for showing the Diff button:** the code fence must include a filename (e.g. ` ```dart lib/auth/middleware.dart `). No filename = plain block only, no Diff button.

Clicking Diff:
1. Reads the target file from disk, matched by the filename in the code fence
2. Computes a unified diff using `diff_match_patch`
3. Expands the block inline into a card with **Before / Diff / After** tabs
4. Shows **Apply** and **Collapse** buttons

**Apply** writes the new content to disk, records a snapshot in `AppliedChangesNotifier`, and adds an entry to the changes panel.

**Edge cases:**
- File doesn't exist on disk → Diff shows all lines as additions; Apply creates the file
- File already has unapplied local edits → diff is computed against current disk content (not last commit)

### 2. Changes Panel

A collapsible side panel anchored to the right of the chat column, 190px wide, tracking every applied file for the session.

**Toggle:** A `● N changes` dot + label in the status bar. Hidden when no changes have been applied. Clicking opens/closes the panel.

**Panel contents:**
- Entries grouped by the chat message that triggered the Apply
- Each entry: filename (monospace, truncated with ellipsis) + relative path + `+N −N` line counts + ↩ revert button
- "Commit all →" button in the panel footer (stub in this phase — wires to Phase 3 git flow)

**Panel persistence:** state survives open/close within the session. Cleared only when the session is deleted.

### 3. Revert Strategy

The ↩ button per file in the changes panel:

| Project type | File was pre-existing | File was new (created by Apply) |
|---|---|---|
| Git repo | `git checkout -- <filepath>` | Delete the file |
| Non-git | Write back in-memory snapshot | Delete the file |

`isGit` from `WorkspaceProjects` is used to branch behaviour. The in-memory snapshot is captured at Apply time for non-git projects.

After revert: entry is removed from the panel, change count decrements.

### 4. Data Model

**`AppliedChange`** — in-memory only (not persisted to SQLite). Ephemeral per session.

```dart
@freezed
class AppliedChange with _$AppliedChange {
  const factory AppliedChange({
    required String id,           // uuid
    required String sessionId,
    required String messageId,    // ChatMessage that contained the code block
    required String filePath,     // absolute path on disk
    String? originalContent,      // null = file didn't exist before Apply
    required DateTime appliedAt,
  }) = _AppliedChange;
}
```

**`AppliedChangesNotifier`** — `keepAlive` Riverpod notifier holding a `Map<sessionId, List<AppliedChange>>` internally. Exposes:
- `apply(AppliedChange)` — add entry
- `revert(String id)` — remove entry + trigger file restoration
- `watchForSession(String sessionId)` — stream filtered by session

**`ApplyService`** — new thin service handling the Apply + revert filesystem operations:
- `applyChange({filePath, newContent, sessionId, messageId})` → snapshots, writes file, notifies notifier
- `revertChange(AppliedChange change, {required bool isGit})` → branches on git/non-git, removes entry

### 5. Future Agentic Hook (Phase 2B)

When real tool-use API calls arrive, `ChatMessage` gains:

```dart
@Default([]) List<ToolEvent> toolEvents,
```

A `ToolEvent` carries `{type, toolName, input, output, filePath?}`. Tool-driven file writes push `AppliedChange` entries into the same notifier via `ApplyService`. The changes panel requires no redesign — it already watches the notifier.

---

## Files Touched

| File | Changes |
|---|---|
| `pubspec.yaml` | Add `diff_match_patch` |
| `lib/data/models/applied_change.dart` | New `@freezed` model |
| `lib/services/apply/apply_service.dart` | New service — apply + revert filesystem logic |
| `lib/features/chat/chat_notifier.dart` | Add `AppliedChangesNotifier` (keepAlive, keyed by sessionId) |
| `lib/features/chat/widgets/message_bubble.dart` | Add Diff button to code block header; inline expansion to change card |
| `lib/features/chat/widgets/changes_panel.dart` | New widget — session changes panel |
| `lib/shell/chat_shell.dart` | Add panel layout slot (right of chat column); wire panel toggle state |
| `lib/shell/widgets/status_bar.dart` | Add `● N changes` indicator wired to `AppliedChangesNotifier` |

---

## Out of Scope for This Phase

- Agentic tool-use API calls (Phase 2B — future spec)
- Functional Commit & Push from the panel footer (Phase 3)
- Diff view for files not referenced by filename in the code fence
- Conflict resolution if the file was edited externally between Apply and revert
