# UI Refresh — Elevated Glass + Light Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the Elevated Glass design language across the full app — frosted surfaces, rgba borders, shadow-only depth, gradient teal CTA, glass dark dialog — and wire a functional light theme switcher.

**Architecture:** Pure styling changes layered on top of the existing widget tree. New tokens in `ThemeConstants` → `AppTheme` updated → individual widgets updated to use the new tokens. Light theme uses the same `MaterialApp.router` `theme`/`darkTheme`/`themeMode` pattern with `ThemeMode` persisted via `SharedPreferences`. No notifiers, services, or data models change except the additions for theme preference and one new git worktree command.

**Tech Stack:** Flutter/Dart, Riverpod (`ref.watch`/`ref.read`), `shared_preferences`, `dart:ui` (`ImageFilter`), `lucide_icons_flutter`

---

## Token Reference (hex values for `Color()` constructor)

Use these exact values everywhere in the plan:

| Token name | `Color(0xAARRGGBB)` |
|---|---|
| `glassSurface` | `0x06FFFFFF` (rgba 255,255,255,0.024 ≈ 0.025) |
| `glassBorder` | `0x14FFFFFF` (rgba 255,255,255,0.08) |
| `glassBorderSubtle` | `0x0FFFFFFF` (rgba 255,255,255,0.06) |
| `glassBorderFaint` | `0x0DFFFFFF` (rgba 255,255,255,0.05) |
| `chipSurface` | `0x0AFFFFFF` (rgba 255,255,255,0.04) |
| `chipBorder` | `0x12FFFFFF` (rgba 255,255,255,0.07) |
| `userBubbleBorder` | `0x17FFFFFF` (rgba 255,255,255,0.09) |
| `userBubbleHighlight` | `0x12FFFFFF` (rgba 255,255,255,0.07) |
| `topBarSurface` | `0x05FFFFFF` (rgba 255,255,255,0.02) |
| `chatBoxRimGlow` | `0x124EC9B0` (rgba 78,201,176,0.07) |
| `accentGlowBadge` | `0x2E4EC9B0` (rgba 78,201,176,0.18) |
| `accentBorderTeal` | `0x4D4EC9B0` (rgba 78,201,176,0.30) |
| `accentBorderAmber` | `0x4DE8A228` (rgba 232,162,40,0.30) |
| `sendGlow` | `0x664EC9B0` (rgba 78,201,176,0.40) |
| `inlineCodeBg` | `0xCC0D1117` (rgba 13,17,23,0.80) |
| `dialogSurface` | `0xEB121212` (rgba 18,18,18,0.92) |
| `dialogTopHighlight` | `0x0FFFFFFF` (rgba 255,255,255,0.06) |
| `fieldSurface` | `0x0AFFFFFF` (rgba 255,255,255,0.04) |
| `fieldBorder` | `0x1AFFFFFF` (rgba 255,255,255,0.10) |
| `fieldFocusGlow` | `0x1F4EC9B0` (rgba 78,201,176,0.12) |
| `sendDisabledSurface` | `0x0FFFFFFF` (rgba 255,255,255,0.06) |
| `sendDisabledBorder` | `0x2EFFFFFF` (rgba 255,255,255,0.18) |
| `sendDisabledIcon` | `0x59FFFFFF` (rgba 255,255,255,0.35) |
| `lightBackground` | `0xFFF0F2F5` |
| `lightStatusBar` | `0xFFE8EAEE` |
| `lightTopBarSurface` | `0xCCF0F2F5` (rgba 240,242,245,0.80) |
| `lightChatBoxSurface` | `0xB8FFFFFF` (rgba 255,255,255,0.72) |
| `lightChatBoxBorder` | `0xE6FFFFFF` (rgba 255,255,255,0.90) |
| `lightDialogSurface` | `0xE0FFFFFF` (rgba 255,255,255,0.88) |
| `lightDialogBorder` | `0xF2FFFFFF` (rgba 255,255,255,0.95) |
| `lightDialogHighlight` | `0xFFFFFFFF` |
| `lightDivider` | `0x0F000000` (rgba 0,0,0,0.06) |
| `lightBorder` | `0x17000000` (rgba 0,0,0,0.09) |
| `lightText` | `0xFF1E2329` |
| `lightTextSecondary` | `0xFF3A424D` |
| `lightTextTertiary` | `0xFF6B7280` |
| `lightTextMuted` | `0xFF9BA4B0` |
| `lightChipSurface` | `0x0A000000` (rgba 0,0,0,0.04) |
| `lightChipBorder` | `0x1A000000` (rgba 0,0,0,0.10) |
| `lightChipText` | `0xFF7A8494` |
| `lightUserBubbleSurface` | `0x1F4EC9B0` (rgba 78,201,176,0.12) |
| `lightUserBubbleBorder` | `0x4D4EC9B0` (rgba 78,201,176,0.30) |
| `lightInlineCodeSurface` | `0x1F4EC9B0` |
| `lightInlineCodeBorder` | `0x334EC9B0` (rgba 78,201,176,0.20) |
| `lightInlineCodeText` | `0xFF2A7A6E` |
| `lightSendDisabledSurface` | `0x0D000000` (rgba 0,0,0,0.05) |
| `lightSendDisabledBorder` | `0x21000000` (rgba 0,0,0,0.13) |
| `lightSendDisabledIcon` | `0x40000000` (rgba 0,0,0,0.25) |

> **Token name conflict:** `ThemeConstants.accentGlow` already exists (`0x404EC9B0`, used by branding panel). The new token is named `chatBoxRimGlow` to avoid collision. The spec's "accentDark" gradient end (`#3AB49A`) already exists as `ThemeConstants.accentHover` — use `accentHover` everywhere the spec says `accentDark` for gradients.

---

## Task 1: Colour tokens

**Files:**
- Modify: `lib/core/constants/theme_constants.dart`

- [ ] **Step 1: Add all new dark tokens after the existing `iconInactive` line**

In `lib/core/constants/theme_constants.dart`, add after `static const Color iconInactive = Color(0xFF444444);`:

