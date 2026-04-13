# Code Bench — Theme & Branding Redesign

## Overview

Full rebrand from VS Code blue (`#007ACC`) to a teal (`#4EC9B0`) identity. Covers colour tokens, logo mark, selection surfaces, onboarding panel, button system, dialog system, and snackbar system. All interactive blue is replaced with teal; semantic colours (error, warning, info, success, syntax highlighting) are unchanged.

---

## 1. Colour tokens

### 1.1 Accent family

Replaces every blue interactive token. `accentLight` / `accentHover` / `accentDark` are proportional lightness/saturation steps derived from `#4EC9B0`.

| Token | Old | New |
|---|---|---|
| `accent` | `#007ACC` | `#4EC9B0` |
| `accentLight` | `#1F8AD2` | `#6DD4BE` |
| `accentHover` | `#0066B8` | `#3AB49A` |
| `accentDark` | `#004F85` | `#267A68` |
| `tabBorder` | `#007ACC` | `#4EC9B0` |
| `blueAccent` | `#4A7CFF` | `#4EC9B0` |

### 1.2 Selection / active surfaces

Replaces the blue-tinted dark surfaces used for selected items throughout the app.

| Token | Old | New |
|---|---|---|
| `selectionBg` | `#1A2540` | `#0D2B27` |
| `selectionBorder` | `#2A3550` | `#1A4840` |
| `questionCardBg` | `#1A1F2E` | `#0D2B27` |

### 1.3 Unchanged tokens

The following are semantic colours that intentionally stay as-is:

- Semantic states: `error` `#F44747`, `warning` `#CCA700`, `success` `#4EC9B0` (already teal), `info` `#4FC1FF`
- Git/VCS badges: `gitBadgeText`, `gitBadgeBg`, `gitBadgeBorder`
- Worktree badge: `worktreeBadgeBg`, `worktreeBadgeFg`
- PR status: `prMergedColor`, `pendingAmber`
- Edit badge: `editedBadgeBg`, `editedBadgeBorder`
- GitHub brand: `githubBrandColor`
- Diff highlights: `diffAdditionBg`, `diffDeletionBg`
- All syntax highlight colours (`syntaxKeyword` through `syntaxVariable`)

---

## 2. Logo mark

The in-app logo mark replaces the current "C" lettermark box in the onboarding panel and anywhere the app identifies itself.

| Property | Value |
|---|---|
| Container (onboarding panel) | 32×32px, `border-radius: 8px`, `background: #0D2B27`, `border: 1px solid #1A4840`, `box-shadow: 0 0 12px rgba(78,201,176,0.25)` |
| Container (neutral contexts) | 32×32px, `border-radius: 8px`, `background: linear-gradient(145deg, #141414, #0a0a0a)`, `border: 1px solid #2A2A2A` |
| Glyph | `</>` — five strokes, `stroke: #4EC9B0`, `stroke-width: 2.2`, `stroke-linecap: round` |
| Wordmark | "Code Bench", Inter 700, `#D4D4D4`, `font-size: 15–17px` |
| Tagline | "AI-powered coding workspace", Inter 400, `#4A6660`, `font-size: 10px` |

Use the teal-tinted container variant in the onboarding branding panel (it sits on a dark teal-atmospheric background). Use the neutral dark container variant anywhere else the logo mark appears.

**SVG glyph paths (32×32 viewport — single source of truth for all usages):**

```svg
<!-- Left bracket < -->
<path d="M5 16 L11 10" stroke="#4EC9B0" stroke-width="2.2" stroke-linecap="round"/>
<path d="M5 16 L11 22" stroke="#4EC9B0" stroke-width="2.2" stroke-linecap="round"/>
<!-- Right bracket > -->
<path d="M27 16 L21 10" stroke="#4EC9B0" stroke-width="2.2" stroke-linecap="round"/>
<path d="M27 16 L21 22" stroke="#4EC9B0" stroke-width="2.2" stroke-linecap="round"/>
<!-- Slash / -->
<line x1="19" y1="9" x2="13" y2="23" stroke="#4EC9B0" stroke-width="2.2" stroke-linecap="round"/>
```

