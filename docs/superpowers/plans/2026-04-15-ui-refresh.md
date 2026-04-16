# UI Refresh — Elevated Glass + Light Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the Elevated Glass design language across the full app — frosted surfaces, rgba borders, shadow-only depth, gradient teal CTA, glass dark dialog — and wire a functional light theme switcher.

**Architecture:** `ThemeExtension` approach (Option A). Create `AppColors extends ThemeExtension<AppColors>` in `lib/core/theme/app_colors.dart` containing **all** colour tokens — the ~84 existing ones from `ThemeConstants` plus 29 new glass/light tokens. Register `AppColors.dark` on `AppTheme.dark` and `AppColors.light` on `AppTheme.light`. Remove every colour field from `ThemeConstants` (keep non-colour constants: sizes, fonts). Migrate all existing widget references from `ThemeConstants.colorXxx` to `AppColors.of(context).colorXxx`. Result: zero `Theme.of(context).brightness` checks anywhere; the extension instance handles the switch automatically.

**Tech Stack:** Flutter/Dart, Riverpod (`ref.watch`/`ref.read`), `shared_preferences`, `dart:ui` (`ImageFilter`), `lucide_icons_flutter`

---

## Token Reference

All hex values for `Color(0xAARRGGBB)`. Tokens new in this plan are marked ★.

| Token | dark value | light value |
|---|---|---|
| `background` | `0xFF141414` | `0xFFF0F2F5` ★ |
| `textPrimary` | `0xFFD4D4D4` | `0xFF1E2329` ★ |
| `textSecondary` | `0xFF9D9D9D` | `0xFF3A424D` ★ |
| `textMuted` | `0xFF666666` | `0xFF9BA4B0` ★ |
| `glassFill` ★ | `0x06FFFFFF` | `0xB8FFFFFF` |
| `glassBorder` ★ | `0x14FFFFFF` | `0xE6FFFFFF` |
| `subtleBorder` ★ | `0x0FFFFFFF` | `0x17000000` |
| `faintBorder` ★ | `0x0DFFFFFF` | `0x0F000000` |
| `chipFill` ★ | `0x0AFFFFFF` | `0x0A000000` |
| `chipStroke` ★ | `0x12FFFFFF` | `0x1A000000` |
| `chipText` ★ | `0xFF9D9D9D` | `0xFF7A8494` |
| `userBubbleFill` ★ | `0x06FFFFFF` | `0x1F4EC9B0` |
| `userBubbleStroke` ★ | `0x17FFFFFF` | `0x4D4EC9B0` |
| `userBubbleHighlight` ★ | `0x12FFFFFF` | `0x00000000` |
| `topBarFill` ★ | `0x05FFFFFF` | `0xCCF0F2F5` |
| `statusBarFill` ★ | `0xFF141414` | `0xFFE8EAEE` |
| `chatBoxRimGlow` ★ | `0x124EC9B0` | same |
| `accentGlowBadge` ★ | `0x2E4EC9B0` | same |
| `accentBorderTeal` ★ | `0x4D4EC9B0` | same |
| `accentBorderAmber` ★ | `0x4DE8A228` | same |
| `sendGlow` ★ | `0x664EC9B0` | same |
| `inlineCodeFill` ★ | `0xCC0D1117` | `0x1F4EC9B0` |
| `inlineCodeStroke` ★ | `0x0FFFFFFF` | `0x334EC9B0` |
| `inlineCodeText` ★ | `0xFFCE9178` | `0xFF2A7A6E` |
| `dialogFill` ★ | `0xEB121212` | `0xE0FFFFFF` |
| `dialogBorder` ★ | `0x0FFFFFFF` | `0xF2FFFFFF` |
| `dialogHighlight` ★ | `0x0FFFFFFF` | `0xFFFFFFFF` |
| `fieldFill` ★ | `0x0AFFFFFF` | `0xB8FFFFFF` |
| `fieldStroke` ★ | `0x1AFFFFFF` | `0x17000000` |
| `fieldFocusGlow` ★ | `0x1F4EC9B0` | same |
| `sendDisabledFill` ★ | `0x0FFFFFFF` | `0x0D000000` |
| `sendDisabledStroke` ★ | `0x2EFFFFFF` | `0x21000000` |
| `sendDisabledIconColor` ★ | `0x59FFFFFF` | `0x40000000` |

> **Note:** `accentHover` (`#3AB49A`) is used as gradient end everywhere the spec says `accentDark`. `chatBoxRimGlow` replaces the old plan's `accentGlow` name to avoid collision with the existing branding token.

---

## Task 1: Create `AppColors` ThemeExtension

