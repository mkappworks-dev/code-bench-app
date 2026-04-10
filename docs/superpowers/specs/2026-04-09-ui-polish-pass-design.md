# Code Bench — UI Polish Pass (Phase 1)

## Overview

Tighten the chat-first UI to match the approved design direction. This pass covers five originally-scoped consistency fixes plus expanded UI improvements identified on 2026-04-09. It also introduces Archive as a full feature (DB migration + UI).

This is Phase 1 of a three-phase UI improvement queue. Phases 2 (tool-call cards, diff views) and 3 (stub button functionality) are separate follow-up specs.

---

## Decisions Made

### 1. Icon library

**Package:** `lucide_icons_flutter` (pub.dev)

Replace all Material icons (`Icons.*`) across the app with Lucide stroke icons from this package. Lucide icons use 1.8–2px stroke weight, rounded linecaps, and a consistent geometric grid. No SVG asset files needed — the package provides `IconData`-compatible objects.

Affected files: `message_bubble.dart`, `top_action_bar.dart`, `status_bar.dart`, `project_sidebar.dart`, `project_tile.dart`, `conversation_tile.dart`, `chat_input_bar_v2.dart`, `settings_screen.dart`.

### 2. Message layout

**User messages:** Right-aligned bubble. `max-width: 82%`, `border-radius: 10px`, background `ThemeConstants.userMessageBg` (`#1E1E1E`), padding `9px 13px`, font size 12px. Aligned to the trailing edge of the chat column.

**Assistant messages:** Flat full-width text. No background, no border-radius. Left accent: `2px` solid border in `ThemeConstants.borderColor` (`#2A2A2A`), `padding-left: 9px`. Font size 12px, line-height 1.65.

**No avatars.** No role labels ("You" / "Assistant"). Role is communicated entirely by position (right = user, left-border = assistant).

**Streaming indicator:** Replace `CircularProgressIndicator` with a small pulsing dot (`6×6px`, color `ThemeConstants.success`, animated opacity 0.3→1→0.3 on a 1.2s loop).

### 3. Color tokens

Centralise all raw `Color(0xFF...)` literals into `ThemeConstants`. Add four missing tokens:

| Token | Value | Semantic use |
|---|---|---|
| `inputSurface` | `#1A1A1A` | Input box, card surfaces, button backgrounds |
| `deepBorder` | `#222222` | Input box border, separator lines |
| `mutedFg` | `#555555` | Section labels, muted text, icon color |
| `faintFg` | `#333333` | Timestamp text, dropdown carets |

After adding these, replace every inline `Color(0xFF1A1A1A)`, `Color(0xFF222222)`, `Color(0xFF555555)`, `Color(0xFF333333)` in widget files with the corresponding constant.

Existing tokens already in `ThemeConstants` that are also under-used:
- `activityBar` (`#0A0A0A`) — use for sidebar background, status bar background
- `inputBackground` (`#111111`) — use for top action bar background
- `panelBackground` (`#1E1E1E`) — use for user message bubble, context menu background
- `borderColor` (`#2A2A2A`) — use for all border/divider lines
- `textMuted` (`#666666`) → rename to `textFaint` to avoid collision with new `mutedFg` **or** consolidate — see implementation note below

**Implementation note:** `ThemeConstants.textMuted` is currently `#666666` and `mutedFg` above is `#555555`. Keep both — they serve different roles (`textMuted` for body secondary text, `mutedFg` for icon/label chrome).

### 4. Typography scale

**Body text (messages, sidebar conversation titles):** 12px  
**Secondary UI (chips, button labels, top bar title):** 11px  
**Labels / muted (section headers, timestamps, badge text):** 10px  
**Badges (git tag, provider badge):** 9px  
**Code blocks:** 13px (`ThemeConstants.editorFontSize` — unchanged)

Update `ThemeConstants`:
- `uiFontSize`: `13` → `12`
- `uiFontSizeSmall`: `11` (unchanged)
- Add `uiFontSizeLabel = 10`
- Add `uiFontSizeBadge = 9`

Cascade through all widget files — replace any hardcoded font size literal with the appropriate constant.

### 5. Route transitions