```dart
  // ── Elevated Glass — dark tokens ─────────────────────────────────────────

  // Surface fills (frosted white tints)
  static const Color glassSurface = Color(0x06FFFFFF);
  static const Color chipSurface = Color(0x0AFFFFFF);
  static const Color fieldSurface = Color(0x0AFFFFFF);
  static const Color topBarSurface = Color(0x05FFFFFF);
  static const Color sendDisabledSurface = Color(0x0FFFFFFF);
  static const Color dialogSurface = Color(0xEB121212);

  // Borders (frosted white)
  static const Color glassBorder = Color(0x14FFFFFF);
  static const Color glassBorderSubtle = Color(0x0FFFFFFF);
  static const Color glassBorderFaint = Color(0x0DFFFFFF);
  static const Color chipBorder = Color(0x12FFFFFF);
  static const Color userBubbleBorder = Color(0x17FFFFFF);
  static const Color userBubbleHighlight = Color(0x12FFFFFF);
  static const Color dialogTopHighlight = Color(0x0FFFFFFF);
  static const Color fieldBorder = Color(0x1AFFFFFF);
  static const Color sendDisabledBorder = Color(0x2EFFFFFF);

  // Icon / text (disabled states)
  static const Color sendDisabledIcon = Color(0x59FFFFFF);

  // Accent tinted surfaces / borders
  static const Color chatBoxRimGlow = Color(0x124EC9B0);
  static const Color accentGlowBadge = Color(0x2E4EC9B0);
  static const Color accentBorderTeal = Color(0x4D4EC9B0);
  static const Color accentBorderAmber = Color(0x4DE8A228);
  static const Color sendGlow = Color(0x664EC9B0);
  static const Color fieldFocusGlow = Color(0x1F4EC9B0);

  // Code
  static const Color inlineCodeBg = Color(0xCC0D1117);

  // ── Elevated Glass — light tokens ────────────────────────────────────────

  static const Color lightBackground = Color(0xFFF0F2F5);
  static const Color lightStatusBar = Color(0xFFE8EAEE);
  static const Color lightTopBarSurface = Color(0xCCF0F2F5);
  static const Color lightChatBoxSurface = Color(0xB8FFFFFF);
  static const Color lightChatBoxBorder = Color(0xE6FFFFFF);
  static const Color lightDialogSurface = Color(0xE0FFFFFF);
  static const Color lightDialogBorder = Color(0xF2FFFFFF);
  static const Color lightDialogHighlight = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0x0F000000);
  static const Color lightBorder = Color(0x17000000);
  static const Color lightText = Color(0xFF1E2329);
  static const Color lightTextSecondary = Color(0xFF3A424D);
  static const Color lightTextTertiary = Color(0xFF6B7280);
  static const Color lightTextMuted = Color(0xFF9BA4B0);
  static const Color lightChipSurface = Color(0x0A000000);
  static const Color lightChipBorder = Color(0x1A000000);
  static const Color lightChipText = Color(0xFF7A8494);
  static const Color lightUserBubbleSurface = Color(0x1F4EC9B0);
  static const Color lightUserBubbleBorder = Color(0x4D4EC9B0);
  static const Color lightInlineCodeSurface = Color(0x1F4EC9B0);
  static const Color lightInlineCodeBorder = Color(0x334EC9B0);
  static const Color lightInlineCodeText = Color(0xFF2A7A6E);
  static const Color lightSendDisabledSurface = Color(0x0D000000);
  static const Color lightSendDisabledBorder = Color(0x21000000);
  static const Color lightSendDisabledIcon = Color(0x40000000);
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/core/constants/theme_constants.dart
```
Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/theme_constants.dart
git commit -m "feat(tokens): add Elevated Glass dark + light colour tokens"
```

---

## Task 2: AppTheme — update dark `InputDecorationTheme` + add `AppTheme.light`

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Update the dark `InputDecorationTheme`**

In `lib/core/theme/app_theme.dart`, replace the existing `inputDecorationTheme:` block:

```dart
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ThemeConstants.fieldSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ThemeConstants.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ThemeConstants.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ThemeConstants.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        hintStyle: const TextStyle(color: ThemeConstants.textMuted),
        labelStyle: const TextStyle(color: ThemeConstants.textSecondary),
      ),
```

- [ ] **Step 2: Add `AppTheme.light` static getter**

After the closing `}` of `static ThemeData get dark { ... }`, add:

```dart
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: ThemeConstants.lightBackground,
      colorScheme: ColorScheme.light(
        primary: ThemeConstants.accent,
        onPrimary: Colors.white,
        secondary: ThemeConstants.accent,
        onSecondary: Colors.white,
        surface: ThemeConstants.lightChatBoxSurface,
        onSurface: ThemeConstants.lightText,
        error: ThemeConstants.error,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyMedium: GoogleFonts.inter(
          color: ThemeConstants.lightText,
          fontSize: ThemeConstants.uiFontSize,
        ),
        bodySmall: GoogleFonts.inter(
          color: ThemeConstants.lightTextSecondary,
          fontSize: 12,
        ),
        titleMedium: GoogleFonts.inter(
          color: ThemeConstants.lightText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: GoogleFonts.inter(
          color: ThemeConstants.lightTextTertiary,
          fontSize: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ThemeConstants.lightDivider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ThemeConstants.lightChatBoxSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ThemeConstants.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ThemeConstants.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ThemeConstants.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        hintStyle: const TextStyle(color: ThemeConstants.lightTextMuted),
        labelStyle: const TextStyle(color: ThemeConstants.lightTextTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConstants.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          ThemeConstants.lightTextMuted.withAlpha(100),
        ),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ThemeConstants.lightChatBoxSurface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ThemeConstants.lightBorder),
        ),
        textStyle: const TextStyle(color: ThemeConstants.lightText, fontSize: 12),
        waitDuration: const Duration(milliseconds: 500),
      ),
    );
  }
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/core/theme/app_theme.dart
```
Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat(theme): update dark InputDecorationTheme to glass; add AppTheme.light"
```

---

## Task 3: Status bar

**Files:**
- Modify: `lib/shell/widgets/status_bar.dart`

- [ ] **Step 1: Fix background and remove border**

In `lib/shell/widgets/status_bar.dart`, replace the `Container` decoration (around line 45–51):

```dart
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? ThemeConstants.background
            : ThemeConstants.lightStatusBar,
      ),
```

The old `border: Border(top: BorderSide(color: ThemeConstants.borderColor))` is removed entirely. The `color: ThemeConstants.activityBar` line is replaced.

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/shell/widgets/status_bar.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/shell/widgets/status_bar.dart
git commit -m "feat(status-bar): match background colour, remove border-top"
```

---

## Task 4: Top action bar + commit button

**Files:**
- Modify: `lib/shell/widgets/top_action_bar.dart`
- Modify: `lib/shell/widgets/commit_push_button.dart`

- [ ] **Step 1: Update `TopActionBar` container background and button styling**

In `lib/shell/widgets/top_action_bar.dart`, replace the `Container` decoration:

```dart
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? ThemeConstants.topBarSurface
            : ThemeConstants.lightTopBarSurface,
        border: const Border(
          bottom: BorderSide(color: ThemeConstants.glassBorderSubtle),
        ),
      ),