**Files:**
- Create: `lib/core/theme/app_colors.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// All colour tokens for Code Bench.
///
/// Access in a widget build method:
///   final c = AppColors.of(context);
///   color: c.background
///
/// Registered on ThemeData via AppTheme.dark / AppTheme.light.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    // ── Backgrounds ──────────────────────────────────────────────────────
    required this.background,
    required this.sidebarBackground,
    required this.activityBar,
    required this.deepBackground,
    required this.titleBar,
    required this.editorBackground,
    required this.editorLineHighlight,
    required this.editorGutter,
    required this.editorGutterForeground,
    required this.panelBackground,
    required this.inputBackground,
    required this.borderColor,
    required this.dividerColor,
    // ── Text ─────────────────────────────────────────────────────────────
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    // ── Accent ───────────────────────────────────────────────────────────
    required this.accent,
    required this.accentLight,
    required this.accentHover,
    required this.accentDark,
    // ── Semantic ─────────────────────────────────────────────────────────
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    // ── Chat ─────────────────────────────────────────────────────────────
    required this.userMessageBg,
    required this.assistantMessageBg,
    required this.codeBlockBg,
    // ── Syntax ───────────────────────────────────────────────────────────
    required this.syntaxKeyword,
    required this.syntaxString,
    required this.syntaxComment,
    required this.syntaxFunction,
    required this.syntaxType,
    required this.syntaxNumber,
    required this.syntaxVariable,
    // ── Tabs ─────────────────────────────────────────────────────────────
    required this.tabActive,
    required this.tabInactive,
    required this.tabBorder,
    // ── Legacy frosted glass ──────────────────────────────────────────────
    required this.frostedBg,
    required this.frostedBorder,
    // ── VCS badges ───────────────────────────────────────────────────────
    required this.gitBadgeText,
    required this.gitBadgeBg,
    required this.gitBadgeBorder,
    // ── Input / surface ───────────────────────────────────────────────────
    required this.inputSurface,
    required this.deepBorder,
    required this.mutedFg,
    required this.faintFg,
    // ── Misc foregrounds ─────────────────────────────────────────────────
    required this.blueAccent,
    required this.dimFg,
    required this.headingText,
    // ── Status badges ────────────────────────────────────────────────────
    required this.worktreeBadgeBg,
    required this.worktreeBadgeFg,
    required this.selectionBg,
    required this.selectionBorder,
    required this.questionCardBg,
    required this.prMergedColor,
    required this.pendingAmber,
    required this.editedBadgeBg,
    required this.editedBadgeBorder,
    required this.githubBrandColor,
    // ── Diff ─────────────────────────────────────────────────────────────
    required this.diffAdditionBg,
    required this.diffDeletionBg,
    // ── Surfaces / shadows ────────────────────────────────────────────────
    required this.onAccent,
    required this.frostedSurface,
    required this.destructiveBorder,
    required this.panelSeparator,
    required this.iconInactive,
    required this.shadowDark,
    required this.shadowMedium,
    required this.shadowHeavy,
    required this.shadowDeep,
    required this.innerGlow,
    // ── Tinted icon backgrounds ───────────────────────────────────────────
    required this.successTintBg,
    required this.errorTintBg,
    required this.warningTintBg,
    required this.infoTintBg,
    required this.successBadgeBg,
    required this.errorBadgeBg,
    required this.warningBadgeBg,
    // ── Branding ─────────────────────────────────────────────────────────
    required this.brandingGradientTop,
    required this.brandingGradientMid,
    required this.accentGlow,
    required this.subtleTealFg,
    required this.accentTintLight,
    required this.accentTintMid,
    // ── Elevated Glass — new tokens ★ ─────────────────────────────────────
    required this.glassFill,
    required this.glassBorder,
    required this.subtleBorder,
    required this.faintBorder,
    required this.chipFill,
    required this.chipStroke,
    required this.chipText,
    required this.userBubbleFill,
    required this.userBubbleStroke,
    required this.userBubbleHighlight,
    required this.topBarFill,
    required this.statusBarFill,
    required this.chatBoxRimGlow,
    required this.accentGlowBadge,
    required this.accentBorderTeal,
    required this.accentBorderAmber,
    required this.sendGlow,
    required this.inlineCodeFill,
    required this.inlineCodeStroke,
    required this.inlineCodeText,
    required this.dialogFill,
    required this.dialogBorder,
    required this.dialogHighlight,
    required this.fieldFill,
    required this.fieldStroke,
    required this.fieldFocusGlow,
    required this.sendDisabledFill,
    required this.sendDisabledStroke,
    required this.sendDisabledIconColor,
  });

  // ── Field declarations ────────────────────────────────────────────────────

  final Color background;
  final Color sidebarBackground;
  final Color activityBar;
  final Color deepBackground;
  final Color titleBar;
  final Color editorBackground;
  final Color editorLineHighlight;
  final Color editorGutter;
  final Color editorGutterForeground;
  final Color panelBackground;
  final Color inputBackground;
  final Color borderColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentLight;
  final Color accentHover;
  final Color accentDark;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color userMessageBg;
  final Color assistantMessageBg;
  final Color codeBlockBg;
  final Color syntaxKeyword;
  final Color syntaxString;
  final Color syntaxComment;
  final Color syntaxFunction;
  final Color syntaxType;
  final Color syntaxNumber;
  final Color syntaxVariable;
  final Color tabActive;
  final Color tabInactive;
  final Color tabBorder;
  final Color frostedBg;
  final Color frostedBorder;
  final Color gitBadgeText;
  final Color gitBadgeBg;
  final Color gitBadgeBorder;
  final Color inputSurface;
  final Color deepBorder;
  final Color mutedFg;
  final Color faintFg;
  final Color blueAccent;
  final Color dimFg;
  final Color headingText;
  final Color worktreeBadgeBg;
  final Color worktreeBadgeFg;
  final Color selectionBg;
  final Color selectionBorder;
  final Color questionCardBg;
  final Color prMergedColor;
  final Color pendingAmber;
  final Color editedBadgeBg;
  final Color editedBadgeBorder;
  final Color githubBrandColor;
  final Color diffAdditionBg;
  final Color diffDeletionBg;
  final Color onAccent;
  final Color frostedSurface;
  final Color destructiveBorder;
  final Color panelSeparator;
  final Color iconInactive;
  final Color shadowDark;
  final Color shadowMedium;
  final Color shadowHeavy;
  final Color shadowDeep;
  final Color innerGlow;
  final Color successTintBg;
  final Color errorTintBg;
  final Color warningTintBg;
  final Color infoTintBg;
  final Color successBadgeBg;
  final Color errorBadgeBg;
  final Color warningBadgeBg;
  final Color brandingGradientTop;
  final Color brandingGradientMid;
  final Color accentGlow;
  final Color subtleTealFg;
  final Color accentTintLight;
  final Color accentTintMid;
  // New glass tokens ★
  final Color glassFill;
  final Color glassBorder;
  final Color subtleBorder;
  final Color faintBorder;
  final Color chipFill;
  final Color chipStroke;
  final Color chipText;
  final Color userBubbleFill;
  final Color userBubbleStroke;
  final Color userBubbleHighlight;
  final Color topBarFill;
  final Color statusBarFill;
  final Color chatBoxRimGlow;
  final Color accentGlowBadge;
  final Color accentBorderTeal;
  final Color accentBorderAmber;
  final Color sendGlow;
  final Color inlineCodeFill;
  final Color inlineCodeStroke;
  final Color inlineCodeText;
  final Color dialogFill;
  final Color dialogBorder;
  final Color dialogHighlight;
  final Color fieldFill;
  final Color fieldStroke;
  final Color fieldFocusGlow;
  final Color sendDisabledFill;
  final Color sendDisabledStroke;
  final Color sendDisabledIconColor;

  // ── Convenience accessor ─────────────────────────────────────────────────

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  // ── Static instances (used by AppTheme and InputDecorationTheme) ──────────

  static const AppColors dark = AppColors(
    background: Color(0xFF141414),
    sidebarBackground: Color(0xFF111111),
    activityBar: Color(0xFF0A0A0A),
    deepBackground: Color(0xFF050505),
    titleBar: Color(0xFF111111),
    editorBackground: Color(0xFF141414),
    editorLineHighlight: Color(0xFF1E1E1E),
    editorGutter: Color(0xFF141414),
    editorGutterForeground: Color(0xFF858585),
    panelBackground: Color(0xFF1E1E1E),
    inputBackground: Color(0xFF111111),
    borderColor: Color(0xFF2A2A2A),
    dividerColor: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFD4D4D4),
    textSecondary: Color(0xFF9D9D9D),
    textMuted: Color(0xFF666666),
    accent: Color(0xFF4EC9B0),
    accentLight: Color(0xFF6DD4BE),
    accentHover: Color(0xFF3AB49A),
    accentDark: Color(0xFF267A68),
    success: Color(0xFF4EC9B0),
    warning: Color(0xFFCCA700),
    error: Color(0xFFF44747),
    info: Color(0xFF4FC1FF),
    userMessageBg: Color(0xFF1E1E1E),
    assistantMessageBg: Color(0xFF141414),
    codeBlockBg: Color(0xFF0D1117),
    syntaxKeyword: Color(0xFF569CD6),
    syntaxString: Color(0xFFCE9178),
    syntaxComment: Color(0xFF6A9955),
    syntaxFunction: Color(0xFFDCDCAA),
    syntaxType: Color(0xFF4EC9B0),
    syntaxNumber: Color(0xFFB5CEA8),
    syntaxVariable: Color(0xFF9CDCFE),
    tabActive: Color(0xFF141414),
    tabInactive: Color(0xFF111111),
    tabBorder: Color(0xFF4EC9B0),
    frostedBg: Color(0x0AFFFFFF),
    frostedBorder: Color(0x12FFFFFF),
    gitBadgeText: Color(0xFF4CAF50),
    gitBadgeBg: Color(0xFF0F3D1F),
    gitBadgeBorder: Color(0xFF1A6B35),
    inputSurface: Color(0xFF1A1A1A),
    deepBorder: Color(0xFF222222),
    mutedFg: Color(0xFF555555),
    faintFg: Color(0xFF333333),
    blueAccent: Color(0xFF4EC9B0),
    dimFg: Color(0xFF888888),
    headingText: Color(0xFFE0E0E0),
    worktreeBadgeBg: Color(0xFF2A1F0A),
    worktreeBadgeFg: Color(0xFFE8A228),
    selectionBg: Color(0xFF0D2B27),
    selectionBorder: Color(0xFF1A4840),
    questionCardBg: Color(0xFF0D2B27),
    prMergedColor: Color(0xFF6E40C9),
    pendingAmber: Color(0xFFFFAA00),
    editedBadgeBg: Color(0xFF3D2900),
    editedBadgeBorder: Color(0xFFAA7700),
    githubBrandColor: Color(0xFF24292E),
    diffAdditionBg: Color(0x3300CC66),
    diffDeletionBg: Color(0x33FF4444),
    onAccent: Color(0xFF0A0A0A),
    frostedSurface: Color(0xF7161616),
    destructiveBorder: Color(0xFF3D1515),
    panelSeparator: Color(0xFF242424),
    iconInactive: Color(0xFF444444),
    shadowDark: Color(0x99000000),
    shadowMedium: Color(0x66000000),
    shadowHeavy: Color(0xB3000000),
    shadowDeep: Color(0xD9000000),
    innerGlow: Color(0x0AFFFFFF),
    successTintBg: Color(0x1F4EC9B0),
    errorTintBg: Color(0x1FF44747),
    warningTintBg: Color(0x1FCCA700),
    infoTintBg: Color(0x1F4FC1FF),
    successBadgeBg: Color(0x1A4EC9B0),
    errorBadgeBg: Color(0x1AF44747),
    warningBadgeBg: Color(0x1ACCA700),
    brandingGradientTop: Color(0xFF0E1A18),
    brandingGradientMid: Color(0xFF0A0E0D),
    accentGlow: Color(0x404EC9B0),
    subtleTealFg: Color(0xFF4A6660),
    accentTintLight: Color(0x0A4EC9B0),
    accentTintMid: Color(0x144EC9B0),
    // Elevated Glass dark
    glassFill: Color(0x06FFFFFF),
    glassBorder: Color(0x14FFFFFF),
    subtleBorder: Color(0x0FFFFFFF),
    faintBorder: Color(0x0DFFFFFF),
    chipFill: Color(0x0AFFFFFF),
    chipStroke: Color(0x12FFFFFF),
    chipText: Color(0xFF9D9D9D),
    userBubbleFill: Color(0x06FFFFFF),
    userBubbleStroke: Color(0x17FFFFFF),
    userBubbleHighlight: Color(0x12FFFFFF),
    topBarFill: Color(0x05FFFFFF),
    statusBarFill: Color(0xFF141414),
    chatBoxRimGlow: Color(0x124EC9B0),
    accentGlowBadge: Color(0x2E4EC9B0),
    accentBorderTeal: Color(0x4D4EC9B0),
    accentBorderAmber: Color(0x4DE8A228),
    sendGlow: Color(0x664EC9B0),
    inlineCodeFill: Color(0xCC0D1117),
    inlineCodeStroke: Color(0x0FFFFFFF),
    inlineCodeText: Color(0xFFCE9178),
    dialogFill: Color(0xEB121212),
    dialogBorder: Color(0x0FFFFFFF),
    dialogHighlight: Color(0x0FFFFFFF),
    fieldFill: Color(0x0AFFFFFF),
    fieldStroke: Color(0x1AFFFFFF),
    fieldFocusGlow: Color(0x1F4EC9B0),
    sendDisabledFill: Color(0x0FFFFFFF),
    sendDisabledStroke: Color(0x2EFFFFFF),
    sendDisabledIconColor: Color(0x59FFFFFF),
  );

  static const AppColors light = AppColors(
    // Themed
    background: Color(0xFFF0F2F5),
    textPrimary: Color(0xFF1E2329),
    textSecondary: Color(0xFF3A424D),
    textMuted: Color(0xFF9BA4B0),
    // Unchanged from dark (will be themed in follow-up PRs as needed)
    sidebarBackground: Color(0xFF111111),
    activityBar: Color(0xFF0A0A0A),
    deepBackground: Color(0xFF050505),
    titleBar: Color(0xFF111111),
    editorBackground: Color(0xFF141414),
    editorLineHighlight: Color(0xFF1E1E1E),
    editorGutter: Color(0xFF141414),
    editorGutterForeground: Color(0xFF858585),
    panelBackground: Color(0xFF1E1E1E),
    inputBackground: Color(0xFF111111),
    borderColor: Color(0xFF2A2A2A),
    dividerColor: Color(0xFF2A2A2A),
    accent: Color(0xFF4EC9B0),
    accentLight: Color(0xFF6DD4BE),
    accentHover: Color(0xFF3AB49A),
    accentDark: Color(0xFF267A68),
    success: Color(0xFF4EC9B0),
    warning: Color(0xFFCCA700),
    error: Color(0xFFF44747),
    info: Color(0xFF4FC1FF),
    userMessageBg: Color(0xFF1E1E1E),
    assistantMessageBg: Color(0xFF141414),
    codeBlockBg: Color(0xFF0D1117),
    syntaxKeyword: Color(0xFF569CD6),
    syntaxString: Color(0xFFCE9178),
    syntaxComment: Color(0xFF6A9955),
    syntaxFunction: Color(0xFFDCDCAA),
    syntaxType: Color(0xFF4EC9B0),
    syntaxNumber: Color(0xFFB5CEA8),
    syntaxVariable: Color(0xFF9CDCFE),
    tabActive: Color(0xFF141414),
    tabInactive: Color(0xFF111111),
    tabBorder: Color(0xFF4EC9B0),
    frostedBg: Color(0x0AFFFFFF),
    frostedBorder: Color(0x12FFFFFF),
    gitBadgeText: Color(0xFF4CAF50),
    gitBadgeBg: Color(0xFF0F3D1F),
    gitBadgeBorder: Color(0xFF1A6B35),
    inputSurface: Color(0xFF1A1A1A),
    deepBorder: Color(0xFF222222),
    mutedFg: Color(0xFF555555),
    faintFg: Color(0xFF333333),
    blueAccent: Color(0xFF4EC9B0),
    dimFg: Color(0xFF888888),
    headingText: Color(0xFFE0E0E0),
    worktreeBadgeBg: Color(0xFF2A1F0A),
    worktreeBadgeFg: Color(0xFFE8A228),
    selectionBg: Color(0xFF0D2B27),
    selectionBorder: Color(0xFF1A4840),
    questionCardBg: Color(0xFF0D2B27),
    prMergedColor: Color(0xFF6E40C9),
    pendingAmber: Color(0xFFFFAA00),
    editedBadgeBg: Color(0xFF3D2900),
    editedBadgeBorder: Color(0xFFAA7700),
    githubBrandColor: Color(0xFF24292E),
    diffAdditionBg: Color(0x3300CC66),
    diffDeletionBg: Color(0x33FF4444),
    onAccent: Color(0xFF0A0A0A),
    frostedSurface: Color(0xF7161616),
    destructiveBorder: Color(0xFF3D1515),
    panelSeparator: Color(0xFF242424),
    iconInactive: Color(0xFF444444),
    shadowDark: Color(0x99000000),
    shadowMedium: Color(0x66000000),
    shadowHeavy: Color(0xB3000000),
    shadowDeep: Color(0xD9000000),
    innerGlow: Color(0x0AFFFFFF),
    successTintBg: Color(0x1F4EC9B0),
    errorTintBg: Color(0x1FF44747),
    warningTintBg: Color(0x1FCCA700),
    infoTintBg: Color(0x1F4FC1FF),
    successBadgeBg: Color(0x1A4EC9B0),
    errorBadgeBg: Color(0x1AF44747),
    warningBadgeBg: Color(0x1ACCA700),
    brandingGradientTop: Color(0xFF0E1A18),
    brandingGradientMid: Color(0xFF0A0E0D),
    accentGlow: Color(0x404EC9B0),
    subtleTealFg: Color(0xFF4A6660),
    accentTintLight: Color(0x0A4EC9B0),
    accentTintMid: Color(0x144EC9B0),
    // Elevated Glass light ★
    glassFill: Color(0xB8FFFFFF),
    glassBorder: Color(0xE6FFFFFF),
    subtleBorder: Color(0x17000000),
    faintBorder: Color(0x0F000000),
    chipFill: Color(0x0A000000),
    chipStroke: Color(0x1A000000),
    chipText: Color(0xFF7A8494),
    userBubbleFill: Color(0x1F4EC9B0),
    userBubbleStroke: Color(0x4D4EC9B0),
    userBubbleHighlight: Color(0x00000000),
    topBarFill: Color(0xCCF0F2F5),
    statusBarFill: Color(0xFFE8EAEE),
    chatBoxRimGlow: Color(0x124EC9B0),
    accentGlowBadge: Color(0x2E4EC9B0),
    accentBorderTeal: Color(0x4D4EC9B0),
    accentBorderAmber: Color(0x4DE8A228),
    sendGlow: Color(0x664EC9B0),
    inlineCodeFill: Color(0x1F4EC9B0),
    inlineCodeStroke: Color(0x334EC9B0),
    inlineCodeText: Color(0xFF2A7A6E),
    dialogFill: Color(0xE0FFFFFF),
    dialogBorder: Color(0xF2FFFFFF),
    dialogHighlight: Color(0xFFFFFFFF),
    fieldFill: Color(0xB8FFFFFF),
    fieldStroke: Color(0x17000000),
    fieldFocusGlow: Color(0x1F4EC9B0),
    sendDisabledFill: Color(0x0D000000),
    sendDisabledStroke: Color(0x21000000),
    sendDisabledIconColor: Color(0x40000000),
  );

  // ── ThemeExtension overrides ──────────────────────────────────────────────

  @override
  AppColors copyWith({
    Color? background, Color? sidebarBackground, Color? activityBar,
    Color? deepBackground, Color? titleBar, Color? editorBackground,
    Color? editorLineHighlight, Color? editorGutter, Color? editorGutterForeground,
    Color? panelBackground, Color? inputBackground, Color? borderColor,
    Color? dividerColor, Color? textPrimary, Color? textSecondary, Color? textMuted,
    Color? accent, Color? accentLight, Color? accentHover, Color? accentDark,
    Color? success, Color? warning, Color? error, Color? info,
    Color? userMessageBg, Color? assistantMessageBg, Color? codeBlockBg,
    Color? syntaxKeyword, Color? syntaxString, Color? syntaxComment,
    Color? syntaxFunction, Color? syntaxType, Color? syntaxNumber, Color? syntaxVariable,
    Color? tabActive, Color? tabInactive, Color? tabBorder,
    Color? frostedBg, Color? frostedBorder,
    Color? gitBadgeText, Color? gitBadgeBg, Color? gitBadgeBorder,
    Color? inputSurface, Color? deepBorder, Color? mutedFg, Color? faintFg,
    Color? blueAccent, Color? dimFg, Color? headingText,
    Color? worktreeBadgeBg, Color? worktreeBadgeFg,
    Color? selectionBg, Color? selectionBorder, Color? questionCardBg,
    Color? prMergedColor, Color? pendingAmber,
    Color? editedBadgeBg, Color? editedBadgeBorder, Color? githubBrandColor,
    Color? diffAdditionBg, Color? diffDeletionBg,
    Color? onAccent, Color? frostedSurface, Color? destructiveBorder,
    Color? panelSeparator, Color? iconInactive,
    Color? shadowDark, Color? shadowMedium, Color? shadowHeavy,
    Color? shadowDeep, Color? innerGlow,
    Color? successTintBg, Color? errorTintBg, Color? warningTintBg, Color? infoTintBg,
    Color? successBadgeBg, Color? errorBadgeBg, Color? warningBadgeBg,
    Color? brandingGradientTop, Color? brandingGradientMid,
    Color? accentGlow, Color? subtleTealFg, Color? accentTintLight, Color? accentTintMid,
    Color? glassFill, Color? glassBorder, Color? subtleBorder, Color? faintBorder,
    Color? chipFill, Color? chipStroke, Color? chipText,
    Color? userBubbleFill, Color? userBubbleStroke, Color? userBubbleHighlight,
    Color? topBarFill, Color? statusBarFill,
    Color? chatBoxRimGlow, Color? accentGlowBadge, Color? accentBorderTeal,
    Color? accentBorderAmber, Color? sendGlow,
    Color? inlineCodeFill, Color? inlineCodeStroke, Color? inlineCodeText,
    Color? dialogFill, Color? dialogBorder, Color? dialogHighlight,
    Color? fieldFill, Color? fieldStroke, Color? fieldFocusGlow,
    Color? sendDisabledFill, Color? sendDisabledStroke, Color? sendDisabledIconColor,
  }) => AppColors(
    background: background ?? this.background,
    sidebarBackground: sidebarBackground ?? this.sidebarBackground,
    activityBar: activityBar ?? this.activityBar,
    deepBackground: deepBackground ?? this.deepBackground,
    titleBar: titleBar ?? this.titleBar,
    editorBackground: editorBackground ?? this.editorBackground,
    editorLineHighlight: editorLineHighlight ?? this.editorLineHighlight,
    editorGutter: editorGutter ?? this.editorGutter,
    editorGutterForeground: editorGutterForeground ?? this.editorGutterForeground,
    panelBackground: panelBackground ?? this.panelBackground,
    inputBackground: inputBackground ?? this.inputBackground,
    borderColor: borderColor ?? this.borderColor,
    dividerColor: dividerColor ?? this.dividerColor,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    accent: accent ?? this.accent,
    accentLight: accentLight ?? this.accentLight,
    accentHover: accentHover ?? this.accentHover,
    accentDark: accentDark ?? this.accentDark,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    info: info ?? this.info,
    userMessageBg: userMessageBg ?? this.userMessageBg,
    assistantMessageBg: assistantMessageBg ?? this.assistantMessageBg,
    codeBlockBg: codeBlockBg ?? this.codeBlockBg,
    syntaxKeyword: syntaxKeyword ?? this.syntaxKeyword,
    syntaxString: syntaxString ?? this.syntaxString,
    syntaxComment: syntaxComment ?? this.syntaxComment,
    syntaxFunction: syntaxFunction ?? this.syntaxFunction,
    syntaxType: syntaxType ?? this.syntaxType,
    syntaxNumber: syntaxNumber ?? this.syntaxNumber,
    syntaxVariable: syntaxVariable ?? this.syntaxVariable,
    tabActive: tabActive ?? this.tabActive,
    tabInactive: tabInactive ?? this.tabInactive,
    tabBorder: tabBorder ?? this.tabBorder,
    frostedBg: frostedBg ?? this.frostedBg,
    frostedBorder: frostedBorder ?? this.frostedBorder,
    gitBadgeText: gitBadgeText ?? this.gitBadgeText,
    gitBadgeBg: gitBadgeBg ?? this.gitBadgeBg,
    gitBadgeBorder: gitBadgeBorder ?? this.gitBadgeBorder,
    inputSurface: inputSurface ?? this.inputSurface,
    deepBorder: deepBorder ?? this.deepBorder,
    mutedFg: mutedFg ?? this.mutedFg,
    faintFg: faintFg ?? this.faintFg,
    blueAccent: blueAccent ?? this.blueAccent,
    dimFg: dimFg ?? this.dimFg,
    headingText: headingText ?? this.headingText,
    worktreeBadgeBg: worktreeBadgeBg ?? this.worktreeBadgeBg,
    worktreeBadgeFg: worktreeBadgeFg ?? this.worktreeBadgeFg,
    selectionBg: selectionBg ?? this.selectionBg,
    selectionBorder: selectionBorder ?? this.selectionBorder,
    questionCardBg: questionCardBg ?? this.questionCardBg,
    prMergedColor: prMergedColor ?? this.prMergedColor,
    pendingAmber: pendingAmber ?? this.pendingAmber,
    editedBadgeBg: editedBadgeBg ?? this.editedBadgeBg,
    editedBadgeBorder: editedBadgeBorder ?? this.editedBadgeBorder,
    githubBrandColor: githubBrandColor ?? this.githubBrandColor,
    diffAdditionBg: diffAdditionBg ?? this.diffAdditionBg,
    diffDeletionBg: diffDeletionBg ?? this.diffDeletionBg,
    onAccent: onAccent ?? this.onAccent,
    frostedSurface: frostedSurface ?? this.frostedSurface,
    destructiveBorder: destructiveBorder ?? this.destructiveBorder,
    panelSeparator: panelSeparator ?? this.panelSeparator,
    iconInactive: iconInactive ?? this.iconInactive,
    shadowDark: shadowDark ?? this.shadowDark,
    shadowMedium: shadowMedium ?? this.shadowMedium,
    shadowHeavy: shadowHeavy ?? this.shadowHeavy,
    shadowDeep: shadowDeep ?? this.shadowDeep,
    innerGlow: innerGlow ?? this.innerGlow,
    successTintBg: successTintBg ?? this.successTintBg,
    errorTintBg: errorTintBg ?? this.errorTintBg,
    warningTintBg: warningTintBg ?? this.warningTintBg,
    infoTintBg: infoTintBg ?? this.infoTintBg,
    successBadgeBg: successBadgeBg ?? this.successBadgeBg,
    errorBadgeBg: errorBadgeBg ?? this.errorBadgeBg,
    warningBadgeBg: warningBadgeBg ?? this.warningBadgeBg,
    brandingGradientTop: brandingGradientTop ?? this.brandingGradientTop,
    brandingGradientMid: brandingGradientMid ?? this.brandingGradientMid,
    accentGlow: accentGlow ?? this.accentGlow,
    subtleTealFg: subtleTealFg ?? this.subtleTealFg,
    accentTintLight: accentTintLight ?? this.accentTintLight,
    accentTintMid: accentTintMid ?? this.accentTintMid,
    glassFill: glassFill ?? this.glassFill,
    glassBorder: glassBorder ?? this.glassBorder,
    subtleBorder: subtleBorder ?? this.subtleBorder,
    faintBorder: faintBorder ?? this.faintBorder,
    chipFill: chipFill ?? this.chipFill,
    chipStroke: chipStroke ?? this.chipStroke,
    chipText: chipText ?? this.chipText,
    userBubbleFill: userBubbleFill ?? this.userBubbleFill,
    userBubbleStroke: userBubbleStroke ?? this.userBubbleStroke,
    userBubbleHighlight: userBubbleHighlight ?? this.userBubbleHighlight,
    topBarFill: topBarFill ?? this.topBarFill,
    statusBarFill: statusBarFill ?? this.statusBarFill,
    chatBoxRimGlow: chatBoxRimGlow ?? this.chatBoxRimGlow,
    accentGlowBadge: accentGlowBadge ?? this.accentGlowBadge,
    accentBorderTeal: accentBorderTeal ?? this.accentBorderTeal,
    accentBorderAmber: accentBorderAmber ?? this.accentBorderAmber,
    sendGlow: sendGlow ?? this.sendGlow,
    inlineCodeFill: inlineCodeFill ?? this.inlineCodeFill,
    inlineCodeStroke: inlineCodeStroke ?? this.inlineCodeStroke,
    inlineCodeText: inlineCodeText ?? this.inlineCodeText,
    dialogFill: dialogFill ?? this.dialogFill,
    dialogBorder: dialogBorder ?? this.dialogBorder,
    dialogHighlight: dialogHighlight ?? this.dialogHighlight,
    fieldFill: fieldFill ?? this.fieldFill,
    fieldStroke: fieldStroke ?? this.fieldStroke,
    fieldFocusGlow: fieldFocusGlow ?? this.fieldFocusGlow,
    sendDisabledFill: sendDisabledFill ?? this.sendDisabledFill,
    sendDisabledStroke: sendDisabledStroke ?? this.sendDisabledStroke,
    sendDisabledIconColor: sendDisabledIconColor ?? this.sendDisabledIconColor,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      sidebarBackground: l(sidebarBackground, other.sidebarBackground),
      activityBar: l(activityBar, other.activityBar),
      deepBackground: l(deepBackground, other.deepBackground),
      titleBar: l(titleBar, other.titleBar),
      editorBackground: l(editorBackground, other.editorBackground),
      editorLineHighlight: l(editorLineHighlight, other.editorLineHighlight),
      editorGutter: l(editorGutter, other.editorGutter),
      editorGutterForeground: l(editorGutterForeground, other.editorGutterForeground),
      panelBackground: l(panelBackground, other.panelBackground),
      inputBackground: l(inputBackground, other.inputBackground),
      borderColor: l(borderColor, other.borderColor),
      dividerColor: l(dividerColor, other.dividerColor),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      accentLight: l(accentLight, other.accentLight),
      accentHover: l(accentHover, other.accentHover),
      accentDark: l(accentDark, other.accentDark),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      error: l(error, other.error),
      info: l(info, other.info),
      userMessageBg: l(userMessageBg, other.userMessageBg),
      assistantMessageBg: l(assistantMessageBg, other.assistantMessageBg),
      codeBlockBg: l(codeBlockBg, other.codeBlockBg),
      syntaxKeyword: l(syntaxKeyword, other.syntaxKeyword),
      syntaxString: l(syntaxString, other.syntaxString),
      syntaxComment: l(syntaxComment, other.syntaxComment),
      syntaxFunction: l(syntaxFunction, other.syntaxFunction),
      syntaxType: l(syntaxType, other.syntaxType),
      syntaxNumber: l(syntaxNumber, other.syntaxNumber),
      syntaxVariable: l(syntaxVariable, other.syntaxVariable),
      tabActive: l(tabActive, other.tabActive),
      tabInactive: l(tabInactive, other.tabInactive),
      tabBorder: l(tabBorder, other.tabBorder),
      frostedBg: l(frostedBg, other.frostedBg),
      frostedBorder: l(frostedBorder, other.frostedBorder),
      gitBadgeText: l(gitBadgeText, other.gitBadgeText),
      gitBadgeBg: l(gitBadgeBg, other.gitBadgeBg),
      gitBadgeBorder: l(gitBadgeBorder, other.gitBadgeBorder),
      inputSurface: l(inputSurface, other.inputSurface),
      deepBorder: l(deepBorder, other.deepBorder),
      mutedFg: l(mutedFg, other.mutedFg),
      faintFg: l(faintFg, other.faintFg),
      blueAccent: l(blueAccent, other.blueAccent),
      dimFg: l(dimFg, other.dimFg),
      headingText: l(headingText, other.headingText),
      worktreeBadgeBg: l(worktreeBadgeBg, other.worktreeBadgeBg),
      worktreeBadgeFg: l(worktreeBadgeFg, other.worktreeBadgeFg),
      selectionBg: l(selectionBg, other.selectionBg),
      selectionBorder: l(selectionBorder, other.selectionBorder),
      questionCardBg: l(questionCardBg, other.questionCardBg),
      prMergedColor: l(prMergedColor, other.prMergedColor),
      pendingAmber: l(pendingAmber, other.pendingAmber),
      editedBadgeBg: l(editedBadgeBg, other.editedBadgeBg),
      editedBadgeBorder: l(editedBadgeBorder, other.editedBadgeBorder),
      githubBrandColor: l(githubBrandColor, other.githubBrandColor),
      diffAdditionBg: l(diffAdditionBg, other.diffAdditionBg),
      diffDeletionBg: l(diffDeletionBg, other.diffDeletionBg),
      onAccent: l(onAccent, other.onAccent),
      frostedSurface: l(frostedSurface, other.frostedSurface),
      destructiveBorder: l(destructiveBorder, other.destructiveBorder),
      panelSeparator: l(panelSeparator, other.panelSeparator),
      iconInactive: l(iconInactive, other.iconInactive),
      shadowDark: l(shadowDark, other.shadowDark),
      shadowMedium: l(shadowMedium, other.shadowMedium),
      shadowHeavy: l(shadowHeavy, other.shadowHeavy),
      shadowDeep: l(shadowDeep, other.shadowDeep),
      innerGlow: l(innerGlow, other.innerGlow),
      successTintBg: l(successTintBg, other.successTintBg),
      errorTintBg: l(errorTintBg, other.errorTintBg),
      warningTintBg: l(warningTintBg, other.warningTintBg),
      infoTintBg: l(infoTintBg, other.infoTintBg),
      successBadgeBg: l(successBadgeBg, other.successBadgeBg),
      errorBadgeBg: l(errorBadgeBg, other.errorBadgeBg),
      warningBadgeBg: l(warningBadgeBg, other.warningBadgeBg),
      brandingGradientTop: l(brandingGradientTop, other.brandingGradientTop),
      brandingGradientMid: l(brandingGradientMid, other.brandingGradientMid),
      accentGlow: l(accentGlow, other.accentGlow),
      subtleTealFg: l(subtleTealFg, other.subtleTealFg),
      accentTintLight: l(accentTintLight, other.accentTintLight),
      accentTintMid: l(accentTintMid, other.accentTintMid),
      glassFill: l(glassFill, other.glassFill),
      glassBorder: l(glassBorder, other.glassBorder),
      subtleBorder: l(subtleBorder, other.subtleBorder),
      faintBorder: l(faintBorder, other.faintBorder),
      chipFill: l(chipFill, other.chipFill),
      chipStroke: l(chipStroke, other.chipStroke),
      chipText: l(chipText, other.chipText),
      userBubbleFill: l(userBubbleFill, other.userBubbleFill),
      userBubbleStroke: l(userBubbleStroke, other.userBubbleStroke),
      userBubbleHighlight: l(userBubbleHighlight, other.userBubbleHighlight),
      topBarFill: l(topBarFill, other.topBarFill),
      statusBarFill: l(statusBarFill, other.statusBarFill),
      chatBoxRimGlow: l(chatBoxRimGlow, other.chatBoxRimGlow),
      accentGlowBadge: l(accentGlowBadge, other.accentGlowBadge),
      accentBorderTeal: l(accentBorderTeal, other.accentBorderTeal),
      accentBorderAmber: l(accentBorderAmber, other.accentBorderAmber),
      sendGlow: l(sendGlow, other.sendGlow),
      inlineCodeFill: l(inlineCodeFill, other.inlineCodeFill),
      inlineCodeStroke: l(inlineCodeStroke, other.inlineCodeStroke),
      inlineCodeText: l(inlineCodeText, other.inlineCodeText),
      dialogFill: l(dialogFill, other.dialogFill),
      dialogBorder: l(dialogBorder, other.dialogBorder),
      dialogHighlight: l(dialogHighlight, other.dialogHighlight),
      fieldFill: l(fieldFill, other.fieldFill),
      fieldStroke: l(fieldStroke, other.fieldStroke),
      fieldFocusGlow: l(fieldFocusGlow, other.fieldFocusGlow),
      sendDisabledFill: l(sendDisabledFill, other.sendDisabledFill),
      sendDisabledStroke: l(sendDisabledStroke, other.sendDisabledStroke),
      sendDisabledIconColor: l(sendDisabledIconColor, other.sendDisabledIconColor),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/core/theme/app_colors.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_colors.dart
git commit -m "feat(tokens): add AppColors ThemeExtension with all colour tokens"
```