Disable slide animations on all GoRouter routes. Set `customTransitionPage` with a zero-duration fade or use `Page` with no transition. Screen switches must be instant — no slide-in, no fade delay.

---

## Top Action Bar

Height: 38px. Background: `ThemeConstants.inputBackground` (`#111111`). Bottom border: `ThemeConstants.borderColor`.

**Left side:** Conversation title (12px, `textPrimary`) + project name badge (10px, `mutedFg`, bg `inputSurface`, `border-radius: 4px`) + git status badge:
- Git repo: omitted (git status communicated by the sidebar icon only)
- Not a git repo: amber `No Git` badge (10px, `#E8A228`, bg `#2A1F0A`, `border-radius: 4px`)

**Right side (left to right):**

1. **`+ Add action`** — text button with Lucide `plus` icon. Opens a dialog to register a named shell command for this project. Background `inputSurface`, border `deepBorder`.

2. **`VS Code ↓`** — text button with VS Code icon + dropdown caret. Dropdown menu contains:
   - VS Code (with icon) — opens project folder in VS Code
   - Cursor (with icon) — opens project folder in Cursor
   - *(separator)*
   - Open in Finder (with Lucide `folder-open` icon) — reveals folder in Finder (shortcut: `⌘O`)

3. **Git action button — two states:**
   - **Git repo:** `Commit & Push ↓` split button. Left side: Lucide `git-commit` icon + "Commit & Push" label, blue accent background. Right side: dropdown caret (same blue background, separated by a 1px darker border). Dropdown contains: Commit / Push / Create PR.
   - **Not a git repo:** `Initialize Git` button (same size/style as a plain action button, `inputSurface` background). Tapping runs `git init` and swaps this button to the full Commit & Push split button immediately (Phase 3).

4. ~~Terminal toggle icon~~ — removed. Terminal access is via "Open Terminal" in the "VS Code ↓" IDE dropdown (Phase 3). No icon in the top bar.

---

## Project Sidebar

### Sidebar header

"PROJECTS" label (10px, `mutedFg`, uppercase, `letter-spacing: 0.8px`) + two icon buttons (right-aligned): Lucide `arrow-up-down` (sort) and Lucide `plus` (add project).

### Sort dropdown

Tapping the sort icon opens a dropdown anchored below the icon. Two sections:

**Sort projects:**
- Last user message *(default, checkmark)*
- Created at
- Manual

**Sort threads:**
- Last user message *(default, checkmark)*
- Created at

Sort state is persisted across app restarts (use `shared_preferences` or a `keepAlive` Riverpod notifier backed by `SharedPreferences`). Changing sort order immediately re-sorts the visible list — no confirmation needed.

"Manual" sort for projects enables drag-to-reorder in the sidebar. When Manual is selected, project rows show a Lucide `grip-vertical` handle on the left. Drag order is persisted to the `WorkspaceProjects.sortOrder` column (already exists in the schema).

### Project tile row

`[chevron ▼/▶] [folder icon] [project name] [spacer] [new-chat icon] [git icon]`

- **Chevron:** Lucide `chevron-down` (expanded) / `chevron-right` (collapsed). Color `faintFg`.
- **Folder icon:** Lucide `folder`, color `textSecondary`.
- **Project name:** 12px, `textPrimary`, `font-weight: 500`, truncated with ellipsis.
- **New-chat icon:** Lucide `message-square-plus`, color `mutedFg`. Tapping creates a new conversation under this project. Shows on hover only (opacity 0 → 1) to reduce clutter.
- **Git icon:** Lucide `git-branch`.
  - Git repository: color `ThemeConstants.success` (`#4EC9B0`), tooltip = current branch name.
  - Not a git repository: color `faintFg` (`#333333`), no tooltip.
  - **No text tag.** Remove the pill/badge entirely. The icon color alone communicates git status.

### Conversation tile

Unchanged from current spec, except: font size 11px (down from 12px per typography scale).

---

## Input Bar

The four chips in the controls row all become functional dropdowns, anchored to their respective chip:

| Chip | Current | Dropdown options |
|---|---|---|
| Model | Shows selected model name | Full `AIModels.defaults` list, grouped by provider |
| Effort | Static "High" | Low / Medium / High (default) / Max |
| Mode | Static "Chat" | Chat / Plan / Act |
| Permissions | Static "Full access" | Read only / Ask before changes / Full access |