These same coordinates are used for both the in-app logo mark (scaled to 32×32px display) and the app icon generation script (scaled ×32 to a 1024px canvas).

---

## 3. Onboarding branding panel

The left panel (`_BrandingPanel`) gets a teal atmospheric treatment.

| Property | Old | New |
|---|---|---|
| Background gradient | `#111111 → #0A0A0A → #050505` | `#0E1A18 → #0A0E0D → #050505` |
| Radial glow | None | `radial-gradient(circle, rgba(78,201,176,0.08) 0%, transparent 70%)` positioned top-left behind the logo |
| Feature card fill | `rgba(255,255,255,0.04)` | `rgba(78,201,176,0.04)` |
| Feature card border | `rgba(255,255,255,0.07)` | `rgba(78,201,176,0.08)` |
| Logo mark | "C" lettermark in blue gradient box | `</>` glyph in dark rounded-square (see §2) |

---

## 4. Selection / active state treatment

Active items (sidebar sessions, file tree rows, question cards) use a consistent treatment:

| Property | Value |
|---|---|
| Background | `#0D2B27` (medium teal tint) |
| Left border | `2px solid #4EC9B0` |
| Border radius | `0 6px 6px 0` (right corners only — left is cut by the border) |
| Text colour | `#D4D4D4` (unchanged — no teal text on selected rows) |

The `selectionBorder` token (`#1A4840`) is used for card-style selected states (e.g. `questionCardBg`) where a full border is more appropriate than a left-bar.

---

## 5. Button system

### 5.1 Primary

Solid teal fill, near-black text. The only button with a filled background.

| Property | Value |
|---|---|
| Background | `#4EC9B0` |
| Text | `#0A0A0A`, weight 600 |
| Hover background | `#3AB49A` (`accentHover`) |
| Disabled | 40% opacity |
| Border radius | 6px |
| Padding | `6px 14px` |

### 5.2 Secondary (ghost)

Transparent fill, neutral border. Used for cancel, skip, and non-primary actions.

| Property | Value |
|---|---|
| Background | Transparent |
| Text | `#D4D4D4` |
| Border | `1px solid #2A2A2A` |
| Hover border | `1px solid #3A3A3A` |
| Border radius | 6px |
| Padding | `6px 14px` |

### 5.3 Text / inline

No border, no background. Used for back navigation, learn-more links.

| Property | Value |
|---|---|
| Background | Transparent |
| Text | `#4EC9B0` for primary-tone links; `#9D9D9D` for neutral navigation (e.g. "Back") |
| Padding | `6px 4px` |

### 5.4 Destructive (ghost red)

Ghost pattern matching secondary, red accent instead of neutral.

| Property | Value |
|---|---|
| Background | Transparent |
| Text | `#F44747` |
| Border | `1px solid #3D1515` |
| Hover border | `1px solid #5A1F1F` |
| Border radius | 6px |

---

## 6. Dialog system

### 6.1 Surface

| Property | Value |
|---|---|
| Background | `rgba(22, 22, 22, 0.97)` |
| Border | `1px solid #333` |
| Border radius | `10px` |
| Box shadow | `0 20px 60px rgba(0,0,0,0.85), 0 0 0 0.5px rgba(255,255,255,0.04)` |
| Min width | `300px` |

### 6.2 Icon badge (hybrid sizing)

| Dialog type | Icon size | Border radius | When to use |
|---|---|---|---|
| Confirmation / destructive | 36×36px | 9px | No input fields in body |
| Input / prompt | 28×28px | 7px | Body contains one or more input fields |

Icon tint colours:
- Teal action: `background: rgba(78,201,176,0.10)`, `color: #4EC9B0`
- Destructive: `background: rgba(244,71,71,0.10)`, `color: #F44747`
- Info/neutral: `background: rgba(78,201,176,0.10)`, `color: #4EC9B0`

### 6.3 Layout

```
┌─────────────────────────────────────┐
│  [icon]  Title                       │  ← padding: 18px 16px 14px (36px icon)
│          Subtitle / body text        │    padding: 16px 16px 12px (28px icon)
│          [input field if applicable] │
├─────────────────────────────────────┤  ← border-top: 1px solid #242424
│              [Cancel]  [Primary Btn] │  ← padding: 11px 16px
└─────────────────────────────────────┘
```