---

## Task 2: Update `ThemeConstants` — remove colour fields

**Files:**
- Modify: `lib/core/constants/theme_constants.dart`

- [ ] **Step 1: Replace the file contents**

Keep only the non-colour constants (sizes, fonts). The new file:

```dart
import 'package:flutter/material.dart';

/// Non-colour design constants. Colour tokens live in AppColors.
class ThemeConstants {
  ThemeConstants._();

  // Icon sizes
  static const double iconSizeSmall = 14;
  static const double iconSizeMedium = 18;
  static const double iconSizeLarge = 24;

  // Action button height — exact height of small action buttons in the top bar
  static const double actionButtonHeight = 22;

  // Font
  static const String editorFontFamily = 'JetBrains Mono';
  static const double editorFontSize = 13;
  static const double uiFontSize = 12;
  static const double uiFontSizeSmall = 11;
  static const double uiFontSizeLabel = 10;
  static const double uiFontSizeBadge = 9;
  static const double uiFontSizeLarge = 15;
}
```

- [ ] **Step 2: Run analysis — expect many errors (all ThemeConstants.colorXxx usages)**

```bash
flutter analyze 2>&1 | grep "ThemeConstants" | head -40
```

This confirms which files need migration (Task 4). Do NOT fix errors yet — Task 4 handles them.

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/theme_constants.dart
git commit -m "refactor(tokens): strip colour fields from ThemeConstants — colours now in AppColors"
```

---

## Task 3: Update `AppTheme` — register extensions + update `InputDecorationTheme`

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Add import**

At the top of `lib/core/theme/app_theme.dart`:

```dart
import 'app_colors.dart';
```

- [ ] **Step 2: Update `AppTheme.dark` to register extension + glass `InputDecorationTheme`**

In the `static ThemeData get dark` getter, add `extensions: [AppColors.dark]` to the `copyWith` call, and replace the `inputDecorationTheme`:

```dart
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.dark.background,
      extensions: const [AppColors.dark],
      colorScheme: ColorScheme.dark(
        primary: AppColors.dark.accent,
        onPrimary: AppColors.dark.onAccent,
        secondary: AppColors.dark.accent,
        surface: AppColors.dark.panelBackground,
        onSurface: AppColors.dark.textPrimary,
        error: AppColors.dark.error,
      ),
      // keep existing textTheme, dividerTheme, scrollbarTheme, tooltipTheme
      // just update inputDecorationTheme:
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.dark.fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.dark.fieldStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.dark.fieldStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.dark.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        hintStyle: TextStyle(color: AppColors.dark.textMuted),
        labelStyle: TextStyle(color: AppColors.dark.textSecondary),
      ),
    );
  }
