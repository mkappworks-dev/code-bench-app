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
  static const Color accent = Color(0xFF007ACC);
  static const Color accentLight = Color(0xFF1F8AD2);
  static const Color accentHover = Color(0xFF0066B8);
  static const Color accentDark = Color(0xFF004F85);

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
  static const Color tabBorder = Color(0xFF007ACC);

  // Frosted glass (for cards on dark backgrounds)
  static const Color frostedBg = Color(0x0AFFFFFF);
  static const Color frostedBorder = Color(0x12FFFFFF);

  // Input / surface tokens (for input boxes, card surfaces, button backgrounds)
  static const Color inputSurface = Color(0xFF1A1A1A);
  static const Color deepBorder = Color(0xFF222222);
  static const Color mutedFg = Color(0xFF555555);
  static const Color faintFg = Color(0xFF333333);

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
