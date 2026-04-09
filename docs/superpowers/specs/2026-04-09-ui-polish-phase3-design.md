# Code Bench — UI Polish Phase 3: Stub Button Functionality

## Overview

Phase 3 makes the stub buttons from Phase 1 functional. Covers: VS Code/Cursor/Finder launch, Rename project dialog, Add action (register + run with floating output panel), Commit (AI-generated message with dialog and auto-commit toggle), Push, and Create PR (AI-generated title/body).

All git operations shell out via `Process.run`/`Process.start` using the project path. The existing `GitHubApiService` handles PR creation. The existing `GitDetector` handles git detection — a new `GitService` handles git operations.

The terminal pane is out of scope for this phase — deferred to Phase 6.

This is Phase 3 of a three-phase UI improvement queue. Phases 1 and 2 are separate specs.

---

## Decisions Made

### 1. VS Code / Cursor / Finder Launch

Three `Process.run` calls from the top bar "VS Code ↓" dropdown:

| Action | Command |
|---|---|
| VS Code | `Process.run('code', [projectPath])` |
| Cursor | `Process.run('cursor', [projectPath])` — falls back to `open -a Cursor <path>` if `cursor` CLI not on PATH |
| Open in Finder | `Process.run('open', [projectPath])` |

If the CLI is not found: toast — *"VS Code CLI not found — install it from the Command Palette (Shell Command: Install 'code' in PATH)"*.

**New service: `IdeLaunchService`** — thin Riverpod-injected wrapper around the three launch calls.

### 2. Rename Project Dialog

Triggered from the project tile right-click context menu (same menu as Delete and Archive).

- Small dialog anchored near the project tile
- Single text field pre-filled with the current project name
- **Rename** (primary) and **Cancel** buttons
- Validation: non-empty, max 60 chars, trims whitespace
- On confirm → `ProjectDao.upsertProject` with new name → sidebar updates immediately

No new service needed — uses existing `ProjectDao`.

### 3. Add Action

**Registering:**

"+ Add action" opens a dialog:
- **Name** field (e.g. `Run tests`) — max 40 chars
- **Command** field (e.g. `flutter test`) — shell command to run in the project directory
- **Save** and **Cancel** buttons

Actions are persisted per project as a JSON column (`actionsJson`) on `WorkspaceProjects`. Stored as `List<{name: String, command: String}>`. No new table — actions are small enough to live in the existing row.

Schema change: add `actionsJson` text column (default `'[]'`) to `WorkspaceProjects`. This migration must be combined with Phase 1's `isArchived` migration into a single `schemaVersion` bump (both land in the same implementation PR).

Saved actions appear as chips in the top bar "+" dropdown. Tapping a chip runs the command.

**Running:**

A floating output panel anchors below the top bar:
- Header: action name + status indicator (`● Running` / `✓ Done (exit 0)` / `✗ Failed (exit N)`) + close ×
- Body: monospace scrollable stdout/stderr stream, 13px, `codeBlockBg` background
- Process launched via `Process.start` (streaming, non-blocking)
- Panel stays open after process exits until user closes it
- Running a second action while one is active kills the first process and starts fresh

**New service: `ActionRunnerService`** — wraps `Process.start`, streams output chunks to a `keepAlive` Riverpod `StateNotifier` (`ActionOutputNotifier`).

### 4. Commit

Triggered from the left side of the "Commit & Push" split button.

**Flow:**
1. Collect changed files from `AppliedChangesNotifier` (Phase 2) + last 10 messages from the active session
2. Send short prompt to active AI model: *"Write a conventional commit message (subject line only, max 72 chars) summarising these changes: [file list + conversation summary]"*
3. Commit dialog opens with AI-generated message pre-filled in an editable text field
4. **⚡ Auto-commit** toggle in dialog footer — persisted via `SharedPreferences`. When on, future commits skip the dialog entirely. Also exposed as a row in Settings → General (same `SharedPreferences` key — both controls stay in sync)
5. User edits if needed → clicks **Commit**
6. Runs `git add -A && git commit -m "<message>"` via `GitService`
7. Success: toast *"Committed — [short sha]"*. Failure: toast with git error output

**Auto-commit mode** (toggle on): skips dialog — AI generates message, commit runs immediately, toast appears.

### 5. Push

Triggered from "Push" in the Commit & Push dropdown. No confirmation dialog — one-tap.

**Flow:**
1. Shows `● Pushing…` in status bar while in progress
2. Runs `git push` via `GitService`
3. Success: toast *"Pushed to origin/[branch]"*
4. Failure: friendly error toasts for common cases:
   - No upstream → *"No upstream branch. Run `git push -u origin [branch]` in your terminal."*
   - Auth failure → *"Push failed — check your git credentials."*
   - Other → raw git error output

### 6. Create PR

Triggered from "Create PR" in the Commit & Push dropdown.

**Flow:**
1. Check GitHub token via `SecureStorageSource` — if missing, toast *"Connect GitHub in Settings → Providers"* and stop
2. Detect current branch via `GitDetector.getCurrentBranch` — if on `main`/`master`, warn *"You're on the default branch — create a feature branch first."*
3. Collect changed files + last 10 messages; send prompt to active AI model to generate PR title (max 70 chars) and bullet-point body
4. PR dialog opens with pre-filled **Title** and **Description** fields (both editable)
5. **Base branch** selector — defaults to `main`, populated from `GitHubApiService.listBranches`
6. **Draft PR** toggle — off by default
7. User edits → clicks **Create PR** → calls `GitHubApiService.createPullRequest` → on success opens PR URL in browser via `Process.run('open', [prUrl])`
8. Failure: toast with API error message

---

## New Services

| Service | Responsibility |
|---|---|
| `IdeLaunchService` | VS Code / Cursor / Finder `Process.run` calls |
| `GitService` | Async git operations: `commit`, `push`, `status`, `currentBranch` |
| `ActionRunnerService` | `Process.start` wrapper, streams output to `ActionOutputNotifier` |

`GitDetector` is unchanged — it handles sync detection only.

---

## Files Touched

| File | Changes |
|---|---|
| `pubspec.yaml` | No new packages needed |
| `lib/data/datasources/local/app_database.dart` | Add `actionsJson` column to `WorkspaceProjects`, bump `schemaVersion`, add migration |
| `lib/services/ide/ide_launch_service.dart` | New — VS Code / Cursor / Finder launch |
| `lib/services/git/git_service.dart` | New — async git commit, push, status |
| `lib/services/actions/action_runner_service.dart` | New — `Process.start` wrapper + `ActionOutputNotifier` |
| `lib/shell/widgets/top_action_bar.dart` | Wire VS Code/Cursor/Finder dropdown, Add action dialog + chips, Commit & Push split button flows |
| `lib/shell/widgets/action_output_panel.dart` | New — floating output panel widget |
| `lib/features/project_sidebar/widgets/project_tile.dart` | Add Rename item to right-click context menu |
| `lib/features/project_sidebar/widgets/rename_project_dialog.dart` | New — rename dialog widget |
| `lib/features/chat/widgets/commit_dialog.dart` | New — commit message dialog with auto-commit toggle |
| `lib/features/chat/widgets/create_pr_dialog.dart` | New — PR title/body/base-branch/draft dialog |

---

## Out of Scope for This Phase

- Terminal pane (Phase 6 — deferred, needs its own design pass)
- Pushing to non-origin remotes or multiple remotes (Phase 5)
- PR review or merge flows (Phase 5)
- Running Add actions in the terminal pane (Phase 6 integration)