```

- [ ] **Step 3: Add `AppTheme.light` static getter**

```dart
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.light.background,
      extensions: const [AppColors.light],
      colorScheme: ColorScheme.light(
        primary: AppColors.light.accent,
        onPrimary: Colors.white,
        secondary: AppColors.light.accent,
        onSecondary: Colors.white,
        surface: AppColors.light.glassFill,
        onSurface: AppColors.light.textPrimary,
        error: AppColors.light.error,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyMedium: GoogleFonts.inter(
          color: AppColors.light.textPrimary,
          fontSize: ThemeConstants.uiFontSize,
        ),
        bodySmall: GoogleFonts.inter(
          color: AppColors.light.textSecondary,
          fontSize: 12,
        ),
        titleMedium: GoogleFonts.inter(
          color: AppColors.light.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.light.faintBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.light.fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.light.fieldStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.light.fieldStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.light.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        hintStyle: TextStyle(color: AppColors.light.textMuted),
        labelStyle: TextStyle(color: AppColors.light.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.light.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          AppColors.light.textMuted.withAlpha(100),
        ),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.light.glassFill,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.light.subtleBorder),
        ),
        textStyle: TextStyle(color: AppColors.light.textPrimary, fontSize: 12),
        waitDuration: const Duration(milliseconds: 500),
      ),
    );
  }
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/core/theme/app_theme.dart
```

Expected: only errors from files that still reference removed ThemeConstants colour fields — those are Task 4's job.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat(theme): register AppColors extension on dark+light ThemeData"
```

