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

  static AppColors of(BuildContext context) => Theme.of(context).extension<AppColors>()!;

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
    sidebarBackground: Color(0xFFE8EAEE),
    activityBar: Color(0xFFDFE1E6),
    deepBackground: Color(0xFFF0F2F5),
    titleBar: Color(0xFF111111),
    editorBackground: Color(0xFF141414),
    editorLineHighlight: Color(0xFF1E1E1E),
    editorGutter: Color(0xFF141414),
    editorGutterForeground: Color(0xFF858585),
    panelBackground: Color(0xFFF6F8FA),
    inputBackground: Color(0xFF111111),
    borderColor: Color(0x1A000000),
    dividerColor: Color(0x1A000000),
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
    inputSurface: Color(0xFFFFFFFF),
    deepBorder: Color(0x1E000000),
    mutedFg: Color(0xFF8C95A0),
    faintFg: Color(0xFFBFC5CE),
    blueAccent: Color(0xFF4EC9B0),
    dimFg: Color(0xFF9BA4B0),
    headingText: Color(0xFF1E2329),
    worktreeBadgeBg: Color(0xFFFFF3CD),
    worktreeBadgeFg: Color(0xFF7A5200),
    selectionBg: Color(0xFFD5F5EE),
    selectionBorder: Color(0xFFA0DDD2),
    questionCardBg: Color(0xFFD5F5EE),
    prMergedColor: Color(0xFF6E40C9),
    pendingAmber: Color(0xFFFFAA00),
    editedBadgeBg: Color(0xFFFFF3CD),
    editedBadgeBorder: Color(0xFFCC8800),
    githubBrandColor: Color(0xFF24292E),
    diffAdditionBg: Color(0x3300BB55),
    diffDeletionBg: Color(0x33EE3333),
    onAccent: Color(0xFF0A0A0A),
    frostedSurface: Color(0xF0FFFFFF),
    destructiveBorder: Color(0xFFFFCDD2),
    panelSeparator: Color(0x0F000000),
    iconInactive: Color(0xFFB2B9C4),
    shadowDark: Color(0x26000000),
    shadowMedium: Color(0x14000000),
    shadowHeavy: Color(0x33000000),
    shadowDeep: Color(0x40000000),
    innerGlow: Color(0x0AFFFFFF),
    successTintBg: Color(0x1F4EC9B0),
    errorTintBg: Color(0x1FF44747),
    warningTintBg: Color(0x1FCCA700),
    infoTintBg: Color(0x1F4FC1FF),
    successBadgeBg: Color(0x1A4EC9B0),
    errorBadgeBg: Color(0x1AF44747),
    warningBadgeBg: Color(0x1ACCA700),
    brandingGradientTop: Color(0xFFD5F5EE),
    brandingGradientMid: Color(0xFFC0EDE3),
    accentGlow: Color(0x404EC9B0),
    subtleTealFg: Color(0xFF2A7A6E),
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
    Color? background,
    Color? sidebarBackground,
    Color? activityBar,
    Color? deepBackground,
    Color? titleBar,
    Color? editorBackground,
    Color? editorLineHighlight,
    Color? editorGutter,
    Color? editorGutterForeground,
    Color? panelBackground,
    Color? inputBackground,
    Color? borderColor,
    Color? dividerColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentLight,
    Color? accentHover,
    Color? accentDark,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? userMessageBg,
    Color? assistantMessageBg,
    Color? codeBlockBg,
    Color? syntaxKeyword,
    Color? syntaxString,
    Color? syntaxComment,
    Color? syntaxFunction,
    Color? syntaxType,
    Color? syntaxNumber,
    Color? syntaxVariable,
    Color? tabActive,
    Color? tabInactive,
    Color? tabBorder,
    Color? frostedBg,
    Color? frostedBorder,
    Color? gitBadgeText,
    Color? gitBadgeBg,
    Color? gitBadgeBorder,
    Color? inputSurface,
    Color? deepBorder,
    Color? mutedFg,
    Color? faintFg,
    Color? blueAccent,
    Color? dimFg,
    Color? headingText,
    Color? worktreeBadgeBg,
    Color? worktreeBadgeFg,
    Color? selectionBg,
    Color? selectionBorder,
    Color? questionCardBg,
    Color? prMergedColor,
    Color? pendingAmber,
    Color? editedBadgeBg,
    Color? editedBadgeBorder,
    Color? githubBrandColor,
    Color? diffAdditionBg,
    Color? diffDeletionBg,
    Color? onAccent,
    Color? frostedSurface,
    Color? destructiveBorder,
    Color? panelSeparator,
    Color? iconInactive,
    Color? shadowDark,
    Color? shadowMedium,
    Color? shadowHeavy,
    Color? shadowDeep,
    Color? innerGlow,
    Color? successTintBg,
    Color? errorTintBg,
    Color? warningTintBg,
    Color? infoTintBg,
    Color? successBadgeBg,
    Color? errorBadgeBg,
    Color? warningBadgeBg,
    Color? brandingGradientTop,
    Color? brandingGradientMid,
    Color? accentGlow,
    Color? subtleTealFg,
    Color? accentTintLight,
    Color? accentTintMid,
    Color? glassFill,
    Color? glassBorder,
    Color? subtleBorder,
    Color? faintBorder,
    Color? chipFill,
    Color? chipStroke,
    Color? chipText,
    Color? userBubbleFill,
    Color? userBubbleStroke,
    Color? userBubbleHighlight,
    Color? topBarFill,
    Color? statusBarFill,
    Color? chatBoxRimGlow,
    Color? accentGlowBadge,
    Color? accentBorderTeal,
    Color? accentBorderAmber,
    Color? sendGlow,
    Color? inlineCodeFill,
    Color? inlineCodeStroke,
    Color? inlineCodeText,
    Color? dialogFill,
    Color? dialogBorder,
    Color? dialogHighlight,
    Color? fieldFill,
    Color? fieldStroke,
    Color? fieldFocusGlow,
    Color? sendDisabledFill,
    Color? sendDisabledStroke,
    Color? sendDisabledIconColor,
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
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      activityBar: Color.lerp(activityBar, other.activityBar, t)!,
      deepBackground: Color.lerp(deepBackground, other.deepBackground, t)!,
      titleBar: Color.lerp(titleBar, other.titleBar, t)!,
      editorBackground: Color.lerp(editorBackground, other.editorBackground, t)!,
      editorLineHighlight: Color.lerp(editorLineHighlight, other.editorLineHighlight, t)!,
      editorGutter: Color.lerp(editorGutter, other.editorGutter, t)!,
      editorGutterForeground: Color.lerp(editorGutterForeground, other.editorGutterForeground, t)!,
      panelBackground: Color.lerp(panelBackground, other.panelBackground, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      userMessageBg: Color.lerp(userMessageBg, other.userMessageBg, t)!,
      assistantMessageBg: Color.lerp(assistantMessageBg, other.assistantMessageBg, t)!,
      codeBlockBg: Color.lerp(codeBlockBg, other.codeBlockBg, t)!,
      syntaxKeyword: Color.lerp(syntaxKeyword, other.syntaxKeyword, t)!,
      syntaxString: Color.lerp(syntaxString, other.syntaxString, t)!,
      syntaxComment: Color.lerp(syntaxComment, other.syntaxComment, t)!,
      syntaxFunction: Color.lerp(syntaxFunction, other.syntaxFunction, t)!,
      syntaxType: Color.lerp(syntaxType, other.syntaxType, t)!,
      syntaxNumber: Color.lerp(syntaxNumber, other.syntaxNumber, t)!,
      syntaxVariable: Color.lerp(syntaxVariable, other.syntaxVariable, t)!,
      tabActive: Color.lerp(tabActive, other.tabActive, t)!,
      tabInactive: Color.lerp(tabInactive, other.tabInactive, t)!,
      tabBorder: Color.lerp(tabBorder, other.tabBorder, t)!,
      frostedBg: Color.lerp(frostedBg, other.frostedBg, t)!,
      frostedBorder: Color.lerp(frostedBorder, other.frostedBorder, t)!,
      gitBadgeText: Color.lerp(gitBadgeText, other.gitBadgeText, t)!,
      gitBadgeBg: Color.lerp(gitBadgeBg, other.gitBadgeBg, t)!,
      gitBadgeBorder: Color.lerp(gitBadgeBorder, other.gitBadgeBorder, t)!,
      inputSurface: Color.lerp(inputSurface, other.inputSurface, t)!,
      deepBorder: Color.lerp(deepBorder, other.deepBorder, t)!,
      mutedFg: Color.lerp(mutedFg, other.mutedFg, t)!,
      faintFg: Color.lerp(faintFg, other.faintFg, t)!,
      blueAccent: Color.lerp(blueAccent, other.blueAccent, t)!,
      dimFg: Color.lerp(dimFg, other.dimFg, t)!,
      headingText: Color.lerp(headingText, other.headingText, t)!,
      worktreeBadgeBg: Color.lerp(worktreeBadgeBg, other.worktreeBadgeBg, t)!,
      worktreeBadgeFg: Color.lerp(worktreeBadgeFg, other.worktreeBadgeFg, t)!,
      selectionBg: Color.lerp(selectionBg, other.selectionBg, t)!,
      selectionBorder: Color.lerp(selectionBorder, other.selectionBorder, t)!,
      questionCardBg: Color.lerp(questionCardBg, other.questionCardBg, t)!,
      prMergedColor: Color.lerp(prMergedColor, other.prMergedColor, t)!,
      pendingAmber: Color.lerp(pendingAmber, other.pendingAmber, t)!,
      editedBadgeBg: Color.lerp(editedBadgeBg, other.editedBadgeBg, t)!,
      editedBadgeBorder: Color.lerp(editedBadgeBorder, other.editedBadgeBorder, t)!,
      githubBrandColor: Color.lerp(githubBrandColor, other.githubBrandColor, t)!,
      diffAdditionBg: Color.lerp(diffAdditionBg, other.diffAdditionBg, t)!,
      diffDeletionBg: Color.lerp(diffDeletionBg, other.diffDeletionBg, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      frostedSurface: Color.lerp(frostedSurface, other.frostedSurface, t)!,
      destructiveBorder: Color.lerp(destructiveBorder, other.destructiveBorder, t)!,
      panelSeparator: Color.lerp(panelSeparator, other.panelSeparator, t)!,
      iconInactive: Color.lerp(iconInactive, other.iconInactive, t)!,
      shadowDark: Color.lerp(shadowDark, other.shadowDark, t)!,
      shadowMedium: Color.lerp(shadowMedium, other.shadowMedium, t)!,
      shadowHeavy: Color.lerp(shadowHeavy, other.shadowHeavy, t)!,
      shadowDeep: Color.lerp(shadowDeep, other.shadowDeep, t)!,
      innerGlow: Color.lerp(innerGlow, other.innerGlow, t)!,
      successTintBg: Color.lerp(successTintBg, other.successTintBg, t)!,
      errorTintBg: Color.lerp(errorTintBg, other.errorTintBg, t)!,
      warningTintBg: Color.lerp(warningTintBg, other.warningTintBg, t)!,
      infoTintBg: Color.lerp(infoTintBg, other.infoTintBg, t)!,
      successBadgeBg: Color.lerp(successBadgeBg, other.successBadgeBg, t)!,
      errorBadgeBg: Color.lerp(errorBadgeBg, other.errorBadgeBg, t)!,
      warningBadgeBg: Color.lerp(warningBadgeBg, other.warningBadgeBg, t)!,
      brandingGradientTop: Color.lerp(brandingGradientTop, other.brandingGradientTop, t)!,
      brandingGradientMid: Color.lerp(brandingGradientMid, other.brandingGradientMid, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      subtleTealFg: Color.lerp(subtleTealFg, other.subtleTealFg, t)!,
      accentTintLight: Color.lerp(accentTintLight, other.accentTintLight, t)!,
      accentTintMid: Color.lerp(accentTintMid, other.accentTintMid, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      subtleBorder: Color.lerp(subtleBorder, other.subtleBorder, t)!,
      faintBorder: Color.lerp(faintBorder, other.faintBorder, t)!,
      chipFill: Color.lerp(chipFill, other.chipFill, t)!,
      chipStroke: Color.lerp(chipStroke, other.chipStroke, t)!,
      chipText: Color.lerp(chipText, other.chipText, t)!,
      userBubbleFill: Color.lerp(userBubbleFill, other.userBubbleFill, t)!,
      userBubbleStroke: Color.lerp(userBubbleStroke, other.userBubbleStroke, t)!,
      userBubbleHighlight: Color.lerp(userBubbleHighlight, other.userBubbleHighlight, t)!,
      topBarFill: Color.lerp(topBarFill, other.topBarFill, t)!,
      statusBarFill: Color.lerp(statusBarFill, other.statusBarFill, t)!,
      chatBoxRimGlow: Color.lerp(chatBoxRimGlow, other.chatBoxRimGlow, t)!,
      accentGlowBadge: Color.lerp(accentGlowBadge, other.accentGlowBadge, t)!,
      accentBorderTeal: Color.lerp(accentBorderTeal, other.accentBorderTeal, t)!,
      accentBorderAmber: Color.lerp(accentBorderAmber, other.accentBorderAmber, t)!,
      sendGlow: Color.lerp(sendGlow, other.sendGlow, t)!,
      inlineCodeFill: Color.lerp(inlineCodeFill, other.inlineCodeFill, t)!,
      inlineCodeStroke: Color.lerp(inlineCodeStroke, other.inlineCodeStroke, t)!,
      inlineCodeText: Color.lerp(inlineCodeText, other.inlineCodeText, t)!,
      dialogFill: Color.lerp(dialogFill, other.dialogFill, t)!,
      dialogBorder: Color.lerp(dialogBorder, other.dialogBorder, t)!,
      dialogHighlight: Color.lerp(dialogHighlight, other.dialogHighlight, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      fieldStroke: Color.lerp(fieldStroke, other.fieldStroke, t)!,
      fieldFocusGlow: Color.lerp(fieldFocusGlow, other.fieldFocusGlow, t)!,
      sendDisabledFill: Color.lerp(sendDisabledFill, other.sendDisabledFill, t)!,
      sendDisabledStroke: Color.lerp(sendDisabledStroke, other.sendDisabledStroke, t)!,
      sendDisabledIconColor: Color.lerp(sendDisabledIconColor, other.sendDisabledIconColor, t)!,
    );
  }
}
