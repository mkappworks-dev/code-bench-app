import 'package:flutter/material.dart';

class ThemeConstants {
  ThemeConstants._();

  // Surface hierarchy: deepest → darkest chrome → content → floating panels
  static const Color background = Color(0xFF141414);
  static const Color sidebarBackground = Color(0xFF111111);
  static const Color activityBar = Color(0xFF0A0A0A);
  static const Color deepBackground = Color(0xFF050505);
  static const Color titleBar = Color(0xFF111111);
  static const Color editorBackground = Color(0xFF141414);
  static const Color editorLineHighlight = Color(0xFF1E1E1E);
  static const Color editorGutter = Color(0xFF141414);
  static const Color editorGutterForeground = Color(0xFF858585);
  static const Color panelBackground = Color(0xFF1E1E1E);
  static const Color inputBackground = Color(0xFF111111);
  static const Color borderColor = Color(0xFF2A2A2A);
  static const Color dividerColor = Color(0xFF2A2A2A);

  // Text colors
  static const Color textPrimary = Color(0xFFD4D4D4);
  static const Color textSecondary = Color(0xFF9D9D9D);
  static const Color textMuted = Color(0xFF666666);

  // Accent colors
  static const Color accent = Color(0xFF4EC9B0);
  static const Color accentLight = Color(0xFF6DD4BE);
  static const Color accentHover = Color(0xFF3AB49A);
  static const Color accentDark = Color(0xFF267A68);

  // Semantic colors
  static const Color success = Color(0xFF4EC9B0);
  static const Color warning = Color(0xFFCCA700);
  static const Color error = Color(0xFFF44747);
  static const Color info = Color(0xFF4FC1FF);

  // Chat colors
  static const Color userMessageBg = Color(0xFF1E1E1E);
  static const Color assistantMessageBg = Color(0xFF141414);
  static const Color codeBlockBg = Color(0xFF0D1117);

  // Syntax highlight colors
  static const Color syntaxKeyword = Color(0xFF569CD6);
  static const Color syntaxString = Color(0xFFCE9178);
  static const Color syntaxComment = Color(0xFF6A9955);
  static const Color syntaxFunction = Color(0xFFDCDCAA);
  static const Color syntaxType = Color(0xFF4EC9B0);
  static const Color syntaxNumber = Color(0xFFB5CEA8);
  static const Color syntaxVariable = Color(0xFF9CDCFE);

  // Tab colors
  static const Color tabActive = Color(0xFF141414);
  static const Color tabInactive = Color(0xFF111111);
  static const Color tabBorder = Color(0xFF4EC9B0);

  // Frosted glass (for cards on dark backgrounds)
  static const Color frostedBg = Color(0x0AFFFFFF);
  static const Color frostedBorder = Color(0x12FFFFFF);

  // VCS status badge
  static const Color gitBadgeText = Color(0xFF4CAF50);
  static const Color gitBadgeBg = Color(0xFF0F3D1F);
  static const Color gitBadgeBorder = Color(0xFF1A6B35);

  // Input / surface tokens (for input boxes, card surfaces, button backgrounds)
  static const Color inputSurface = Color(0xFF1A1A1A);
  static const Color deepBorder = Color(0xFF222222);
  static const Color mutedFg = Color(0xFF555555);
  static const Color faintFg = Color(0xFF333333);

  // Interactive teal (step dots, spinners, links — alias of accent; to be renamed in follow-up)
  static const Color blueAccent = Color(0xFF4EC9B0);

  // Dim foreground (between textSecondary and textMuted — dim icons, labels)
  static const Color dimFg = Color(0xFF888888);

  // Heading text (brighter than textPrimary, used in onboarding titles)
  static const Color headingText = Color(0xFFE0E0E0);

  // Worktree badge
  static const Color worktreeBadgeBg = Color(0xFF2A1F0A);
  static const Color worktreeBadgeFg = Color(0xFFE8A228);

  // Selection / active-state surfaces
  static const Color selectionBg = Color(0xFF0D2B27);
  static const Color selectionBorder = Color(0xFF1A4840);
  static const Color questionCardBg = Color(0xFF0D2B27);

  // PR status
  static const Color prMergedColor = Color(0xFF6E40C9);
  static const Color pendingAmber = Color(0xFFFFAA00);

  // "Edited" badge (pending local edits on a file)
  static const Color editedBadgeBg = Color(0xFF3D2900);
  static const Color editedBadgeBorder = Color(0xFFAA7700);

  // GitHub brand
  static const Color githubBrandColor = Color(0xFF24292E);

  // Diff highlights (20% opacity overlays)
  static const Color diffAdditionBg = Color(0x3300CC66);
  static const Color diffDeletionBg = Color(0x33FF4444);

  // Foreground on accent-coloured surfaces (near-black for contrast on teal)
  static const Color onAccent = Color(0xFF0A0A0A);

  // Frosted surface (dialogs, snackbars — near-black with high opacity)
  static const Color frostedSurface = Color(0xF7161616);

  // Destructive action border (dark red outline for destructive buttons)
  static const Color destructiveBorder = Color(0xFF3D1515);

  // Panel/footer separator (divider between content area and footer)
  static const Color panelSeparator = Color(0xFF242424);

  // Icon in empty / inactive state (between mutedFg and faintFg)
  static const Color iconInactive = Color(0xFF444444);

  // Box shadow colours
  static const Color shadowDark = Color(0x99000000);
  static const Color shadowMedium = Color(0x66000000);

  // Icon sizes
  static const double iconSizeSmall = 14;
  static const double iconSizeMedium = 18;
  static const double iconSizeLarge = 24;

  // Top action bar: exact height of the small action buttons in the right-hand
  // cluster. Applied via BoxConstraints.tightFor(height: ...) to the _ActionButton
  // helper and both halves of the Commit/Push split button, so every button in
  // that row lines up exactly (minHeight alone leaves a 1px gap when one half's
  // content renders naturally taller than the other).
  static const double actionButtonHeight = 22;

  // Font
  static const String editorFontFamily = 'JetBrains Mono';
  static const double editorFontSize = 13;
  static const double uiFontSize = 12; // body: messages, sidebar titles
  static const double uiFontSizeSmall = 11; // secondary: chips, button labels
  static const double uiFontSizeLabel = 10; // labels: section headers, timestamps
  static const double uiFontSizeBadge = 9; // badges: git tag, provider badge
  static const double uiFontSizeLarge = 15;
}