---

## Task 4: Migrate all existing `ThemeConstants` colour usages

**Files:**
- Modify: every file in `lib/` that references a colour field that no longer exists on `ThemeConstants`

- [ ] **Step 1: Get the full error list**

```bash
flutter analyze 2>&1 | grep "undefined_identifier\|The getter" | grep -v "app_theme\|app_colors\|theme_constants" | sed "s/.*• //" | sort -u | head -60
```

This lists all undefined `ThemeConstants.xxx` references. Each one becomes `AppColors.of(context).xxx`.

- [ ] **Step 2: Get the list of affected files**

```bash
flutter analyze 2>&1 | grep "lib/" | grep -oE "lib/[^:]*\.dart" | sort -u
```

- [ ] **Step 3: For each file, add the AppColors import and replace references**

Pattern for each file:

1. Add import at top (after existing imports):
```dart
import 'package:code_bench/core/theme/app_colors.dart';
```
(Adjust the relative path as needed — some files may use relative imports like `'../../../core/theme/app_colors.dart'`.)

2. In every `build` method or builder callback, add at the top:
```dart
final c = AppColors.of(context);
```

3. Replace every `ThemeConstants.colorField` reference with `c.colorField`.

4. Drop `const` from `TextStyle(...)`, `BoxDecoration(...)`, or `BorderSide(...)` that now use `c.fieldName` (runtime values can't be const).

**Example — before:**
```dart
decoration: const BoxDecoration(
  color: ThemeConstants.inputSurface,
  border: Border(bottom: BorderSide(color: ThemeConstants.deepBorder)),
),
child: Text('label', style: const TextStyle(color: ThemeConstants.textSecondary)),
```

**Example — after:**
```dart
final c = AppColors.of(context);
// ...
decoration: BoxDecoration(
  color: c.inputSurface,
  border: Border(bottom: BorderSide(color: c.deepBorder)),
),
child: Text('label', style: TextStyle(color: c.textSecondary)),
```

- [ ] **Step 4: Verify zero errors**

```bash
flutter analyze
```

Expected: zero issues (or only pre-existing unrelated warnings).

- [ ] **Step 5: Run tests**

```bash
flutter test
```

Expected: all pass — this task is purely mechanical; no logic changes.

- [ ] **Step 6: Commit**

```bash
git add lib/
git commit -m "refactor(tokens): migrate all ThemeConstants colour refs to AppColors.of(context)"
```

---

## Task 5: Status bar

**Files:**
- Modify: `lib/shell/widgets/status_bar.dart`

- [ ] **Step 1: Update background, remove border**

```dart
final c = AppColors.of(context);
// In the Container decoration:
decoration: BoxDecoration(
  color: c.statusBarFill,
  // Remove old border: Border(top: ...) entirely
),
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/shell/widgets/status_bar.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/shell/widgets/status_bar.dart
git commit -m "feat(status-bar): use statusBarFill token, remove border-top"
```

---

## Task 6: Top action bar + commit button

**Files:**
- Modify: `lib/shell/widgets/top_action_bar.dart`
- Modify: `lib/shell/widgets/commit_push_button.dart`

- [ ] **Step 1: Update `TopActionBar` container**

```dart
final c = AppColors.of(context);
// Container decoration:
decoration: BoxDecoration(
  color: c.topBarFill,
  border: Border(bottom: BorderSide(color: c.subtleBorder)),
),
```

- [ ] **Step 2: Add `_GlassPill` + wrap dropdowns**

Replace the `ActionsDropdown` and `CodeDropdown` call sites with:

```dart
_GlassPill(child: ActionsDropdown(project: s.project!)),
const SizedBox(width: 5),
_GlassPill(child: CodeDropdown(projectId: s.project!.id, projectPath: s.project!.path)),
```

Add at the bottom of `top_action_bar.dart`:

```dart
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.chipFill,
        border: Border.all(color: c.chipStroke),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 3: Update commit button gradient**

In `lib/shell/widgets/commit_push_button.dart`, replace the left-half `Container` decoration:

```dart
final c = AppColors.of(context);
// ...
decoration: BoxDecoration(
  gradient: (busy || !s.canCommit)
      ? null
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.accent, c.accentHover],
        ),
  color: busy
      ? c.accentHover
      : s.canCommit
      ? null
      : c.inputSurface,
  borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
  boxShadow: (busy || !s.canCommit)
      ? null
      : [BoxShadow(color: c.sendGlow, blurRadius: 10, offset: const Offset(0, 2))],
),
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/shell/widgets/top_action_bar.dart lib/shell/widgets/commit_push_button.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/shell/widgets/top_action_bar.dart lib/shell/widgets/commit_push_button.dart
git commit -m "feat(top-bar): glass background, pill buttons, gradient commit button"
```

---

## Task 7: App dialog

**Files:**
- Modify: `lib/core/widgets/app_dialog.dart`

- [ ] **Step 1: Add `dart:ui` import**

```dart
import 'dart:ui';
```

- [ ] **Step 2: Wrap dialog container in glass**

Inside `Dialog > ConstrainedBox`, replace the existing `Container` with:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(13),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
    child: Builder(builder: (context) {
      final c = AppColors.of(context);
      return Container(
        decoration: BoxDecoration(
          color: c.dialogFill,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: c.dialogBorder),
          boxShadow: [
            BoxShadow(
              color: c.shadowDeep,
              blurRadius: 64,
              offset: const Offset(0, 24),
            ),
            BoxShadow(
              color: c.dialogHighlight,
              blurRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // header padding + badge + title/subtitle (unchanged structure)
            // ...keep existing header widget tree, just update colour references:
            //   textPrimary → c.textPrimary
            //   textSecondary → c.textSecondary
            //   accentBorderTeal → c.accentBorderTeal
            //   accentGlowBadge → c.accentGlowBadge
            // footer divider:
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.faintBorder)),
              ),
              // ...existing footer content
            ),
          ],
        ),
      );
    }),
  ),
),
```

