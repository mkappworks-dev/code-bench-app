# Code Bench — Chat-First Redesign

## Overview

Redesign Code Bench from an editor-centric (VS Code-style) layout to a chat-first interface where the conversation is the primary workspace. Projects organize conversations by local folder, with automatic git detection.

## Design Decisions

### 1. Layout Architecture

**Chat-first.** The entire right panel is a full-screen chat. There is no separate editor pane, file explorer panel, or multi-pane split layout. All code appears inline in chat messages.

The app has three horizontal zones:
- **Left:** Sidebar (projects + conversations)
- **Right:** Chat panel (top bar + messages + input + status bar)
- The top action bar spans only the right panel, not the sidebar

### 2. Sidebar

The sidebar lists projects. Each project is collapsible (chevron toggle) and contains a list of conversation threads.

**Project row contents:**
- Chevron (▶/▼) for collapse/expand
- Folder icon (SVG, Lucide-style)
- Project name (the folder's basename — no full path shown)
- Git tag: branch name if git repo, "Not git" otherwise

**No folder path is displayed** in the sidebar. The path is accessible via the right-click context menu.

**Conversation row contents:**
- Status dot (blue = Working, green = Completed, none = idle)
- Status label ("Working" / "Completed") when applicable
- Conversation title (truncated with ellipsis)
- Relative time ("2m", "1h", "3h", "1d")

**Sidebar header:** "PROJECTS" label with sort and add (+) buttons.

**Sidebar footer:** Settings link at the bottom.

### 3. Right-Click Context Menu (Projects)

Right-clicking a project in the sidebar shows:
- **Open in Finder** — reveals the folder in the OS file manager
- **Copy path** (⌘⇧C) — copies the full folder path to clipboard
- **Rename project** — edit the display name
- **New conversation** — creates a new chat under this project
- *(separator)*
- **Remove from Code Bench** (red/danger) — unlinks the project from the app. Does NOT delete the folder from disk.

### 4. Project Model

A project is a reference to a local directory on disk.

**Creating a project:**
- **Open existing folder** — native file picker to select a directory
- **Create new folder** — name it, pick a parent location, Code Bench creates the directory and registers it as a project

**Git detection:** On project creation (and periodically), Code Bench checks if the folder is a git repository. If yes, it reads the current branch name and displays it in the sidebar git tag. If no, it shows "Not git".

**Removing a project:** Only removes the reference from Code Bench's project list. The folder and all its contents remain on disk untouched.

### 5. Top Action Bar

Spans only the right panel. Contains:
- **Conversation title** (left-aligned)
- **Project name badge** (muted tag next to title)
- **Action buttons** (right-aligned):
  - **Add action** — extensible action menu
  - **Open** — open the project folder (in Finder/file manager)
  - **Commit & Push** — for git projects; should prompt for review before committing

### 6. Chat Messages

Standard chat layout with user messages (bubble style) and assistant messages (flat text).

**Assistant messages can contain:**
- Plain text with markdown rendering
- Inline code blocks with syntax highlighting
- Tool-call cards (see below)
- Changes summary block (see below)

### 7. Tool-Call Cards

During the AI's work, actions are displayed as a compact block within the assistant message:

```
┌─ TOOL CALLS (4) ─────────────────────────────┐
│ ● Read complete    lib/middleware/auth.dart    │
│ ● Read complete    lib/models/token.dart       │
│ ● Edit complete    lib/middleware/auth.dart  +12 -3 │
│ ● Write complete   lib/models/auth_error.dart  +24  │
└───────────────────────────────────────────────┘
```

Each row shows:
- Green status dot (SVG circle)
- Action type: Read / Edit / Write / complete
- File path (monospace)
- Line change stats for Edit/Write (+additions, -deletions)

### 8. Changes Summary Block

Appears at the end of an assistant message that modified files. This is the primary way users review code changes.

**Header:** "Changes" title, file count badge, total +/- stats.

**File list:** Each file row shows:
- Chevron for expand/collapse
- Badge: M (modified, yellow), A (added, green), D (deleted, red)
- File path (monospace)
- Per-file +/- stats

**Expanded diff view:** Clicking a file row expands it to show the diff inline. A toggle button switches between:
- **Inline view** — unified diff with green (added) and red (deleted) lines, line numbers, colored left border
- **Side-by-side view** — Before | After columns

### 9. Input Bar

The text input area contains:
- **Text field** with placeholder: "Ask anything, @tag files/folders, or use /command"
- **Controls row** (below the text field, separated by a border):
  - Model selector (e.g., "Claude 3.5 Sonnet") with dropdown
  - Effort level (e.g., "High") with dropdown
  - Mode (e.g., "Chat") — for future expansion
  - Permission level (e.g., "Full access") — for future expansion
- **Send button** (blue circle with up-arrow)

All controls use SVG icons (bolt, chat bubble, lock) and dropdown carets.

### 10. Status Bar

Thin bar at the very bottom of the right panel:
- **Left:** Folder icon + "Local" label
- **Right:** Green dot + branch name + dropdown caret

Shows git branch for git projects. For non-git projects, the right side can show "Not git" or be empty.

### 11. Visual Design

**Icons:** All Lucide-style SVG stroke icons. 1.8–2px stroke weight. Monochrome, inheriting text color from their container. No emoji anywhere in the UI.

**Typography:**
- System font (SF Pro / Helvetica Neue / sans-serif) for all UI text
- JetBrains Mono for code blocks, file paths, and monospace elements
- Sizes: 12px body, 11px secondary, 10px labels/muted, 9px badges

**Color palette:** Retained from current Code Bench dark theme:
- Backgrounds: #0a0a0a (deepest), #111 (sidebar/panels), #141414 (chat), #1a1a1a (input), #1e1e1e (cards)
- Text: #d4d4d4 (primary), #888/#9d9d9d (secondary), #555/#666 (muted), #333/#444 (faint)
- Accent: #007acc (blue), #4ec9b0 (green/success), #f44747 (red/error), #cca700 (yellow/warning)
- Borders: #1e1e1e (subtle), #2a2a2a (visible)

## What Gets Removed

The following features from the current editor-centric layout are removed:
- **Side nav rail** (Dashboard, Chat, Editor, GitHub, Compare, Settings icons) — replaced by sidebar
- **File explorer panel** — no standalone file browser
- **Editor pane** (code editor with file tabs) — code lives in chat
- **Chat side panel** — chat is now the main area, not a panel
- **Dashboard screen** — projects sidebar replaces it
- **Compare screen** — can be revisited later as a chat feature
- **Resizable pane dividers** — single-panel layout, no splits

## What Gets Retained/Adapted

- **Theme constants and color palette** — reused as-is
- **Chat notifier and session service** — conversation management logic stays
- **AI service layer** — streaming, model selection, API key management
- **Drift database** — session storage, message history
- **Onboarding flow** — API key setup remains
- **Settings screen** — accessed from sidebar footer instead of nav rail
- **Keyboard shortcuts** — adapted for new layout (⌘N for new chat, etc.)

## Data Model Changes

### New: Project

```
Project {
  id: String (UUID)
  name: String (display name, defaults to folder basename)
  path: String (absolute path to folder)
  isGit: bool (auto-detected)
  currentBranch: String? (null if not git)
  createdAt: DateTime
  sortOrder: int
}
```

### Modified: ChatSession

Add a `projectId` field linking each conversation to a project:

```
ChatSession {
  ...existing fields...
  projectId: String (FK to Project.id)
}
```

## Mockups

Visual mockups are available in `.superpowers/brainstorm/12518-1775667520/content/`:
- `full-composite-v4.html` — final approved composite layout
- `code-diffs-v2.html` — tool-call cards + changes summary pattern
- `layout-direction.html` — initial layout options explored