Dropdown menus: background `panelBackground` (`#1E1E1E`), border `#333`, `border-radius: 7px`, `box-shadow: 0 6px 24px rgba(0,0,0,0.6)`. Active selection shows a Lucide `check` icon on the right. Item font size 11px.

The model picker dropdown replaces the existing `showMenu` call (which positions at `RelativeRect.fromLTRB(0,0,0,0)` — a hardcoded position). The new dropdown opens anchored **above** the chip using `showInstantMenu` (see `lib/core/utils/instant_menu.dart`), a zero-animation `PopupRoute` subclass. `RelativeRect.top = origin.dy` (button top); `_MenuLayout` places the menu at `y = origin.dy − menuHeight` so the menu bottom sits at the button top without overlap.

> **As implemented:** `PopupMenuButton` was not used. All chip menus (`effort`, `mode`, `permission`, `model`) use the shared `showInstantMenu` utility — a custom `PopupRoute<T>` with `transitionDuration: Duration.zero` that handles positioning via `_MenuLayout` (`SingleChildLayoutDelegate`). `PopupMenuThemeData.popUpAnimationStyle` (Flutter 3.16+) was unavailable on the project's Flutter version.

---

## Settings Screen

The settings screen is redesigned to a two-pane layout:

### Left navigation

Width: 200px. Background: `activityBar` (`#0A0A0A`). Border-right: `borderColor`.

Contents (top to bottom):
- "Settings" title (13px, `textPrimary`, `font-weight: 600`)
- Nav item: General (Lucide `settings` icon) — active by default
- Nav item: Providers (Lucide `message-square` icon)
- Nav item: Archive (Lucide `archive` icon)
- *(spacer)*
- "← Back" link at bottom (returns to main chat)

Active nav item: background `inputSurface`, color `textPrimary`. Inactive: color `textSecondary`.

### Settings header bar

A thin top bar spans the full settings screen (both panes). Right-aligned: "↺ Restore defaults" text button (11px, `textSecondary`). Tapping shows a confirmation dialog before resetting all settings to defaults.

### Content area

Background: `sidebarBackground` (`#111111`). Padding: `20px 24px`.

Content is grouped into sections. Each section has:
- Section header: 10px, uppercase, `mutedFg`, `letter-spacing: 0.8px`
- Rows: stacked with connected borders (top row: `border-radius: 8px 8px 0 0`, bottom row: `border-radius: 0 0 8px 8px`, middle rows: no radius, adjacent borders collapsed)

**General section rows:**

| Label | Description | Control |
|---|---|---|
| Theme | How Code Bench looks | Dropdown: Dark / Light / System |
| Ollama base URL | Base URL for local Ollama | Editable text field |
| Delete confirmation | Ask before deleting a session | Toggle |
| Auto-commit | Skip commit dialog and commit immediately with AI-generated message | Toggle (synced with the toggle in the Commit dialog — same `SharedPreferences` key) |
| Terminal app | App to open when "Open Terminal" is tapped in the IDE dropdown | Editable text field, default `"Terminal"` (e.g. `"iTerm"`, `"Warp"`) |

**Providers section rows:**

One row per AI provider. Each row:
- Status dot (5×5px circle): `success` green = authenticated/running, `error` red = not configured
- Provider name (12px, `textPrimary`, `font-weight: 500`) + version string if available
- Status description (11px, `textSecondary`)
- Lucide `chevron-down` expand icon (reveals API key input when tapped)
- Toggle (enable/disable provider)

Providers: Anthropic, OpenAI, Gemini, Ollama, Custom endpoint.

**About section rows:**

| Label | Description | Control |
|---|---|---|
| Version | Current app version | Version string + "Up to Date" badge |

### Archive screen

Selecting "Archive" in the left nav shows the Archive screen.

**Layout:** Sessions grouped by project. Each project is a section with a header showing the project name in uppercase (10px, `mutedFg`, Lucide `folder` icon before the name).

