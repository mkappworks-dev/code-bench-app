# UI Refresh — Design Spec

**Date:** 2026-04-15  
**Design language:** Elevated Glass (dark) + Cool Studio (light)

---

## 1. Overview

A cohesive visual refresh across seven areas, unified by the Elevated Glass design language:
translucent fills with rgba white tints, subtle rgba borders, teal accent (`#4EC9B0`), and
shadow-only depth (no hard structural dividers except the single top-action-bar hairline).

**Scope:**
1. Top action bar
2. Chat area — message bubbles, input bar, status bar
3. App dialog
4. Text fields
5. Settings screen (nav + groups + back button)
6. Branch picker (converted to dialog)
7. Light theme wired to theme switcher

---

## 2. Colour Tokens

All colours are declared in `lib/core/constants/theme_constants.dart`. No hex values are
hardcoded in widgets — always reference a token.

### 2a. Existing dark tokens (unchanged)

| Token | Value | Role |
|---|---|---|
| `background` | `#141414` | Main surface, chat area, chat input wrapper, status bar |
| `activityBar` | `#0A0A0A` | **No longer used for status bar** — remove usage |
| `inputSurface` | `#1A1A1A` | **No longer used for chat box** — replace with frosted tint |
| `deepBorder` | `#222222` | **No longer used as structural divider** — remove usage |
| `borderColor` | `#2A2A2A` | Hard borders — **remove from status bar** |
| `accent` | `#4EC9B0` | Teal accent |
| `accentDark` | `#3AB49A` | Gradient end |
| `frostedSurface` | `rgba(255,255,255,0.025)` | Chat box fill, dialog fill |

### 2b. New dark tokens to add

| Token | Value | Role |
|---|---|---|
| `glassBorder` | `rgba(255,255,255,0.08)` | Chat box outer border |
| `glassBorderSubtle` | `rgba(255,255,255,0.06)` | Dialog outer border, code block border |
| `glassBorderFaint` | `rgba(255,255,255,0.05)` | Internal chip separator, footer separator |
| `chipSurface` | `rgba(255,255,255,0.04)` | Chip / pill fill |
| `chipBorder` | `rgba(255,255,255,0.07)` | Chip / pill border |
| `userBubbleBorder` | `rgba(255,255,255,0.09)` | User message bubble border |
| `userBubbleHighlight` | `rgba(255,255,255,0.07)` | User bubble inner top highlight |
| `topBarSurface` | `rgba(255,255,255,0.02)` | Top action bar background tint |
| `accentGlow` | `rgba(78,201,176,0.07)` | Inner teal rim glow on chat box |
| `accentGlowBadge` | `rgba(78,201,176,0.18)` | Dialog icon badge glow |
| `accentBorderTeal` | `rgba(78,201,176,0.3)` | Branch picker "new branch" button border |
| `accentBorderAmber` | `rgba(232,162,40,0.3)` | Branch picker "new worktree" button border |
| `sendGlow` | `rgba(78,201,176,0.4)` | Send button drop shadow |
| `inlineCodeBg` | `rgba(13,17,23,0.8)` | Inline code background |

### 2c. New light tokens to add

| Token | Value | Role |
|---|---|---|
| `lightBackground` | `#F0F2F5` | App background |
| `lightSurface` | `#FFFFFF` | Cards, dialogs, input surfaces |
| `lightBorder` | `#D4D8DF` | Borders, dividers |
| `lightBorderSubtle` | `rgba(0,0,0,0.06)` | Hairline separators |
| `lightText` | `#2C3138` | Primary text |
| `lightTextSecondary` | `#6B7280` | Secondary / placeholder text |
| `lightTextMuted` | `#9DA5B0` | Disabled / hint text |
| `lightChipSurface` | `rgba(0,0,0,0.04)` | Chip fill |
| `lightChipBorder` | `rgba(0,0,0,0.1)` | Chip border |

---

## 3. Top Action Bar (`lib/shell/widgets/top_action_bar.dart`)

**Goal:** Match Elevated Glass aesthetic — barely-there background tint, glass pill buttons,
unified teal commit button.

### Changes

- **Container background:** `ThemeConstants.topBarSurface` (`rgba(255,255,255,0.02)`)
- **Bottom border:** keep existing hairline (`rgba(255,255,255,0.06)`) — this is the only
  structural divider in the chat screen and is intentional
- **Action buttons** ("+ Actions", "VS Code" dropdowns): wrap each in a glass pill:
  - fill: `ThemeConstants.chipSurface`
  - border: `ThemeConstants.chipBorder`
  - border-radius: `6`
  - text colour: `#9D9D9D`
