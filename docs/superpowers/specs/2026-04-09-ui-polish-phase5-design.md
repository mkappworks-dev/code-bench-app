# Code Bench — UI Polish Phase 5: Agentic Tool-use & Advanced Diff

## Overview

Phase 5 extends the chat surface to support real agentic tool-use (tool-call cards with metrics), closes the Phase 2 diff gap (nameless code fences), adds conflict resolution when files are externally edited, upgrades the Push button for multi-remote repos, and introduces inline PR review.

The Phase 2 data model hook (`toolEvents` on `ChatMessage`) is activated here. The `AppliedChangesNotifier` and `ApplyService` from Phase 2 wire up to tool-driven file writes automatically.

This is Phase 5 of the UI improvement queue.

---

## Decisions Made

### 1. Tool-call Cards

When the AI agent calls a tool mid-conversation, a card is inserted into the message bubble.

#### Collapsed row (default)

Each tool call renders as a single row:
- Lucide tool icon
- Tool name (monospace)
- Primary argument (e.g., file path, truncated with ellipsis)
- Status indicator: blue spinner (running) / green ✓ (done) / red ✗ (failed)
- Duration (e.g., `0.3s`)
- Token counts: `↑ N ↓ N` (sent / received)

Tapping a row expands it inline.

#### Expanded row

- **Input section** — key/value pairs from tool call arguments
- **Output section** — truncated result text (max ~5 lines; "Show more" link for long outputs)
- **Metrics footer** — duration + tokens sent + tokens received

#### Data model

`ChatMessage` gains (Phase 2 hook activated):

```dart
@Default([]) List<ToolEvent> toolEvents,
```

```dart
@freezed
class ToolEvent with _$ToolEvent {
  const factory ToolEvent({
    required String type,
    required String toolName,
    required Map<String, dynamic> input,
    String? output,
    String? filePath,
    int? durationMs,
    int? tokensIn,
    int? tokensOut,
  }) = _ToolEvent;
}
```

Tool-driven file writes call `ApplyService.applyChange(...)` — the changes panel and revert logic require no redesign.

---

### 2. Diff Without Filename

Code fences with no filename show a faint **Diff…** button (ellipsis indicates a pick is required). Fences with a filename show the regular **Diff** button from Phase 2.

**Clicking Diff…:**
1. Expands an inline form directly below the code block
2. Label: `"Which file does this update?"`
3. Text input with fuzzy autocomplete — filters project files as the user types using `ProjectDao.listFiles()` + client-side substring filter
4. Suggestions list below the input shows matching paths
5. Enter or clicking **Diff** confirms selection and proceeds to the normal Before/Diff/After card
6. **✕** dismisses and collapses back to the plain block

**New file edge case:** if the selected file doesn't exist, all lines are shown as additions and Apply creates the file — identical to the Phase 2 new-file path.

No LLM call involved — purely client-side file matching.

---

### 3. Conflict Resolution on Revert

Triggered when the user clicks ↩ Revert on a file that has been externally edited since Apply.

#### Detection

At Apply time, `ApplyService` records a SHA-256 checksum of the written content in `AppliedChange.contentChecksum`. On Revert (and on changes panel open), the current disk content is checksummed and compared. A mismatch means the file was externally edited.

An **`edited` badge** (amber, same style as the `No Git` badge) appears on the file row in the changes panel when a mismatch is detected.

#### Three-way merge view

Shown inline below the file row when ↩ is clicked on an `edited` file:

| Tab | Content |
|---|---|
| **Original** | Content before Apply (the snapshot from `AppliedChange.originalContent`) |
| **Applied** | What Apply wrote |
| **Current** | What is on disk now |

**Footer actions:**
- **Accept revert** — writes the original snapshot back to disk, removes the entry from the panel
- **Keep current** — dismisses the merge view, leaves the file unchanged, keeps the panel entry

**Git repos:** "Accept revert" uses `git checkout -- <path>`. The three-way view is still shown for transparency, but the revert itself is always clean via git.

---

### 4. Multi-remote Push

The Phase 3 Push button becomes a **split button** when the project has more than one remote.

**Single-remote repos:** unchanged — one tap pushes to origin.

**Multi-remote repos:**
- Left segment: **Push ↑** — pushes to the currently selected remote
- Right segment: **▾** caret — opens a dropdown listing all remotes (name + URL)
- Dropdown footer: **"Push to all remotes"** — runs push for each remote sequentially
- Selected remote persisted per project in `SharedPreferences`

**Remote list** is fetched once on project load via `GitService.listRemotes()` (parses `git remote -v` output into `List<GitRemote>`). Cached for the session. Split button only renders when `remotes.length > 1`.

---

### 5. PR Review (In-chat Card)

When a PR is created (Phase 3), the assistant message gets a **PR card** appended inline. The card is also emitted when the user asks about an open PR.

#### Card contents

- **Header:** open/merged/closed badge + PR title + PR number
- **Meta row:** `base ← head · N commits · opened X ago`
- **CI checks:** compact chips (✓ / ✗ / ⏳ per check run) — fetched from `GET /repos/:owner/:repo/commits/:sha/check-runs`
- **Review comments:** author + body per comment (truncated to 2 lines, expandable)
- **Footer actions:** ✓ Approve · Merge ↓ · Open on GitHub ↗

#### Live updates

Card polls PR status every 30s while the session is open via `GitHubApiService.getPullRequest(number)`. CI chips and comment list refresh automatically.

#### Actions

| Action | API call |
|---|---|
| Approve | `POST /repos/:owner/:repo/pulls/:number/reviews` with `event: "APPROVE"` |
| Merge | `PUT /repos/:owner/:repo/pulls/:number/merge` (merge commit) |

Approve button replaced with "Approved ✓" label on success. Card badge updates to `merged` after merge.

---

## Files Touched

| File | Change |
|---|---|
| `lib/data/models/tool_event.dart` | New `@freezed` model |
| `lib/data/models/chat_message.dart` | Add `@Default([]) List<ToolEvent> toolEvents` |
| `lib/data/models/applied_change.dart` | Add `contentChecksum` field (SHA-256) |
| `lib/features/chat/widgets/message_bubble.dart` | Render tool-call rows; Diff… button + inline path picker for nameless fences |
| `lib/features/chat/widgets/tool_call_row.dart` | New — collapsed/expanded tool-call card with metrics |
| `lib/features/chat/widgets/pr_card.dart` | New — PR status card (CI chips, comments, Approve/Merge) |
| `lib/features/chat/widgets/conflict_merge_view.dart` | New — three-tab merge view (Original / Applied / Current) |
| `lib/services/apply/apply_service.dart` | Add checksum capture at Apply time; conflict detection + three-way revert logic |
| `lib/services/git/git_service.dart` | Add `listRemotes()` → `Future<List<GitRemote>>`; remote selection persistence |
| `lib/services/github/github_api_service.dart` | Add `getPullRequest`, `getCheckRuns`, `approvePullRequest`, `mergePullRequest` |
| `lib/shell/widgets/top_action_bar.dart` | Split Push button for multi-remote; PR card polling wiring |
| `pubspec.yaml` | Add `crypto` package (SHA-256 checksums) |

---

## Out of Scope for This Phase

- Inline code review comments on individual diff lines — future
- PR checkout (switch to PR branch locally) — future
- Resolving merge conflicts in the PR itself — future