### 6.4 Footer buttons

- Cancel: secondary ghost button
- Primary action: primary filled button (`#4EC9B0`)
- Destructive action: destructive ghost button (`#F44747`, `border: 1px solid #3D1515`)
- Primary action disabled: 50% opacity until any required input is filled

---

## 7. Snackbar system

### 7.1 Surface

| Property | Value |
|---|---|
| Background | `rgba(22, 22, 22, 0.97)` |
| Border | `1px solid #2A2A2A` (neutral) |
| Left border | `3px solid <type-colour>` |
| Border radius | `8px` |
| Box shadow | `0 8px 32px rgba(0,0,0,0.70)` |
| Width | `320px` |
| Position | Bottom-centre, `24px` from bottom edge |

### 7.2 Type colours

| Type | Left border | Icon background | Icon colour |
|---|---|---|---|
| Success | `#4EC9B0` | `rgba(78,201,176,0.12)` | `#4EC9B0` |
| Error | `#F44747` | `rgba(244,71,71,0.12)` | `#F44747` |
| Warning | `#CCA700` | `rgba(204,167,0,0.12)` | `#CCA700` |
| Info | `#4FC1FF` | `rgba(79,193,255,0.12)` | `#4FC1FF` |

### 7.3 Layout

```
┌───┬──────────────────────────────┬────────┬───┐
│   │ [icon]  Label (600, #E0E0E0) │ Action │ ✕ │
│ ← │         Message (#888, 10px) │        │   │
│bar│                               │        │   │
└───┴──────────────────────────────┴────────┴───┘
```

- Icon: 20×20px, `border-radius: 5px`
- Label: Inter 600, `11px`, `#E0E0E0`
- Message (optional): Inter 400, `10px`, `#888888`
- Action button (optional): `10px`, weight 600, type colour
- Close: `#555555`, `13px`

---

## 8. Action bar buttons

The top action bar contains three buttons: Commit (split), Push (ghost), and Create PR (ghost). All three sit at `height: 22px`, `border-radius: 4px`.

### 8.1 Commit split button

| Property | Value |
|---|---|
| Shape | Sharp split — `border-radius: 4px`, `overflow: hidden` |
| Left half background | `#4EC9B0` |
| Right half background | `#3AB49A` |
| Split divider | `1px solid #267A68` |
| Text colour | `#0A0A0A`, weight 600 |
| Icon | Git node: filled circle (`r=3px`) + solid pill stems above/below — **not** a stroked circle. Uses `fill` not `stroke` for crispness at 10–11px. |
| Disabled (no changes) | `background: #1A1A1A`, `border: 1px solid #222`, text `#444`, icon `#444` |
| Busy state | `background: #267A68`, text `#D4D4D4`, bullet `●` prefix |

### 8.2 Push button

| Property | Value |
|---|---|
| Style | Ghost — `background: #1A1A1A`, `border: 1px solid #2A2A2A`, text `#9D9D9D` |
| Icon | Cloud-upload (`cloud-upload` Feather/Lucide icon) |
| Label | "Push" |

### 8.3 Create PR button

| Property | Value |
|---|---|
| Style | Ghost — same as Push |
| Icon | Fork-into-target: three circles (top-left source, bottom-left trunk, top-right target) with a line down the left side and a curve from source to target. Standard git pull-request shape. |
| Label | "Create PR" |

---

## 9. Chat send button

Lives at the right end of the chat input bar.

| State | Shape | Background | Content |
|---|---|---|---|
| Active (has text) | 28×28px, `border-radius: 7px` | `#4EC9B0` | `↑` arrow, `#0A0A0A`, weight 700, `14px` |
| Empty | 28×28px, `border-radius: 7px` | `#1A1A1A`, `border: 1px solid #222` | `↑` arrow, `#444` |
| Streaming | 28×28px, `border-radius: 7px` | `#267A68` | 9×9px rounded square (`border-radius: 2px`, `background: #0A0A0A`) with pulse animation |