- **Commit button** (CommitPushButton): merge into a single gradient button:
  - fill: `LinearGradient(135deg, accent → accentDark)`
  - border: none
  - text colour: `#0A0A0A` (background dark)
  - shadow: `BoxShadow(blurRadius: 10, color: rgba(78,201,176,0.35))`

---

## 4. Chat Area

### 4a. Message Bubbles (`lib/features/chat/widgets/message_bubble.dart`)

**User bubble:**
- Fill: `ThemeConstants.frostedSurface` (`rgba(255,255,255,0.025)` — slightly lighter than
  before for contrast against message area)
- Border: `ThemeConstants.userBubbleBorder` (`rgba(255,255,255,0.09)`)
- Inner top highlight: `BoxShadow(inset, 0 1px 0, userBubbleHighlight)`
- Border-radius: `11`

**Inline code spans:**
- Background: `ThemeConstants.inlineCodeBg`
- Border: `1px solid ThemeConstants.glassBorderSubtle`
- Border-radius: `4`
- Colour: `#CE9178` (orange)

**Code blocks (CodeBlockWidget):**
- Background: `#0D1117`
- Border: `1px solid ThemeConstants.glassBorderSubtle`
- Border-radius: `7`

### 4b. Chat Input Bar (`lib/features/chat/widgets/chat_input_bar.dart`)

**Goal:** One continuous `#141414` surface from message list to status bar. The chat box
floats by shadow only. No hard structural borders.

**Outer wrapper (the container around the chat box):**
- Background: `ThemeConstants.background` (`#141414`) — same as message area
- `border: none` — remove the existing `Border(top: BorderSide(color: deepBorder))`
- Padding: `0 12px 10px`

**Gradient fade overlay** (sits between ListView and input wrapper, `IgnorePointer`):
- `Container` height `64px`
- `decoration: BoxDecoration(gradient: LinearGradient(begin: top, end: bottom, colors: [transparent, background]))`
- Positioned at the bottom of the message area, overlapping last message(s)
- `pointer events: none`

**Chat box inner container:**
- Fill: `ThemeConstants.frostedSurface` (`rgba(255,255,255,0.025)`)
- Border: `1px solid ThemeConstants.glassBorder` (`rgba(255,255,255,0.08)`)
- Inner rim glow: `BoxShadow(inset, spread: 0.5, color: accentGlow)`
- Outer shadow: `BoxShadow(blurRadius: 24, offset: 0 6, color: rgba(0,0,0,0.55))` + `BoxShadow(blurRadius: 6, offset: 0 2, color: rgba(0,0,0,0.3))`
- Border-radius: `11`

**Chip separator** (between placeholder text and chips row):
- `Divider(color: ThemeConstants.glassBorderFaint)` — remove the existing `deepBorder` colour

**Control chips** (`_ControlChip`):
- Fill: `ThemeConstants.chipSurface`
- Border: `1px solid ThemeConstants.chipBorder`
- Border-radius: `5`
- Text: `#9D9D9D`
- **Remove** the `_Separator` pipe `|` characters between chips

**Send button:**
- Fill: `LinearGradient(135deg, accent → accentDark)`
- Shadow: `BoxShadow(blurRadius: 8, color: sendGlow)`
- Size: `26×26`, border-radius: `7`
- Icon colour: `#0A0A0A`

### 4c. Status Bar (`lib/shell/widgets/status_bar.dart`)

**Goal:** Remove the second dark band at the bottom of the chat screen.

- **Background:** `ThemeConstants.background` (`#141414`) — was `activityBar` (`#0A0A0A`)
- **Border-top:** `none` — remove entirely; same background means no separator needed
- Height: keep `24px`
- Branch text / icon: keep `ThemeConstants.accent` teal

---

## 5. App Dialog (`lib/core/widgets/app_dialog.dart`)

**Goal:** More refined surface, stronger shadow, icon badge with teal glow, gradient primary
button, faint footer separator.

### Changes

- **Container border-radius:** `13` (was `10`)
- **Background:** `ThemeConstants.frostedSurface`
- **Border:** `1px solid ThemeConstants.glassBorderSubtle`
- **Drop shadow:** `BoxShadow(blurRadius: 64, offset: 0 24, color: rgba(0,0,0,0.9))`
- **Icon badge** (leading icon area, if present):
  - Size: `40×40`, border-radius: `10`
  - Fill: `rgba(78,201,176,0.08)`
  - Border: `1px solid accentBorderTeal`
  - Glow: `BoxShadow(blurRadius: 14, color: accentGlowBadge)`