**Archived session card:**
- Full-width card, background `#141414`, border `borderColor`, `border-radius: 8px`
- Title: session title truncated (12px, `textPrimary`, `font-weight: 500`)
- Subtitle: "Archived Xm ago · Created Xh ago" (11px, `textSecondary`)
- **Unarchive button** (right-aligned): Lucide `archive-restore` icon + "Unarchive" label, bordered button style

**Empty state:** If no archived sessions, show centered Lucide `archive` icon (32px, `mutedFg`) + "No archived conversations" label.

### Archive data model changes

Add `isArchived` boolean column (default `false`) to the `ChatSessions` Drift table.

- Increment `schemaVersion` and add migration step.
- `SessionDao.watchAllSessions()` filters `WHERE isArchived = false` (active sessions only).
- Add `SessionDao.watchArchivedSessions()` — returns sessions where `isArchived = true`, ordered by `updatedAt` descending, grouped by `projectId`.
- Add `SessionDao.archiveSession(String id)` and `unarchiveSession(String id)`.

Archiving a session is triggered from the conversation tile context menu (right-click): add "Archive" item above "Delete". Archived sessions disappear from the sidebar immediately.

---

## Files Touched

| File | Changes |
|---|---|
| `pubspec.yaml` | Add `lucide_icons_flutter` (`shared_preferences` already present) |
| `analysis_options.yaml` | Add `formatter: page_width: 120` — Dart 3.4+ reads this automatically *(added during impl)* |
| `lib/core/constants/theme_constants.dart` | Add 4 tokens, update `uiFontSize`, add `uiFontSizeLabel`, `uiFontSizeBadge` |
| `lib/core/utils/instant_menu.dart` | **New** — `showInstantMenu<T>`: zero-animation `PopupRoute` drop-in for `showMenu` *(added during impl)* |
| `lib/router/app_router.dart` | Disable route transition animations |
| `lib/features/chat/widgets/message_bubble.dart` | Full redesign — right-align user, flat assistant, pulsing dot, Lucide icons |
| `lib/features/chat/widgets/chat_input_bar_v2.dart` | Lucide icons, `showInstantMenu` dropdowns for all 4 chips, `_keyboardFocusNode` memory fix, `mounted` guard |
| `lib/features/chat/widgets/message_list.dart` | Typography token cleanup |
| `lib/shell/widgets/top_action_bar.dart` | New button order, VS Code + Cursor + Finder + Terminal dropdown, Commit split button |
| `lib/shell/widgets/status_bar.dart` | Lucide icons, token cleanup |
| `lib/features/project_sidebar/project_sidebar.dart` | Lucide icons, sort icon + `showInstantMenu` sort dropdown, token cleanup |
| `lib/features/project_sidebar/widgets/project_tile.dart` | Icon-only git badge, new-chat icon, Lucide icons, typography |
| `lib/features/project_sidebar/widgets/project_context_menu.dart` | Switch to `showInstantMenu`; remove "Rename project" *(moved to conversation menu — see below)* |
| `lib/features/project_sidebar/widgets/conversation_tile.dart` | Typography token cleanup + right-click context menu with **Rename** and **Delete** (`onRename`/`onDelete` callbacks; dialogs wired in Phase 3) |
| `lib/features/project_sidebar/project_sidebar_notifier.dart` | Add sort state (projects + threads), persist via SharedPreferences |
| `lib/features/settings/settings_screen.dart` | Full redesign — two-pane layout, section rows, provider rows, Restore defaults |
| `lib/features/settings/archive_screen.dart` | New file — archived sessions grouped by project, Unarchive action |
| `lib/data/datasources/local/app_database.dart` | Add `isArchived` to `ChatSessions`, bump `schemaVersion`, add migration, add archive/unarchive DAO methods |

---

## Out of Scope for This Pass

- Tool-call cards and changes summary block (Phase 2)
- Functional implementations of Add action dialog, VS Code/Cursor/Terminal launch, Commit/Push/Pull/Create PR (Phase 3)
- Rename project dialog (Phase 3)
- Onboarding screen changes (Phase 4)

---

## Mockup References

Visual mockups for this design are saved in:
`.superpowers/brainstorm/74891-1775762953/content/`
- `full-design-v2.html` — full app composite with all changes
- `topbar-v2.html` — top action bar button order and detail
- `design-before-after.html` — before/after comparison