```

(The bottom border hairline stays — it's intentional per spec §3.)

- [ ] **Step 2: Wrap action buttons in glass pills**

The `ActionsDropdown` and `CodeDropdown` widgets are separate files. Wrap each call site in a glass pill container in `top_action_bar.dart`. After the `const SizedBox(width: 8)` and before `ActionsDropdown`, add a helper that wraps those two dropdowns:

```dart
                  _GlassPill(child: ActionsDropdown(project: s.project!)),
                  const SizedBox(width: 5),
                  _GlassPill(child: CodeDropdown(projectId: s.project!.id, projectPath: s.project!.path)),
```

Add the `_GlassPill` private widget at the bottom of `top_action_bar.dart`:

```dart
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? ThemeConstants.chipSurface : ThemeConstants.lightChipSurface,
        border: Border.all(
          color: dark ? ThemeConstants.chipBorder : ThemeConstants.lightChipBorder,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 3: Update the commit button to use gradient + unified appearance**

In `lib/shell/widgets/commit_push_button.dart`, find the left (Commit) half `Container` decoration (around line 232–240) and replace it:

```dart
              decoration: BoxDecoration(
                gradient: (busy || !s.canCommit)
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [ThemeConstants.accent, ThemeConstants.accentHover],
                      ),
                color: busy
                    ? ThemeConstants.accentHover
                    : s.canCommit
                    ? null
                    : ThemeConstants.inputSurface,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                boxShadow: (busy || !s.canCommit)
                    ? null
                    : const [
                        BoxShadow(
                          color: ThemeConstants.sendGlow,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/shell/widgets/top_action_bar.dart lib/shell/widgets/commit_push_button.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/shell/widgets/top_action_bar.dart lib/shell/widgets/commit_push_button.dart
git commit -m "feat(top-bar): glass background, pill buttons, gradient commit"
```

---

## Task 5: App dialog

**Files:**
- Modify: `lib/core/widgets/app_dialog.dart`

- [ ] **Step 1: Add `dart:ui` import**

At the top of `lib/core/widgets/app_dialog.dart`, add:

```dart
import 'dart:ui';
```

- [ ] **Step 2: Replace the dialog container with dark glass**

Replace the `Container` inside `Dialog > ConstrainedBox` (lines 69–148) with:

```dart
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? ThemeConstants.dialogSurface
                      : ThemeConstants.lightDialogSurface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? ThemeConstants.glassBorderSubtle
                        : ThemeConstants.lightDialogBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xF2000000)
                          : const Color(0x33000000),
                      blurRadius: Theme.of(context).brightness == Brightness.dark ? 64 : 48,
                      offset: Offset(
                        0,
                        Theme.of(context).brightness == Brightness.dark ? 24 : 16,
                      ),
                    ),
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? ThemeConstants.dialogTopHighlight
                          : ThemeConstants.lightDialogHighlight,
                      blurRadius: 0,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 18, 16, headerBottomPad),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: badgeSize,
                            height: badgeSize,
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(badgeRadius),
                              border: Border.all(
                                color: iconType == AppDialogIconType.teal
                                    ? ThemeConstants.accentBorderTeal
                                    : ThemeConstants.error.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: iconType == AppDialogIconType.teal
                                      ? ThemeConstants.accentGlowBadge
                                      : ThemeConstants.error.withValues(alpha: 0.18),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: Icon(icon, size: badgeSize * 0.5, color: iconFg),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: (badgeSize - 16.0) / 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? ThemeConstants.textPrimary
                                          : ThemeConstants.lightText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      subtitle!,
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? ThemeConstants.textSecondary
                                            : ThemeConstants.lightTextTertiary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: content),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? ThemeConstants.glassBorderFaint
                                : ThemeConstants.lightDivider,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions.indexed
                            .map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(left: entry.$1 > 0 ? 8.0 : 0.0),
                                child: _ActionButton(action: entry.$2),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
```

Note: `build` must now accept `BuildContext context` — change the `build` signature from `Widget build(BuildContext context)` (it already has context, just make sure it's available in the inner builder). Since `AppDialog.build` already receives `context`, this is fine.

Also update `_ActionButton` to use gradient for the primary style. Replace `_ActionButton.build`:

```dart
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (action._style) {
      case _ActionStyle.primary:
        return GestureDetector(
          onTap: action.onPressed,
          child: Opacity(
            opacity: action.onPressed == null ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ThemeConstants.accent, ThemeConstants.accentHover],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: ThemeConstants.sendGlow,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                action.label,
                style: const TextStyle(
                  color: ThemeConstants.onAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      case _ActionStyle.ghost:
        return GestureDetector(
          onTap: action.onPressed,
          child: Opacity(
            opacity: action.onPressed == null ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: dark ? ThemeConstants.chipSurface : ThemeConstants.lightChipSurface,
                border: Border.all(
                  color: dark ? ThemeConstants.chipBorder : ThemeConstants.lightChipBorder,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                action.label,
                style: TextStyle(
                  color: dark ? ThemeConstants.textPrimary : ThemeConstants.lightTextTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      case _ActionStyle.destructive:
        return GestureDetector(
          onTap: action.onPressed,
          child: Opacity(
            opacity: action.onPressed == null ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: ThemeConstants.destructiveBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                action.label,
                style: const TextStyle(
                  color: ThemeConstants.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
    }
  }
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/core/widgets/app_dialog.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/widgets/app_dialog.dart
git commit -m "feat(dialog): dark glass surface, blur, badge glow, gradient primary button"
```

---

## Task 6: Chat input bar

**Files:**
- Modify: `lib/features/chat/widgets/chat_input_bar.dart`

- [ ] **Step 1: Remove the hard outer border and fix background**

The outer `Container` (around line 315–325) currently has `border: Border(top: BorderSide(color: ThemeConstants.deepBorder))`. Replace that entire outer container decoration:

```dart
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? ThemeConstants.background
            : ThemeConstants.lightBackground,
      ),
```

- [ ] **Step 2: Replace the inner chat box container with glass**

The inner `Container` (around line 320–326) becomes:

```dart
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? ThemeConstants.glassSurface
              : ThemeConstants.lightChatBoxSurface,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? ThemeConstants.glassBorder
                : ThemeConstants.lightChatBoxBorder,
          ),
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0x8C000000)
                  : const Color(0x14000000),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0x4D000000)
                  : const Color(0x0D000000),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: ThemeConstants.chatBoxRimGlow,
              blurRadius: 0,
              spreadRadius: 0.5,
            ),
          ],
        ),
```

- [ ] **Step 3: Update the toolbar divider colour**

The `Container` with `border: Border(top: BorderSide(color: ThemeConstants.deepBorder))` (toolbar separator, around line 364–368) becomes:

```dart
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? ThemeConstants.glassBorderFaint
                        : ThemeConstants.lightDivider,
                  ),
                ),
              ),
```

- [ ] **Step 4: Update `_ControlChip` to glass pill style**

Replace `_ControlChip.build` entirely:

```dart
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: dark ? ThemeConstants.chipSurface : ThemeConstants.lightChipSurface,
          border: Border.all(
            color: dark ? ThemeConstants.chipBorder : ThemeConstants.lightChipBorder,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 11,
                color: dark ? ThemeConstants.textSecondary : ThemeConstants.lightChipText,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: dark ? ThemeConstants.textSecondary : ThemeConstants.lightChipText,
                fontSize: ThemeConstants.uiFontSizeSmall,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              AppIcons.chevronDown,
              size: 10,
              color: dark ? ThemeConstants.faintFg : ThemeConstants.lightTextMuted,
            ),
          ],
        ),
      ),
    );
  }
```

Also remove the `_Separator` widget definition and all `const _Separator()` usages in the `Row` of chips (replace each `const _Separator()` and surrounding `const SizedBox(width:...)` with just `const SizedBox(width: 4)`).

- [ ] **Step 5: Update the send button — disabled and active states**

In the `ListenableBuilder` builder for the send button (around lines 415–465), replace the bg/border logic:

```dart
                        final dark = Theme.of(context).brightness == Brightness.dark;
                        final Color bg;
                        final Border? border;
                        final Color iconColor;
                        final List<BoxShadow> shadows;
                        if (_isSending) {
                          bg = ThemeConstants.accentHover;
                          border = null;
                          iconColor = ThemeConstants.onAccent;
                          shadows = [];
                        } else if (hasText && !isMissing) {
                          bg = ThemeConstants.accent;
                          border = null;
                          iconColor = ThemeConstants.onAccent;
                          shadows = const [
                            BoxShadow(
                              color: ThemeConstants.sendGlow,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ];
                        } else {
                          bg = dark
                              ? ThemeConstants.sendDisabledSurface
                              : ThemeConstants.lightSendDisabledSurface;
                          border = Border.all(
                            color: dark
                                ? ThemeConstants.sendDisabledBorder
                                : ThemeConstants.lightSendDisabledBorder,
                          );
                          iconColor = dark
                              ? ThemeConstants.sendDisabledIcon
                              : ThemeConstants.lightSendDisabledIcon;
                          shadows = [];
                        }
                        return GestureDetector(
                          onTap: _isSending ? null : _send,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: (_isSending || (hasText && !isMissing)) ? bg : null,
                              gradient: (!_isSending && hasText && !isMissing)
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [ThemeConstants.accent, ThemeConstants.accentHover],
                                    )
                                  : null,
                              color: (_isSending || (!hasText) || isMissing) ? bg : null,
                              borderRadius: BorderRadius.circular(7),
                              border: border,
                              boxShadow: shadows,
                            ),
```

Clean this up — the gradient and color can't coexist cleanly with the logic above. Use this simplified form instead for the `Container` decoration:

```dart
                        return GestureDetector(
                          onTap: _isSending ? null : _send,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: (!_isSending && hasText && !isMissing)
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [ThemeConstants.accent, ThemeConstants.accentHover],
                                    )
                                  : null,
                              color: (_isSending || !hasText || isMissing) ? bg : null,
                              borderRadius: BorderRadius.circular(7),
                              border: border,
                              boxShadow: shadows,
                            ),
                            child: Center(
                              child: _isSending
                                  ? AnimatedBuilder(
                                      animation: _pulseOpacity,
                                      builder: (context, _) => Opacity(
                                        opacity: _pulseOpacity.value,
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: ThemeConstants.onAccent,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      AppIcons.arrowUp,
                                      size: 14,
                                      color: iconColor,
                                    ),
                            ),
                          ),
                        );
```

- [ ] **Step 6: Verify**

```bash
flutter analyze lib/features/chat/widgets/chat_input_bar.dart
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/chat/widgets/chat_input_bar.dart
git commit -m "feat(chat-input): glass box, chip pills, glass-ghost disabled send button"
```

---

## Task 7: Message bubbles

**Files:**
- Modify: `lib/features/chat/widgets/message_bubble.dart`

- [ ] **Step 1: Find the user bubble container**

```bash
grep -n "userMessageBg\|user.*bubble\|UserBubble\|bubble.*user" lib/features/chat/widgets/message_bubble.dart | head -20
```

Expected: lines referencing the user bubble container.

- [ ] **Step 2: Update user bubble styling**

Find the user message bubble `Container` decoration. Replace with:

```dart
decoration: BoxDecoration(
  color: Theme.of(context).brightness == Brightness.dark
      ? ThemeConstants.glassSurface
      : ThemeConstants.lightUserBubbleSurface,
  border: Border.all(
    color: Theme.of(context).brightness == Brightness.dark
        ? ThemeConstants.userBubbleBorder
        : ThemeConstants.lightUserBubbleBorder,
  ),
  borderRadius: BorderRadius.circular(11),
  boxShadow: [
    BoxShadow(
      color: Theme.of(context).brightness == Brightness.dark
          ? ThemeConstants.userBubbleHighlight
          : Colors.transparent,
      blurRadius: 0,
      offset: const Offset(0, 1),
    ),
  ],
),
```

- [ ] **Step 3: Update inline code spans**

Find where inline code spans are rendered (look for `syntaxString` or inline code style). Replace the background/border with:

```dart
// Inline code background
color: Theme.of(context).brightness == Brightness.dark
    ? ThemeConstants.inlineCodeBg
    : ThemeConstants.lightInlineCodeSurface,
// Inline code border  
border: Border.all(
  color: Theme.of(context).brightness == Brightness.dark
      ? ThemeConstants.glassBorderSubtle
      : ThemeConstants.lightInlineCodeBorder,
),
borderRadius: BorderRadius.circular(4),
```

And the inline code text colour:
```dart
color: Theme.of(context).brightness == Brightness.dark
    ? ThemeConstants.syntaxString  // #CE9178
    : ThemeConstants.lightInlineCodeText,  // #2A7A6E
```

- [ ] **Step 4: Update code block border**

Find the `CodeBlockWidget` or code block container. Add/update the border:

```dart
border: Border.all(
  color: ThemeConstants.glassBorderSubtle,
),
borderRadius: BorderRadius.circular(7),
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/features/chat/widgets/message_bubble.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/chat/widgets/message_bubble.dart
git commit -m "feat(bubbles): glass user bubble, teal inline-code light style, code block border"
```

---

## Task 8: Settings groups + inline text field

**Files:**
- Modify: `lib/features/settings/widgets/settings_group.dart`
- Modify: `lib/features/settings/widgets/inline_text_field.dart`

- [ ] **Step 1: Update `SettingsGroup` container to glass**

In `lib/features/settings/widgets/settings_group.dart`, replace the container decoration:

```dart
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0x05FFFFFF)  // rgba 255,255,255,0.02
            : const Color(0x99FFFFFF), // rgba 255,255,255,0.60
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? ThemeConstants.glassBorderSubtle
              : ThemeConstants.lightBorder,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
```

- [ ] **Step 2: Update row dividers to faint glass**

Replace `const Divider(height: 1, color: ThemeConstants.deepBorder)` with:

```dart
Divider(
  height: 1,
  color: Theme.of(context).brightness == Brightness.dark
      ? ThemeConstants.glassBorderFaint
      : ThemeConstants.lightDivider,
),
```

Note: since this is inside a `build` method that already has `context` as a parameter, `Theme.of(context)` is available.

- [ ] **Step 3: Slim down `InlineTextField` — remove padding override**

In `lib/features/settings/widgets/inline_text_field.dart`, remove the `contentPadding` and `isDense` overrides so the field inherits size B from `InputDecorationTheme`:

```dart
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? ThemeConstants.textPrimary
            : ThemeConstants.lightText,
        fontSize: 12,
        fontFamily: ThemeConstants.editorFontFamily,
      ),
      decoration: const InputDecoration(),
    );
  }
```

The `InputDecoration()` with no overrides will use the theme's `InputDecorationTheme` (glass fill, size B padding, teal focus ring).

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/features/settings/widgets/settings_group.dart lib/features/settings/widgets/inline_text_field.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/widgets/settings_group.dart lib/features/settings/widgets/inline_text_field.dart
git commit -m "feat(settings): glass group container, faint row dividers, size-B inline text field"
```

---

## Task 9: Settings nav + back button

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Update `_NavItem` active state to glass pill + accent bar**

Replace `_NavItem.build`:

```dart
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: isActive ? const EdgeInsets.only(right: 6) : EdgeInsets.zero,
        padding: EdgeInsets.only(
          left: isActive ? 11 : 16,
          right: 16,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x124EC9B0) : null, // rgba(78,201,176,0.07)
          borderRadius: isActive
              ? const BorderRadius.horizontal(right: Radius.circular(6))
              : null,
          border: isActive
              ? const Border(
                  left: BorderSide(color: ThemeConstants.accent, width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? ThemeConstants.accent : ThemeConstants.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 2: Update the "Back" nav item to a glass pill**

In `_SettingsLeftNav.build`, find the `_NavItem(icon: AppIcons.arrowLeft, label: 'Back', ...)` and replace it with:

```dart
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ThemeConstants.chipSurface,
                  border: Border.all(color: ThemeConstants.chipBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.arrowLeft, size: 11, color: ThemeConstants.textSecondary),
                    SizedBox(width: 6),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/settings/settings_screen.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat(settings-nav): glass active pill with accent bar, glass back button"
```

---

## Task 10: General settings — toggles + glass dropdown

**Files:**
- Modify: `lib/features/settings/general_screen.dart`

- [ ] **Step 1: Replace boolean `_AppDropdown` rows with `Switch` widgets**

In `lib/features/settings/general_screen.dart`, replace the "Delete confirmation" and "Auto-commit" rows. Find these two `SettingsRow` blocks (around lines 121–152) and replace them:

```dart
              SettingsRow(
                label: 'Delete confirmation',
                description: 'Ask before deleting a session',
                trailing: Switch(
                  value: _deleteConfirmation,
                  onChanged: (v) async {
                    await ref.read(generalPrefsProvider.notifier).setDeleteConfirmation(v);
                    setState(() => _deleteConfirmation = v);
                  },
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return Colors.white;
                    return const Color(0x40FFFFFF); // rgba(255,255,255,0.25)
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return ThemeConstants.accent;
                    return const Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
                  }),
                  trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return Colors.transparent;
                    return const Color(0x17FFFFFF); // rgba(255,255,255,0.09)
                  }),
                  thumbRadius: 5.0,
                ),
              ),
              SettingsRow(
                label: 'Auto-commit',
                description: 'Skip commit dialog; commit immediately with AI-generated message',
                trailing: Switch(
                  value: _autoCommit,
                  onChanged: (v) async {
                    await ref.read(generalPrefsProvider.notifier).setAutoCommit(v);
                    setState(() => _autoCommit = v);
                  },
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return Colors.white;
                    return const Color(0x40FFFFFF);
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return ThemeConstants.accent;
                    return const Color(0x0DFFFFFF);
                  }),
                  trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return Colors.transparent;
                    return const Color(0x17FFFFFF);
                  }),
                  thumbRadius: 5.0,
                ),
              ),
```

To get size 28×16, wrap each `Switch` in a `Transform.scale`:

```dart
                trailing: Transform.scale(
                  scale: 0.75,
                  child: Switch( ... ),
                ),
```

Flutter's `Switch` default size is roughly 38×22 — scaling by 0.75 gives ~28×16.

- [ ] **Step 2: Update `_AppDropdown` fill and border to glass**

In `_AppDropdown.build` (around line 316–336), replace the `Container` decoration:

```dart
        decoration: BoxDecoration(
          color: ThemeConstants.chipSurface,
          border: Border.all(color: ThemeConstants.chipBorder),
          borderRadius: BorderRadius.circular(6),
        ),
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/settings/general_screen.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/general_screen.dart
git commit -m "feat(general-settings): Switch toggles for booleans, glass dropdown"
```

---

## Task 11: Theme mode preference — SharedPrefs + repository + notifier

**Files:**
- Modify: `lib/data/_core/preferences/general_preferences.dart`
- Modify: `lib/data/settings/repository/settings_repository.dart`
- Modify: `lib/data/settings/repository/settings_repository_impl.dart`
- Modify: `lib/features/settings/notifiers/general_prefs_notifier.dart`

- [ ] **Step 1: Add `themeMode` to `GeneralPreferences`**

In `lib/data/_core/preferences/general_preferences.dart`, add after the existing keys and methods:

```dart
  static const _themeMode = 'theme_mode'; // values: 'system', 'dark', 'light'

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeMode) ?? 'system';
    return switch (raw) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeMode, raw);
  }
```

Add `import 'package:flutter/material.dart';` at the top.

- [ ] **Step 2: Add interface methods to `SettingsRepository`**

In `lib/data/settings/repository/settings_repository.dart`, add to the general preferences section:

```dart
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
```

Add `import 'package:flutter/material.dart';` at the top.

- [ ] **Step 3: Implement in `SettingsRepositoryImpl`**

In `lib/data/settings/repository/settings_repository_impl.dart`, add:

```dart
  @override
  Future<ThemeMode> getThemeMode() => _generalPrefs.getThemeMode();

  @override
  Future<void> setThemeMode(ThemeMode mode) => _generalPrefs.setThemeMode(mode);
```

- [ ] **Step 4: Add `themeMode` to `GeneralPrefsNotifierState` and `GeneralPrefsNotifier`**

In `lib/features/settings/notifiers/general_prefs_notifier.dart`:

Update `GeneralPrefsNotifierState`:
```dart
class GeneralPrefsNotifierState {
  const GeneralPrefsNotifierState({
    required this.autoCommit,
    required this.deleteConfirmation,
    required this.terminalApp,
    required this.themeMode,
  });

  final bool autoCommit;
  final bool deleteConfirmation;
  final String terminalApp;
  final ThemeMode themeMode;

  GeneralPrefsNotifierState copyWith({
    bool? autoCommit,
    bool? deleteConfirmation,
    String? terminalApp,
    ThemeMode? themeMode,
  }) => GeneralPrefsNotifierState(
    autoCommit: autoCommit ?? this.autoCommit,
    deleteConfirmation: deleteConfirmation ?? this.deleteConfirmation,
    terminalApp: terminalApp ?? this.terminalApp,
    themeMode: themeMode ?? this.themeMode,
  );
}
```

Update `GeneralPrefsNotifier.build` to load `themeMode`:

```dart
  @override
  Future<GeneralPrefsNotifierState> build() async {
    final svc = ref.read(settingsServiceProvider);
    return GeneralPrefsNotifierState(
      autoCommit: await svc.getAutoCommit(),
      deleteConfirmation: await svc.getDeleteConfirmation(),
      terminalApp: await svc.getTerminalApp(),
      themeMode: await svc.getThemeMode(),
    );
  }
```

Add `setThemeMode` method:

```dart
  Future<void> setThemeMode(ThemeMode mode) async {
    final next = await AsyncValue.guard(() async {
      try {
        await ref.read(settingsServiceProvider).setThemeMode(mode);
      } catch (e, st) {
        dLog('[GeneralPrefsNotifier] setThemeMode failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
      return (state.value ?? await build()).copyWith(themeMode: mode);
    });
    if (ref.mounted) state = next;
  }
```

Add `import 'package:flutter/material.dart';` at the top.

- [ ] **Step 5: Add `getThemeMode`/`setThemeMode` to `SettingsService`**

Check the service layer:

```bash
grep -n "themeMode\|getThemeMode\|setThemeMode" lib/services/settings/settings_service.dart
```

If `SettingsService` delegates to `SettingsRepository`, add the delegating methods there too. Find the pattern (e.g. `getAutoCommit` calls `_repo.getAutoCommit()`) and follow it for `themeMode`.

- [ ] **Step 6: Re-run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Verify**

```bash
flutter analyze lib/data/_core/preferences/general_preferences.dart lib/data/settings/repository/ lib/features/settings/notifiers/general_prefs_notifier.dart
```

- [ ] **Step 8: Commit**

```bash
git add lib/data/_core/preferences/general_preferences.dart \
        lib/data/settings/repository/settings_repository.dart \
        lib/data/settings/repository/settings_repository_impl.dart \
        lib/features/settings/notifiers/general_prefs_notifier.dart \
        lib/features/settings/notifiers/general_prefs_notifier.g.dart
git commit -m "feat(prefs): add themeMode to SharedPrefs, SettingsRepository, and GeneralPrefsNotifier"
```

---

## Task 12: Theme wiring — `app.dart` + `GeneralScreen` dropdown

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/features/settings/general_screen.dart`

- [ ] **Step 1: Wire theme in `app.dart`**

In `lib/app.dart`, replace `CodeBenchApp.build`:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(generalPrefsProvider).valueOrNull?.themeMode ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'Code Bench',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
```

Add the import for `generalPrefsProvider`:
```dart
import 'features/settings/notifiers/general_prefs_notifier.dart';
```

- [ ] **Step 2: Wire the Theme dropdown in `GeneralScreen`**

In `lib/features/settings/general_screen.dart`, update the `_GeneralScreenState`:

Add `ThemeMode _themeMode = ThemeMode.system;` field alongside the other bools.

Update `_load()` to also read `themeMode`:
```dart
  Future<void> _load() async {
    final s = await ref.read(generalPrefsProvider.future);
    if (!mounted) return;
    setState(() {
      _autoCommit = s.autoCommit;
      _deleteConfirmation = s.deleteConfirmation;
      _terminalApp = s.terminalApp;  // fix: this was _terminalAppController.text = s.terminalApp
      _themeMode = s.themeMode;
    });
  }
```

Replace the Theme dropdown `SettingsRow`:

```dart
              SettingsRow(
                label: 'Theme',
                description: 'How Code Bench looks',
                trailing: Builder(
                  builder: (ctx) => _AppDropdown<ThemeMode>(
                    value: _themeMode,
                    items: const [ThemeMode.system, ThemeMode.dark, ThemeMode.light],
                    label: (m) => switch (m) {
                      ThemeMode.system => 'System',
                      ThemeMode.dark => 'Dark',
                      ThemeMode.light => 'Light',
                    },
                    onChanged: (mode) async {
                      await ref.read(generalPrefsProvider.notifier).setThemeMode(mode);
                      setState(() => _themeMode = mode);
                    },
                    context: ctx,
                  ),
                ),
              ),
```

Also update `_AppDropdown` generic usage — `_AppDropdown<String>` with `'Dark'` etc. is now `_AppDropdown<ThemeMode>`. Remove the old `'Dark'/'Light'/'System'` strings from the Theme row call site.

Note: `_terminalAppController.text = s.terminalApp` was already in the original `_load()` — don't break that.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/app.dart lib/features/settings/general_screen.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart lib/features/settings/general_screen.dart
git commit -m "feat(theme): wire ThemeMode to MaterialApp.router; live theme dropdown in GeneralScreen"
```

---

## Task 13: Branch picker redesign

**Files:**
- Modify: `lib/features/branch_picker/widgets/branch_picker_popover.dart`
- Modify: `lib/features/branch_picker/notifiers/branch_picker_notifier.dart`
- Modify: `lib/features/branch_picker/notifiers/branch_picker_state.dart` + `.freezed.dart`
- Modify: `lib/features/branch_picker/notifiers/branch_picker_failure.dart` + `.freezed.dart`
- Modify: `lib/services/git/git_service.dart` (interface + impl) or the underlying datasource

**Overview:** Convert the `CompositedTransformFollower` popover to a dialog opened via `showDialog`. Redesign the interior with header, search, list (branches + worktrees), footer actions, and inline create-flows. Add `createWorktree` to the git layer.

- [ ] **Step 1: Add `createWorktree` to the git datasource**

```bash
grep -rn "createBranch\|process\|run" lib/data/git/datasource/ | head -20
```

Find the `*_process.dart` datasource file. Add a `createWorktree` method after `createBranch`:

```dart
  Future<void> createWorktree(String projectPath, String branchName, String worktreePath) async {
    final result = await Process.run(
      'git',
      ['worktree', 'add', worktreePath, '-b', branchName],
      workingDirectory: projectPath,
    );
    if (result.exitCode != 0) {
      throw GitException('git worktree add failed: ${result.stderr}');
    }
  }
```

Then add a corresponding method to the `GitDatasource` interface (the abstract class) and to `GitService`:

```dart
// In GitService interface:
Future<void> createWorktree(String projectPath, String branchName, String worktreePath);

// In GitServiceImpl:
Future<void> createWorktree(String projectPath, String branchName, String worktreePath) =>
    _ds(projectPath).createWorktree(projectPath, branchName, worktreePath);
```

- [ ] **Step 2: Add `createWorktreeFailure` to `BranchPickerFailure`**

In `lib/features/branch_picker/notifiers/branch_picker_failure.dart`:

```dart
  const factory BranchPickerFailure.createWorktreeFailed(String message) = BranchPickerCreateWorktreeFailed;
```

Regenerate:
```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Add `createWorktree` to `BranchPickerNotifier`**

In `lib/features/branch_picker/notifiers/branch_picker_notifier.dart`, add:

```dart
  Future<void> createWorktree(String branchName, String worktreePath) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final git = ref.read(gitServiceProvider);
        await git.createWorktree(projectPath, branchName, worktreePath);
        final branches = await git.listLocalBranches(projectPath);
        final wt = await git.worktreeBranches(projectPath);
        return BranchPickerState(branches: branches, worktreePaths: wt);
      } catch (e, st) {
        dLog('[BranchPickerNotifier] createWorktree failed: $e');
        final failure = switch (e) {
          GitException(:final message) => BranchPickerFailure.createWorktreeFailed(message),
          _ => BranchPickerFailure.gitUnavailable(),
        };
        Error.throwWithStackTrace(failure, st);
      }
    });
  }
```

- [ ] **Step 4: Rewrite `BranchPickerPopover` as a dialog-style widget**

The widget still renders inside an `OverlayEntry` (launched from `StatusBar._openPicker`). Change its appearance from a compact popover to a full-width centered dialog.

Replace the entire `build` method of `_BranchPickerPopoverState` with:

```dart
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(branchPickerProvider(widget.projectPath));

    return Stack(
      children: [
        // Scrim — dismiss on tap
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(color: const Color(0x33000000)),
          ),
        ),
        // Dialog centred on screen
        Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    width: 440,
                    constraints: const BoxConstraints(maxHeight: 560),
                    decoration: BoxDecoration(
                      color: ThemeConstants.dialogSurface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: ThemeConstants.glassBorderSubtle),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xF2000000),
                          blurRadius: 64,
                          offset: Offset(0, 24),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DialogHeader(
                          currentBranch: widget.currentBranch,
                          onClose: widget.onClose,
                          createMode: _createMode,
                          onBack: _createMode ? () => setState(() {
                            _createMode = false;
                            _worktreeMode = false;
                            _createController.clear();
                            _worktreePathController.clear();
                          }) : null,
                        ),
                        _SearchBar(
                          controller: _filterController,
                          focusNode: _filterFocus,
                        ),
                        if (!_createMode) ...[
                          Flexible(child: _buildList(asyncState)),
                          _DialogFooter(
                            onNewBranch: () => setState(() {
                              _createMode = true;
                              _worktreeMode = false;
                            }),
                            onNewWorktree: () => setState(() {
                              _createMode = true;
                              _worktreeMode = true;
                            }),
                          ),
                        ] else if (_worktreeMode) ...[
                          _WorktreeCreateForm(
                            branchController: _createController,
                            pathController: _worktreePathController,
                            defaultPath: _defaultWorktreePath(),
                            onSubmit: _createWorktree,
                          ),
                        ] else ...[
                          _BranchCreateForm(
                            controller: _createController,
                            focusNode: _createFocus,
                            onSubmit: _createBranch,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _defaultWorktreePath() {
    final branch = _createController.text.trim();
    if (branch.isEmpty) return '';
    final dir = widget.projectPath.split('/').last;
    final parent = widget.projectPath.contains('/')
        ? widget.projectPath.substring(0, widget.projectPath.lastIndexOf('/'))
        : widget.projectPath;
    return '$parent/.worktrees/$branch';
  }

  Widget _buildList(AsyncValue<BranchPickerState> asyncState) {
    return switch (asyncState) {
      AsyncLoading() => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: ThemeConstants.accent),
          ),
        ),
      ),
      AsyncError(:final error) => Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          _errorMessage(error),
          style: const TextStyle(color: ThemeConstants.warning, fontSize: ThemeConstants.uiFontSizeLabel),
        ),
      ),
      AsyncData(:final value) => Builder(builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_filterFocus.hasFocus && !_createFocus.hasFocus) {
            _filterFocus.requestFocus();
          }
        });
        final filtered = _filtered(value.branches);
        final branches = filtered.where((b) => !value.worktreePaths.containsKey(b)).toList();
        final worktrees = filtered.where((b) => value.worktreePaths.containsKey(b)).toList();
        return SizedBox(
          height: 240,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              if (branches.isNotEmpty) ...[
                const _SectionHeader(label: 'BRANCHES'),
                for (final b in branches)
                  _BranchRow(
                    branch: b,
                    isCurrent: b == widget.currentBranch,
                    isWorktree: false,
                    onTap: b == widget.currentBranch ? null : () => _checkout(b),
                  ),
              ],
              if (worktrees.isNotEmpty) ...[
                const _SectionHeader(label: 'WORKTREES'),
                for (final b in worktrees)
                  _BranchRow(
                    branch: b,
                    isCurrent: b == widget.currentBranch,
                    isWorktree: true,
                    onTap: b == widget.currentBranch
                        ? null
                        : () => _switchToWorktree(value.worktreePaths[b]!),
                  ),
              ],
            ],
          ),
        );
      }),
    };
  }
```

Add `_worktreeMode = false` and `_worktreePathController = TextEditingController()` fields. Add `_worktreePathController` to `initState`/`dispose`.

Add the helper sub-widgets at the bottom of the file:

```dart
class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.currentBranch,
    required this.onClose,
    required this.createMode,
    this.onBack,
  });
  final String? currentBranch;
  final VoidCallback onClose;
  final bool createMode;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          if (onBack != null)
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(5),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(LucideIcons.arrowLeft, size: 14, color: ThemeConstants.textSecondary),
              ),
            ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0x144EC9B0),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: ThemeConstants.accentBorderTeal),
              boxShadow: const [
                BoxShadow(color: ThemeConstants.accentGlowBadge, blurRadius: 14),
              ],
            ),
            child: const Icon(LucideIcons.gitBranch, size: 13, color: ThemeConstants.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  createMode ? (onBack != null ? 'New Branch' : 'New Worktree') : 'Switch Branch',
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (currentBranch != null)
                  Text(
                    currentBranch!,
                    style: const TextStyle(color: ThemeConstants.accent, fontSize: 10),
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 13, color: ThemeConstants.mutedFg),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: ThemeConstants.mutedFg,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter({required this.onNewBranch, required this.onNewWorktree});
  final VoidCallback onNewBranch;
  final VoidCallback onNewWorktree;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ThemeConstants.glassBorderFaint)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FooterButton(
              icon: LucideIcons.gitBranch,
              label: 'New Branch',
              iconColor: ThemeConstants.accent,
              borderColor: ThemeConstants.accentBorderTeal,
              onTap: onNewBranch,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FooterButton(
              icon: LucideIcons.layers,
              label: 'New Worktree',
              iconColor: const Color(0xFFE8A228),
              borderColor: ThemeConstants.accentBorderAmber,
              onTap: onNewWorktree,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x08FFFFFF),
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: ThemeConstants.uiFontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchCreateForm extends StatelessWidget {
  const _BranchCreateForm({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            onSubmitted: (_) => onSubmit(),
            style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 12),
            decoration: const InputDecoration(hintText: 'branch-name'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onSubmit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ThemeConstants.accent, ThemeConstants.accentHover],
                ),
                borderRadius: BorderRadius.circular(7),
                boxShadow: const [
                  BoxShadow(color: ThemeConstants.sendGlow, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: const Center(
                child: Text(
                  'Create Branch',
                  style: TextStyle(
                    color: ThemeConstants.onAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorktreeCreateForm extends StatelessWidget {
  const _WorktreeCreateForm({
    required this.branchController,
    required this.pathController,
    required this.defaultPath,
    required this.onSubmit,
  });
  final TextEditingController branchController;
  final TextEditingController pathController;
  final String defaultPath;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    // Pre-fill path if empty
    if (pathController.text.isEmpty && defaultPath.isNotEmpty) {
      pathController.text = defaultPath;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Branch name',
            style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: branchController,
            autofocus: true,
            style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 12),
            decoration: const InputDecoration(hintText: 'feat/my-feature'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Path',
            style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: pathController,
            style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 12),
            decoration: const InputDecoration(hintText: '.worktrees/feat-my-feature'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onSubmit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x14E8A228),
                border: Border.all(color: ThemeConstants.accentBorderAmber),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: Text(
                  'Create Worktree',
                  style: TextStyle(
                    color: Color(0xFFE8A228),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

Add the `_createWorktree` method to `_BranchPickerPopoverState`:

```dart
  Future<void> _createWorktree() async {
    final branch = _createController.text.trim();
    final path = _worktreePathController.text.trim();
    if (branch.isEmpty || path.isEmpty) return;
    await ref.read(branchPickerProvider(widget.projectPath).notifier).createWorktree(branch, path);
    if (!mounted) return;
    final s = ref.read(branchPickerProvider(widget.projectPath));
    if (s.hasError) {
      final failure = s.error;
      if (failure is BranchPickerFailure) {
        switch (failure) {
          case BranchPickerCreateWorktreeFailed(:final message):
            AppSnackBar.show(context, 'Worktree failed: $message', type: AppSnackBarType.error);
          default:
            AppSnackBar.show(context, 'Create worktree failed.', type: AppSnackBarType.error);
        }
      }
    } else {
      ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.projectPath);
      widget.onClose();
    }
  }
```

Add `import 'dart:ui';` at the top of `branch_picker_popover.dart`.

- [ ] **Step 5: Update `_SearchBar` to use theme field style**

Replace `_SearchBar.build` to use the global `InputDecorationTheme` (remove the explicit `fillColor`, hard borders):

```dart
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
        decoration: InputDecoration(
          hintText: 'Search branches…',
          hintStyle: const TextStyle(color: ThemeConstants.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 8, right: 4),
            child: Icon(LucideIcons.search, size: 11, color: ThemeConstants.mutedFg),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }
```

- [ ] **Step 6: Re-run code generation for updated freezed files**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Verify**

```bash
flutter analyze lib/features/branch_picker/ lib/services/git/ lib/data/git/
```

- [ ] **Step 8: Commit**

```bash
git add lib/features/branch_picker/ lib/services/git/ lib/data/git/
git commit -m "feat(branch-picker): dialog redesign, glass surface, footer actions, worktree create flow"
```

---

## Post-implementation checklist

- [ ] `dart format lib/ test/`
- [ ] `flutter analyze` — zero issues
- [ ] `flutter test` — all existing tests pass
- [ ] Run `flutter run -d macos` and visually verify:
  - [ ] Status bar background matches message area — no dark band
  - [ ] Chat box floats by shadow — no hard top border
  - [ ] Send button disabled: glass ghost visible; active: teal gradient
  - [ ] App dialog: dark glass, blur, gradient primary button
  - [ ] Settings groups: glass container, faint dividers
  - [ ] Settings nav: teal pill + left bar on active item; glass back button
  - [ ] Toggle switches on General settings (delete confirmation, auto-commit)
  - [ ] Theme dropdown in settings switches the whole app (Dark / Light / System)
  - [ ] Branch picker opens as centred dialog with search, list, footer buttons
  - [ ] New Branch flow: inline form + gradient Create Branch button
  - [ ] New Worktree flow: branch + path fields + amber Create Worktree button

---

## Self-review notes

**Spec coverage gaps addressed:**
- §3 top bar: `ActionsDropdown` and `CodeDropdown` are separate widget files that style their own text/icons internally. Task 4 wraps them in glass pills — their inner styles are left to their own pass if needed.
- §4b gradient fade overlay: not yet in the chat screen layout. The fade needs adding to the `Stack` or `Column` in `chat_screen.dart` / wherever the `ListView` + `ChatInputBar` live. Find the parent and add an `IgnorePointer` `Container` with a gradient at the bottom of the list area. This is a missing task — add it after Task 6 if the fade is absent.
- §9b (`GeneralPrefs` Drift table): the actual storage uses `SharedPreferences`, not Drift. The plan follows the existing pattern (SharedPrefs) and does not add a Drift column. The spec reference to "Drift table" is incorrect — ignore it.

**Type consistency:**
- `accentHover` (`#3AB49A`) is used as gradient end everywhere instead of the spec's `accentDark` (which has a different existing value).
- `chatBoxRimGlow` replaces the spec's `accentGlow` to avoid colliding with the existing branding token.
- `glassSurface` replaces the spec's reference to "repurposed `frostedSurface`" — the existing `frostedSurface` token is kept unchanged to avoid breaking snackbars and other dialogs that currently use it.