- **Footer separator:** `Divider(color: ThemeConstants.glassBorderFaint)`
- **Primary action button:**
  - Fill: `LinearGradient(135deg, accent → accentDark)`
  - Shadow: `BoxShadow(blurRadius: 10, color: sendGlow)`
  - Text: `#0A0A0A`, font-weight: `600`
- **Secondary action button:**
  - Fill: `ThemeConstants.chipSurface`
  - Border: `1px solid ThemeConstants.chipBorder`
  - Text: `#9D9D9D`

---

## 6. Text Fields

**Goal:** Consistent Elevated Glass treatment matching the chat box container style.

**`InputDecorationTheme` in `AppTheme.dark`:**
- Filled: `true`
- Fill colour: `ThemeConstants.frostedSurface`
- Enabled border: `OutlineInputBorder(borderSide: BorderSide(color: glassBorderSubtle), borderRadius: 9)`
- Focused border: `OutlineInputBorder(borderSide: BorderSide(color: accent, width: 1.5), borderRadius: 9)`
- Hint style: colour `#444`
- Label style: colour `#9D9D9D`
- Content padding: `EdgeInsets.symmetric(horizontal: 14, vertical: 12)`

---

## 7. Settings Screen

### 7a. Left nav (`lib/features/settings/settings_screen.dart`)