- [ ] **Step 3: Update `_ActionButton` for gradient primary**

Replace `_ActionButton.build`:

```dart
@override
Widget build(BuildContext context) {
  final c = AppColors.of(context);
  switch (action._style) {
    case _ActionStyle.primary:
      return GestureDetector(
        onTap: action.onPressed,
        child: Opacity(
          opacity: action.onPressed == null ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.accent, c.accentHover],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [BoxShadow(color: c.sendGlow, blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Text(action.label,
              style: TextStyle(color: c.onAccent, fontSize: 11, fontWeight: FontWeight.w600)),
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
              color: c.chipFill,
              border: Border.all(color: c.chipStroke),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(action.label,
              style: TextStyle(color: c.textPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
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
              border: Border.all(color: c.destructiveBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(action.label,
              style: TextStyle(color: c.error, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ),
      );
  }
}
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/core/widgets/app_dialog.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/app_dialog.dart
git commit -m "feat(dialog): dark glass surface, blur, badge glow, gradient primary button"
```

---

## Task 8: Chat input bar

**Files:**
- Modify: `lib/features/chat/widgets/chat_input_bar.dart`

- [ ] **Step 1: Update outer container — remove border, match background**

```dart
final c = AppColors.of(context);
// Outer Container decoration:
decoration: BoxDecoration(color: c.background),
```

- [ ] **Step 2: Inner glass chat box**

```dart
decoration: BoxDecoration(
  color: c.glassFill,
  border: Border.all(color: c.glassBorder),
  borderRadius: BorderRadius.circular(11),
  boxShadow: [
    BoxShadow(color: c.shadowHeavy.withAlpha(0x8C), blurRadius: 24, offset: const Offset(0, -6)),
    BoxShadow(color: c.shadowDark.withAlpha(0x4D), blurRadius: 6, offset: const Offset(0, 2)),
    BoxShadow(color: c.chatBoxRimGlow, blurRadius: 0, spreadRadius: 0.5),
  ],
),
```

- [ ] **Step 3: Toolbar divider**

```dart
decoration: BoxDecoration(
  border: Border(top: BorderSide(color: c.faintBorder)),
),
```

- [ ] **Step 4: Update `_ControlChip` to glass pill**

Replace `_ControlChip.build`:

```dart
@override
Widget build(BuildContext context) {
  final c = AppColors.of(context);
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(5),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.chipFill,
        border: Border.all(color: c.chipStroke),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: c.chipText),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: c.chipText, fontSize: ThemeConstants.uiFontSizeSmall)),
          const SizedBox(width: 3),
          Icon(AppIcons.chevronDown, size: 10, color: c.faintFg),
        ],
      ),
    ),
  );
}
```

Remove the `_Separator` widget and all `const _Separator()` usages (replace each separator + adjacent `SizedBox` with `const SizedBox(width: 4)`).

- [ ] **Step 5: Update send button states**

```dart
final c = AppColors.of(context);
final Color bgColor;
final Border? border;
final Color iconColor;
final List<BoxShadow> shadows;

if (_isSending) {
  bgColor = c.accentHover;
  border = null;
  iconColor = c.onAccent;
  shadows = [];
} else if (hasText && !isMissing) {
  bgColor = c.accent; // overridden by gradient below
  border = null;
  iconColor = c.onAccent;
  shadows = [BoxShadow(color: c.sendGlow, blurRadius: 8, offset: const Offset(0, 2))];
} else {
  bgColor = c.sendDisabledFill;
  border = Border.all(color: c.sendDisabledStroke);
  iconColor = c.sendDisabledIconColor;
  shadows = [];
}

return GestureDetector(
  onTap: _isSending ? null : _send,
  child: Container(
    width: 28, height: 28,
    decoration: BoxDecoration(
      gradient: (!_isSending && hasText && !isMissing)
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.accent, c.accentHover],
            )
          : null,
      color: (_isSending || !hasText || isMissing) ? bgColor : null,
      borderRadius: BorderRadius.circular(7),
      border: border,
      boxShadow: shadows,
    ),
    child: Center(
      child: _isSending
          ? AnimatedBuilder(
              animation: _pulseOpacity,
              builder: (_, __) => Opacity(
                opacity: _pulseOpacity.value,
                child: Container(
                  width: 9, height: 9,
                  decoration: BoxDecoration(
                    color: c.onAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            )
          : Icon(AppIcons.arrowUp, size: 14, color: iconColor),
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
git commit -m "feat(chat-input): glass box, chip pills, glass-ghost disabled send, gradient active send"
```