The square shape matches the app's dialog icon badge shape. The streaming stop indicator is a pulsing filled square — not a spinner.

---

## 10. Commit dialog

Replaces the bare `AlertDialog` in `commit_dialog.dart` with the frosted dialog system (§6).

### 10.1 Header

| Property | Value |
|---|---|
| Icon | Git node, 28×28px badge (input-dialog size — body has text field) |
| Title | "Commit changes" |
| Subtitle | AI-generated message shown as editable text field |

### 10.2 File list

Requires new data: `git diff --cached --numstat` output (staged changes only) parsed into a `GitChangedFile` model with `path`, `additions`, `deletions`, and `status` (added/modified/deleted/renamed). Fall back to `git diff --numstat HEAD` if the staged output is empty (i.e. the user is committing all working-tree changes directly).

| Property | Value |
|---|---|
| Container | Scrollable list, max-height `160px`, inside the dialog body |
| Row height | `22px` per file |
| Status badge | 1-letter pill: `M` modified `#CCA700`, `A` added `#4EC9B0`, `D` deleted `#F44747`, `R` renamed `#9D9D9D` |
| Filename | Monospace `11px`, `#D4D4D4`, truncated with ellipsis on the left if long |
| Stat | `+N −N` at right, green/red, `10px` |

### 10.3 Footer

Standard dialog footer (§6.4): "Cancel" ghost + "Commit" primary teal.

---

## 11. Create PR dialog

Replaces the bare `AlertDialog` in `create_pr_dialog.dart` with the frosted dialog system.

| Property | Value |
|---|---|
| Icon | Fork-into-target, 28×28px badge (input-dialog size) |
| Icon tint | Teal (`rgba(78,201,176,0.10)`) |
| Title | "Create pull request" |
| Body | Branch name, base branch dropdown, PR title text field |
| Footer | "Cancel" ghost + "Create PR" primary teal |

---

## 12. Onboarding screens

### 12.1 Branding panel (already in §3)

See §3. The `</>` logo mark, teal glow, and teal feature cards are the key changes.

### 12.2 Step progress indicator

`StepProgressIndicator` currently uses `blueAccent` for dots. Change to:

| Dot state | Colour | Size |
|---|---|---|
| Completed | `#4EC9B0` (full opacity) | `22×5px`, `border-radius: 3px` |
| Active | `rgba(78,201,176,0.45)` | `22×5px` |
| Future | `#222222` | `22×5px` |

### 12.3 GitHub connected card

The connected-state card (`_ConnectedView`) uses a teal-tinted border: `border: 1px solid #1A4840`, `background: #111`.

---

## 13. Settings screens

### 13.1 Left nav active state

`_NavItem` active treatment changes from `inputSurface` fill to the selection surface system (§4):

| Property | Value |
|---|---|
| Background | `#0D2B27` |
| Left border | `2px solid #4EC9B0` |
| Left padding | `14px` (2px less than inactive `16px` to compensate for border) |
| Icon colour | `#4EC9B0` |
| Text colour | `#D4D4D4` |

### 13.2 Section dividers

Each `SectionLabel` that is not the first on screen is preceded by a `Divider`:

```dart
Divider(height: 36, thickness: 1, color: ThemeConstants.borderColor)
```

This applies to General (before "About", before "Debug"), Providers (before "Ollama", before "Custom Endpoint"), and any future settings sections.

### 13.3 Layout fix — full-height content

`SettingsScreen` body `Row` is missing `crossAxisAlignment: CrossAxisAlignment.stretch`. Without it the nav and content columns do not fill the full window height, leaving the Scaffold `background` (`#141414`) visible at top and bottom as a lighter strip.

Fix: add `crossAxisAlignment: CrossAxisAlignment.stretch` to the `Row` in `_SettingsScreenState.build`.

---

## 14. Implementation scope (B+)

All interactive blue replaced with teal. The full audit touches:

**Token & theme layer**
1. `lib/core/constants/theme_constants.dart` — token values (§1)
2. `lib/core/theme/app_theme.dart` — `ColorScheme`, button themes, input focus border