**Active item (`_NavItem`):**
- Fill: `rgba(78,201,176,0.07)` — was no fill
- Border-radius: `0 6px 6px 0` (pill open on the left, touching the nav edge)
- Right margin: `6px` (so the pill doesn't touch the right wall)
- Left accent bar: `3px wide`, colour `accent`, full height of the item

**Inactive item:**
- No fill, no border
- Text colour: `#9D9D9D`

### 7b. Back button

- Replace plain `InkWell` text row with a bordered pill container:
  - Fill: `ThemeConstants.chipSurface`
  - Border: `1px solid ThemeConstants.chipBorder`
  - Border-radius: `6`
  - Padding: `6px 10px`
  - Leading chevron icon: `#9D9D9D`
  - Label: `#9D9D9D`

### 7c. Settings groups (`lib/features/settings/widgets/settings_group.dart`)

**`SettingsGroup` container:**
- Fill: `rgba(255,255,255,0.02)`
- Border: `1px solid ThemeConstants.glassBorderSubtle`
- Border-radius: `9`

**Row dividers (between items inside a group):**
- `Divider(color: ThemeConstants.glassBorderFaint)` — was opaque `#222`

---

## 8. Branch Picker (`lib/features/branch_picker/`)

**Goal:** Convert from `CompositedTransformFollower` overlay popover to an `AppDialog`-style
full dialog. Clearer structure with sections, icons, and footer actions.

### 8a. Dialog chrome (uses `AppDialog` or mirrors its structure)

- Same border-radius `13`, frosted surface, drop shadow as §5
- Fixed width: `440px`, max-height: `560px` — dialog is scrollable internally

### 8b. Header

- Left: branch-picker icon badge (git-branch SVG, teal, `accentGlowBadge` glow)
- Centre: title "Switch Branch" (or "Branches & Worktrees")
- Right: ✕ close button (`#555`, hover `#D4D4D4`)
- Below title: subtitle showing current branch/worktree name in `accent` teal

### 8c. Search bar

- Full-width `TextField` styled per §6 (Elevated Glass)
- Leading icon: magnifier, `#555`
- Placeholder: "Search branches…"
- Clears the list live (client-side filter only)

### 8d. Branch/worktree list

- Fixed height: `240px`, scrollable `ListView`
- **Section headers:** "BRANCHES" / "WORKTREES" in `#555`, `8px`, uppercase, letter-spacing `0.5px`
- **Branch row:**
  - Leading icon: git-branch SVG (`14×14`, colour `accent` if current, else `#555`)
  - Label: branch name `#D4D4D4`
  - Active indicator: `3px` left accent bar, `accent` colour + `BoxShadow` dot glow on icon
  - Right: `CheckIcon` if current branch
- **Worktree row:**
  - Leading icon: layers SVG (`14×14`, colour `#E8A228` amber if that worktree is checked out, else `#555`)
  - Label: worktree name `#D4D4D4`
  - Right: "worktree" badge pill (`rgba(232,162,40,0.08)` fill, `accentBorderAmber` border, amber text)
- Row height: `36px`, hover fill `rgba(255,255,255,0.03)`
- No dividers between rows — use spacing only

### 8e. Footer (two action buttons)

Both buttons share the same layout: glass body, coloured border, coloured icon, neutral label.

| Button | Border colour | Icon | Label |
|---|---|---|---|
| New Branch | `accentBorderTeal` | git-branch SVG, `accent` | "New Branch" `#E8E8E8` |
| New Worktree | `accentBorderAmber` | layers SVG, `#E8A228` | "New Worktree" `#E8E8E8` |

Button spec:
- Fill: `rgba(255,255,255,0.03)`
- Border: `1px solid <coloured border above>`
- Border-radius: `7`
- Padding: `8px 14px`
- Buttons sit side-by-side with `8px` gap; equal width

### 8f. Create flows (inline, replace dialog content)

Tapping "New Branch" or "New Worktree" replaces the dialog body (not a new dialog):

**New Branch create state:**
- Header: back arrow (←) + "New Branch" title (same ✕ close)
- Single `TextField` (§6): placeholder "branch-name"
- Action: teal gradient "Create Branch" button (full width)

**New Worktree create state:**
- Header: back arrow (←) + "New Worktree" title
- Two `TextField`s (§6): "Branch name" + "Path" (auto-filled `.worktrees/<branch-name>` as
  user types; editable)
- Action: amber-tinted "Create Worktree" button (fill `rgba(232,162,40,0.08)`, border
  `accentBorderAmber`, full width)

---

## 9. Light Theme

### 9a. `AppTheme.light` (`lib/core/theme/app_theme.dart`)

Mirror `AppTheme.dark` structure with Cool Studio tokens (§2c):

| Property | Light value |
|---|---|
| `scaffoldBackgroundColor` | `lightBackground` (`#F0F2F5`) |
| `colorScheme.surface` | `lightSurface` (`#FFFFFF`) |
| `colorScheme.primary` | `accent` (`#4EC9B0`) |
| `colorScheme.onPrimary` | `#FFFFFF` |
| `colorScheme.onSurface` | `lightText` (`#2C3138`) |
| Dialog background | `lightSurface` |
| `InputDecorationTheme` fill | `lightSurface` |
| `InputDecorationTheme` border | `lightBorder` |
| Hint colour | `lightTextMuted` |
| Divider colour | `lightBorder` |

Top bar, status bar, chat box borders adapt automatically via `Theme.of(context)` lookups.
Any widget currently reading a `ThemeConstants` dark token directly must be updated to
read from `Theme.of(context).colorScheme` or a resolved token helper.

### 9b. `GeneralPrefs` — theme field (`lib/data/settings/`)

Add a `themeMode` column (enum: `system`, `dark`, `light`) to the `GeneralPrefs` Drift
table. Default: `system`.

Expose `setThemeMode(ThemeMode mode)` on the `GeneralPrefsNotifier`.

### 9c. Theme switcher wiring

In `GeneralScreen` (settings), replace the current no-op dropdown `onChanged: (_) {}` with:
```dart
onChanged: (value) =>
    ref.read(generalPrefsProvider.notifier).setThemeMode(value),
```

In `main.dart` / the root `MaterialApp.router`, watch `generalPrefsProvider` and pass the
resolved `ThemeMode` to `themeMode:`, `theme: AppTheme.light`, `darkTheme: AppTheme.dark`.

---

## 10. File Change Summary

| File | Change type |
|---|---|
| `lib/core/constants/theme_constants.dart` | Add new dark + light tokens |
| `lib/core/theme/app_theme.dart` | Add `AppTheme.light`, update `InputDecorationTheme` |
| `lib/shell/widgets/top_action_bar.dart` | Glass buttons, gradient commit button, bg tint |
| `lib/features/chat/widgets/message_bubble.dart` | Bubble fill/border, inline code border, code block border |
| `lib/features/chat/widgets/chat_input_bar.dart` | Remove hard border/bg band, gradient fade, floating box style, chip style, send button |
| `lib/shell/widgets/status_bar.dart` | Background `#141414`, border removed |
| `lib/core/widgets/app_dialog.dart` | Larger radius, stronger shadow, icon badge glow, footer separator, gradient primary button |
| `lib/features/settings/settings_screen.dart` | Active nav accent bar + fill, back button pill |
| `lib/features/settings/widgets/settings_group.dart` | Glass container, hairline row dividers |
| `lib/features/settings/general_screen.dart` | Wire theme dropdown to `setThemeMode` |
| `lib/features/branch_picker/widgets/branch_picker_popover.dart` | Full redesign → dialog-style |
| `lib/data/settings/` (Drift table) | Add `themeMode` column to `GeneralPrefs` |
| `main.dart` | Pass `theme`, `darkTheme`, `themeMode` to `MaterialApp.router` |