---

## Task 9: Message bubbles

**Files:**
- Modify: `lib/features/chat/widgets/message_bubble.dart`

- [ ] **Step 1: Locate the user bubble container**

```bash
grep -n "userMessageBg\|user.*bubble\|bubble.*user\|UserBubble" lib/features/chat/widgets/message_bubble.dart | head -20
```

- [ ] **Step 2: Update user bubble**

```dart
final c = AppColors.of(context);
// User bubble Container decoration:
decoration: BoxDecoration(
  color: c.userBubbleFill,
  border: Border.all(color: c.userBubbleStroke),
  borderRadius: BorderRadius.circular(11),
  boxShadow: [
    BoxShadow(color: c.userBubbleHighlight, blurRadius: 0, offset: const Offset(0, 1)),
  ],
),
```

- [ ] **Step 3: Update inline code spans**

```dart
// Inline code background:
color: c.inlineCodeFill,
// Inline code border:
border: Border.all(color: c.inlineCodeStroke),
borderRadius: BorderRadius.circular(4),
// Inline code text colour:
color: c.inlineCodeText,
```

- [ ] **Step 4: Update code block border**

```dart
border: Border.all(color: c.subtleBorder),
borderRadius: BorderRadius.circular(7),
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/features/chat/widgets/message_bubble.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/chat/widgets/message_bubble.dart
git commit -m "feat(bubbles): glass user bubble, themed inline-code, code block border"
```

---

## Task 10: Settings groups + inline text field

**Files:**
- Modify: `lib/features/settings/widgets/settings_group.dart`
- Modify: `lib/features/settings/widgets/inline_text_field.dart`

- [ ] **Step 1: Update `SettingsGroup` container**

```dart
final c = AppColors.of(context);
decoration: BoxDecoration(
  color: c.glassFill,
  border: Border.all(color: c.subtleBorder),
  borderRadius: BorderRadius.circular(9),
),
```

- [ ] **Step 2: Update row dividers**

```dart
Divider(height: 1, color: AppColors.of(context).faintBorder),
```

- [ ] **Step 3: Slim `InlineTextField` — inherit theme padding**

```dart
@override
Widget build(BuildContext context) {
  final c = AppColors.of(context);
  return TextField(
    controller: controller,
    obscureText: obscureText,
    style: TextStyle(
      color: c.textPrimary,
      fontSize: 12,
      fontFamily: ThemeConstants.editorFontFamily,
    ),
    decoration: const InputDecoration(),
  );
}
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/features/settings/widgets/settings_group.dart lib/features/settings/widgets/inline_text_field.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/widgets/settings_group.dart lib/features/settings/widgets/inline_text_field.dart
git commit -m "feat(settings): glass group container, faint dividers, size-B inline text field"
```

---

## Task 11: Settings nav + back button

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Update `_NavItem` active state**

Replace `_NavItem.build`:

```dart
@override
Widget build(BuildContext context) {
  final c = AppColors.of(context);
  return InkWell(
    onTap: onTap,
    child: Container(
      margin: isActive ? const EdgeInsets.only(right: 6) : EdgeInsets.zero,
      padding: EdgeInsets.only(left: isActive ? 11 : 16, right: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? c.accentTintMid : null,
        borderRadius: isActive
            ? const BorderRadius.horizontal(right: Radius.circular(6))
            : null,
        border: isActive
            ? Border(left: BorderSide(color: c.accent, width: 3))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isActive ? c.accent : c.textSecondary),
          const SizedBox(width: 8),
          Text(label,
            style: TextStyle(
              color: isActive ? c.textPrimary : c.textSecondary,
              fontSize: 12,
            )),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 2: Update Back button to glass pill**

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
  child: Builder(builder: (context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onBack,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.chipFill,
          border: Border.all(color: c.chipStroke),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.arrowLeft, size: 11, color: c.textSecondary),
            const SizedBox(width: 6),
            Text('Back', style: TextStyle(color: c.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }),
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

## Task 12: General settings — toggles + glass dropdown

**Files:**
- Modify: `lib/features/settings/general_screen.dart`

- [ ] **Step 1: Replace boolean `_AppDropdown` rows with `Switch` widgets**

Replace the "Delete confirmation" and "Auto-commit" `SettingsRow` blocks:

```dart
SettingsRow(
  label: 'Delete confirmation',
  description: 'Ask before deleting a session',
  trailing: Transform.scale(
    scale: 0.75,
    child: Builder(builder: (context) {
      final c = AppColors.of(context);
      return Switch(
        value: _deleteConfirmation,
        onChanged: (v) async {
          await ref.read(generalPrefsProvider.notifier).setDeleteConfirmation(v);
          setState(() => _deleteConfirmation = v);
        },
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : const Color(0x40FFFFFF)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? c.accent : const Color(0x0DFFFFFF)),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.transparent : const Color(0x17FFFFFF)),
      );
    }),
  ),
),
SettingsRow(
  label: 'Auto-commit',
  description: 'Skip commit dialog; commit immediately with AI-generated message',
  trailing: Transform.scale(
    scale: 0.75,
    child: Builder(builder: (context) {
      final c = AppColors.of(context);
      return Switch(
        value: _autoCommit,
        onChanged: (v) async {
          await ref.read(generalPrefsProvider.notifier).setAutoCommit(v);
          setState(() => _autoCommit = v);
        },
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : const Color(0x40FFFFFF)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? c.accent : const Color(0x0DFFFFFF)),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.transparent : const Color(0x17FFFFFF)),
      );
    }),
  ),
),
```

- [ ] **Step 2: Update `_AppDropdown` to glass style**

In `_AppDropdown.build`, replace the `Container` decoration:

```dart
final c = AppColors.of(context);
decoration: BoxDecoration(
  color: c.chipFill,
  border: Border.all(color: c.chipStroke),
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

## Task 13: Theme mode preference — SharedPrefs + repository + notifier

**Files:**
- Modify: `lib/data/_core/preferences/general_preferences.dart`
- Modify: `lib/data/settings/repository/settings_repository.dart`
- Modify: `lib/data/settings/repository/settings_repository_impl.dart`
- Modify: `lib/features/settings/notifiers/general_prefs_notifier.dart`
- Modify: `lib/services/settings/settings_service.dart` (if it delegates prefs)

- [ ] **Step 1: Add `themeMode` to `GeneralPreferences`**

In `lib/data/_core/preferences/general_preferences.dart`, add import and methods:

```dart
import 'package:flutter/material.dart';
// ...
static const _themeMode = 'theme_mode';

Future<ThemeMode> getThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  return switch (prefs.getString(_themeMode) ?? 'system') {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };
}

Future<void> setThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themeMode, switch (mode) {
    ThemeMode.dark => 'dark',
    ThemeMode.light => 'light',
    ThemeMode.system => 'system',
  });
}
```

- [ ] **Step 2: Add interface methods to `SettingsRepository`**

```dart
import 'package:flutter/material.dart';
// ...
Future<ThemeMode> getThemeMode();
Future<void> setThemeMode(ThemeMode mode);
```

- [ ] **Step 3: Implement in `SettingsRepositoryImpl`**

```dart
@override
Future<ThemeMode> getThemeMode() => _generalPrefs.getThemeMode();

@override
Future<void> setThemeMode(ThemeMode mode) => _generalPrefs.setThemeMode(mode);
```

- [ ] **Step 4: Add `setThemeMode` to `SettingsService`**

```bash
grep -n "getAutoCommit\|setAutoCommit" lib/services/settings/settings_service.dart | head -6
```

Follow the same delegation pattern:

```dart
Future<ThemeMode> getThemeMode() => _repo.getThemeMode();
Future<void> setThemeMode(ThemeMode mode) => _repo.setThemeMode(mode);
```

- [ ] **Step 5: Update `GeneralPrefsNotifierState` + `GeneralPrefsNotifier`**

In `lib/features/settings/notifiers/general_prefs_notifier.dart`:

```dart
import 'package:flutter/material.dart';

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

Update `build()`:

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

Add `setThemeMode`:

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

- [ ] **Step 6: Re-run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Verify**

```bash
flutter analyze lib/data/_core/preferences/ lib/data/settings/repository/ lib/features/settings/notifiers/general_prefs_notifier.dart
```

- [ ] **Step 8: Commit**

```bash
git add lib/data/_core/preferences/general_preferences.dart \
        lib/data/settings/repository/settings_repository.dart \
        lib/data/settings/repository/settings_repository_impl.dart \
        lib/services/settings/settings_service.dart \
        lib/features/settings/notifiers/general_prefs_notifier.dart \
        lib/features/settings/notifiers/general_prefs_notifier.g.dart
git commit -m "feat(prefs): add themeMode to SharedPrefs, SettingsRepository, and GeneralPrefsNotifier"
```

---

## Task 14: Theme wiring — `app.dart` + `GeneralScreen` dropdown

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/features/settings/general_screen.dart`

- [ ] **Step 1: Wire theme in `app.dart`**

Replace `CodeBenchApp.build`:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final router = ref.watch(appRouterProvider);
  final themeMode = ref.watch(generalPrefsProvider).valueOrNull?.themeMode
      ?? ThemeMode.system;

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

Add import:
```dart
import 'features/settings/notifiers/general_prefs_notifier.dart';
```

- [ ] **Step 2: Wire Theme dropdown in `GeneralScreen`**

Add `ThemeMode _themeMode = ThemeMode.system;` field.

Update `_load()` to include:
```dart
_themeMode = s.themeMode;
```

Replace the Theme `SettingsRow`:

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

## Task 15: Branch picker redesign

**Files:**
- Modify: `lib/features/branch_picker/widgets/branch_picker_popover.dart`
- Modify: `lib/features/branch_picker/notifiers/branch_picker_notifier.dart`
- Modify: `lib/features/branch_picker/notifiers/branch_picker_failure.dart`
- Modify: `lib/services/git/git_service.dart`
- Modify: `lib/data/git/datasource/` (`*_process.dart` file)

- [ ] **Step 1: Add `createWorktree` to git datasource**

```bash
grep -rn "createBranch" lib/data/git/datasource/ | head -10
```

In the `*_process.dart` datasource, add after `createBranch`:

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

Add matching method to the `GitDatasource` interface and to `GitService` / `GitServiceImpl`:

```dart
// Interface + impl delegation:
Future<void> createWorktree(String projectPath, String branchName, String worktreePath);
```

- [ ] **Step 2: Add `createWorktreeFailed` to `BranchPickerFailure`**

```dart
const factory BranchPickerFailure.createWorktreeFailed(String message) = BranchPickerCreateWorktreeFailed;
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Add `createWorktree` to `BranchPickerNotifier`**

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

- [ ] **Step 4: Rewrite `BranchPickerPopover` as centred dialog**

Add `import 'dart:ui';` at top.

Add fields to `_BranchPickerPopoverState`:

```dart
bool _createMode = false;
bool _worktreeMode = false;
final _worktreePathController = TextEditingController();
```

Add to `dispose`: `_worktreePathController.dispose();`

Replace `build`:

```dart
@override
Widget build(BuildContext context) {
  final c = AppColors.of(context);
  final asyncState = ref.watch(branchPickerProvider(widget.projectPath));

  return Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: widget.onClose,
          behavior: HitTestBehavior.opaque,
          child: Container(color: const Color(0x33000000)),
        ),
      ),
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
                    color: c.dialogFill,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: c.dialogBorder),
                    boxShadow: [
                      BoxShadow(color: c.shadowDeep, blurRadius: 64, offset: const Offset(0, 24)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DialogHeader(
                        currentBranch: widget.currentBranch,
                        onClose: widget.onClose,
                        createMode: _createMode,
                        worktreeMode: _worktreeMode,
                        onBack: _createMode
                            ? () => setState(() {
                                _createMode = false;
                                _worktreeMode = false;
                                _createController.clear();
                                _worktreePathController.clear();
                              })
                            : null,
                      ),
                      if (!_createMode) ...[
                        _SearchBar(controller: _filterController, focusNode: _filterFocus),
                        Flexible(child: _buildList(asyncState)),
                        _DialogFooter(
                          onNewBranch: () => setState(() { _createMode = true; _worktreeMode = false; }),
                          onNewWorktree: () => setState(() { _createMode = true; _worktreeMode = true; }),
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
  final parent = widget.projectPath.contains('/')
      ? widget.projectPath.substring(0, widget.projectPath.lastIndexOf('/'))
      : widget.projectPath;
  return '$parent/.worktrees/$branch';
}

Future<void> _createWorktree() async {
  final branch = _createController.text.trim();
  final path = _worktreePathController.text.trim();
  if (branch.isEmpty || path.isEmpty) return;
  await ref.read(branchPickerProvider(widget.projectPath).notifier).createWorktree(branch, path);
  if (!mounted) return;
  final s = ref.read(branchPickerProvider(widget.projectPath));
  if (s.hasError && s.error is BranchPickerFailure) {
    switch (s.error as BranchPickerFailure) {
      case BranchPickerCreateWorktreeFailed(:final message):
        AppSnackBar.show(context, 'Worktree failed: $message', type: AppSnackBarType.error);
      default:
        AppSnackBar.show(context, 'Create worktree failed.', type: AppSnackBarType.error);
    }
  } else {
    ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.projectPath);
    widget.onClose();
  }
}
```

- [ ] **Step 5: Add helper sub-widgets at bottom of file**

```dart
class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.currentBranch,
    required this.onClose,
    required this.createMode,
    required this.worktreeMode,
    this.onBack,
  });
  final String? currentBranch;
  final VoidCallback onClose;
  final bool createMode;
  final bool worktreeMode;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          if (onBack != null)
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(5),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(LucideIcons.arrowLeft, size: 14, color: c.textSecondary),
              ),
            ),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: c.accentTintMid,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: c.accentBorderTeal),
              boxShadow: [BoxShadow(color: c.accentGlowBadge, blurRadius: 14)],
            ),
            child: Icon(LucideIcons.gitBranch, size: 13, color: c.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  createMode
                      ? (worktreeMode ? 'New Worktree' : 'New Branch')
                      : 'Switch Branch',
                  style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (currentBranch != null)
                  Text(currentBranch!, style: TextStyle(color: c.accent, fontSize: 10)),
              ],
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 13, color: c.mutedFg),
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
        style: TextStyle(
          color: AppColors.of(context).mutedFg,
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
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.faintBorder))),
      child: Row(
        children: [
          Expanded(
            child: _FooterButton(
              icon: LucideIcons.gitBranch,
              label: 'New Branch',
              iconColor: c.accent,
              borderColor: c.accentBorderTeal,
              onTap: onNewBranch,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FooterButton(
              icon: LucideIcons.layers,
              label: 'New Worktree',
              iconColor: c.worktreeBadgeFg,
              borderColor: c.accentBorderAmber,
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
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.glassFill,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
              style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall)),
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
    final c = AppColors.of(context);
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
            style: TextStyle(color: c.textPrimary, fontSize: 12),
            decoration: const InputDecoration(hintText: 'branch-name'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onSubmit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.accent, c.accentHover]),
                borderRadius: BorderRadius.circular(7),
                boxShadow: [BoxShadow(color: c.sendGlow, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Center(
                child: Text('Create Branch',
                  style: TextStyle(color: c.onAccent, fontSize: 11, fontWeight: FontWeight.w600)),
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
    final c = AppColors.of(context);
    if (pathController.text.isEmpty && defaultPath.isNotEmpty) {
      pathController.text = defaultPath;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Branch name', style: TextStyle(color: c.textSecondary, fontSize: 10)),
          const SizedBox(height: 4),
          TextField(
            controller: branchController,
            autofocus: true,
            style: TextStyle(color: c.textPrimary, fontSize: 12),
            decoration: const InputDecoration(hintText: 'feat/my-feature'),
          ),
          const SizedBox(height: 8),
          Text('Path', style: TextStyle(color: c.textSecondary, fontSize: 10)),
          const SizedBox(height: 4),
          TextField(
            controller: pathController,
            style: TextStyle(color: c.textPrimary, fontSize: 12),
            decoration: const InputDecoration(hintText: '.worktrees/feat-my-feature'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onSubmit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: c.accentTintLight,
                border: Border.all(color: c.accentBorderAmber),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text('Create Worktree',
                  style: TextStyle(color: c.worktreeBadgeFg, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

Update `_SearchBar.build` to use theme field:

```dart
@override
Widget build(BuildContext context) {
  final c = AppColors.of(context);
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
      decoration: InputDecoration(
        hintText: 'Search branches…',
        hintStyle: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: Icon(LucideIcons.search, size: 11, color: c.mutedFg),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    ),
  );
}
```

- [ ] **Step 6: Re-run code generation**

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
  - [ ] Toggle switches on General settings
  - [ ] Theme dropdown in settings switches the whole app (Dark / Light / System)
  - [ ] Light theme: background pale cool grey, chat box frosted white, text dark
  - [ ] Branch picker opens as centred dialog with search, list, footer buttons
  - [ ] New Branch + New Worktree create flows

---

## Self-review notes

- Task 4 (migration) is the largest task — it touches potentially 50+ files. The safest subagent strategy is: remove colours from ThemeConstants first (Task 2), let the analyser enumerate every error, fix file by file. `flutter analyze` output is the todo list.
- `AppColors.dark` and `AppColors.light` are `const` — safe to reference directly in `AppTheme` (no `BuildContext` needed there) and in any `const`-compatible context. Widget `build` methods should still call `AppColors.of(context)` rather than `AppColors.dark` so the extension swap works at runtime.
- Spec says "Drift table" for themeMode — actual storage uses SharedPreferences. Plan follows existing pattern.
- `accentHover` (`#3AB49A`) is used as gradient end throughout; the spec's `accentDark` has a different existing value.