**Shell & action bar**
3. `lib/shell/widgets/status_bar.dart` — branch name colour (currently `#007ACC`)
4. `lib/shell/widgets/top_action_bar.dart` — active-state icon colour
5. `lib/shell/widgets/commit_push_button.dart` — git node icon, Push cloud-upload icon, Create PR fork-into-target icon (§8)

**Chat**
6. `lib/features/chat/widgets/chat_input_bar.dart` — send button shape, states, streaming stop (§9)
7. `lib/features/chat/widgets/commit_dialog.dart` — full redesign to frosted dialog + file list (§10); requires new `GitChangedFile` model and `git diff --numstat` datasource method
8. `lib/features/chat/widgets/create_pr_dialog.dart` — redesign to frosted dialog (§11)

**Onboarding**
9. `lib/features/onboarding/onboarding_screen.dart` — `_BrandingPanel` gradient, glow, logo mark, feature card colours (§3)
10. `lib/features/onboarding/widgets/step_progress_indicator.dart` — step dots (§12.2)

**Settings**
11. `lib/features/settings/settings_screen.dart` — `_NavItem` active state (§13.1); `Row crossAxisAlignment` layout fix (§13.3)
12. `lib/features/settings/general_screen.dart` and `lib/features/settings/providers_screen.dart` — insert `Divider(height: 36, thickness: 1, color: ThemeConstants.borderColor)` before each `SectionLabel` that is not the first on the screen (§13.2)

**Selection surfaces**
13. All widgets using hard-coded `Color(0xFF007ACC)` or `selectionBg`/`selectionBorder` for selection surfaces — update to new teal tokens

**Net-new widgets**
14. `lib/core/widgets/app_dialog.dart` — frosted glass surface, hybrid icon badge, standardised footer (§6)
15. `lib/core/widgets/app_snack_bar.dart` — frosted glass surface, left colour bar, 4 type variants (§7); all existing `showSnackBar` call sites updated to use `AppSnackBar`

**New data layer (commit dialog)**
16. `lib/data/git/models/git_changed_file.dart` — new `GitChangedFile` model (`path`, `additions`, `deletions`, `status`)
17. `lib/data/git/datasource/git_datasource_process.dart` — new `getChangedFiles()` method using `git diff --cached --numstat`

**App icon**
18. `test/tool/generate_icon_test.dart` — icon generator script (see §15 and `docs/superpowers/plans/2026-04-13-code-bench-icon-generation.md`)
19. `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png` — 7 generated PNG files

---

## 15. App icon

The macOS app icon uses the same `</>` glyph (§2) on a dark rounded-square shell, generated as PNG files at all required sizes.

### 15.1 Output files

All files go in `macos/Runner/Assets.xcassets/AppIcon.appiconset/`. `Contents.json` is not modified.

| File | Size |
|---|---|
| `app_icon_16.png` | 16×16 |
| `app_icon_32.png` | 32×32 |
| `app_icon_64.png` | 64×64 |
| `app_icon_128.png` | 128×128 |
| `app_icon_256.png` | 256×256 |
| `app_icon_512.png` | 512×512 |
| `app_icon_1024.png` | 1024×1024 |

### 15.2 Generation approach

A Flutter test (`test/tool/generate_icon_test.dart`) acts as the generator:

1. Renders the 1024×1024 master using `dart:ui` `PictureRecorder` + `Canvas` (`dart:ui` requires `flutter test` — not available in plain `dart run`)
2. Downsamples to each size using the `image` package (`copyResize` with `Interpolation.lanczos`)
3. Writes PNG files directly to the appiconset directory

**Icon canvas spec:**
- Background: `RRect` with corner radius `224px` (~22%), filled with `linear-gradient(145deg, #141414 → #0A0A0A)`
- Glyph: five strokes from §2, scaled ×32 from the 32-unit viewport (e.g. stroke width `2.2 × 32 = 70.4px`)

The full implementation steps are in `docs/superpowers/plans/2026-04-13-code-bench-icon-generation.md`.

---

## What is NOT in scope

- Light theme
- Windows / Linux theming
- Syntax highlighting colour changes
- Icon generation script changes (already uses `#4EC9B0`)
- Any layout or feature changes — this spec is cosmetic only
