import 'package:flutter/material.dart';

class ThemeConstants {
  ThemeConstants._();

  // VS Code Dark+ palette
  static const Color background = Color(0xFF1E1E1E);
  static const Color sidebarBackground = Color(0xFF252526);
  static const Color activityBar = Color(0xFF333333);
  static const Color titleBar = Color(0xFF3C3C3C);
  static const Color editorBackground = Color(0xFF1E1E1E);
  static const Color editorLineHighlight = Color(0xFF2A2D2E);
  static const Color editorGutter = Color(0xFF1E1E1E);
  static const Color editorGutterForeground = Color(0xFF858585);
  static const Color panelBackground = Color(0xFF252526);
  static const Color inputBackground = Color(0xFF3C3C3C);
  static const Color borderColor = Color(0xFF3E3E3E);
  static const Color dividerColor = Color(0xFF454545);

  // Text colors
  static const Color textPrimary = Color(0xFFD4D4D4);
  static const Color textSecondary = Color(0xFF9D9D9D);
  static const Color textMuted = Color(0xFF6A6A6A);

  // Accent colors
  static const Color accent = Color(0xFF007ACC);
  static const Color accentLight = Color(0xFF1F8AD2);
  static const Color accentHover = Color(0xFF0066B8);

  // Semantic colors
  static const Color success = Color(0xFF4EC9B0);
  static const Color warning = Color(0xFFCCA700);
  static const Color error = Color(0xFFF44747);
  static const Color info = Color(0xFF4FC1FF);

  // Chat colors
  static const Color userMessageBg = Color(0xFF2D2D2D);
  static const Color assistantMessageBg = Color(0xFF1E1E1E);
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
  static const Color tabActive = Color(0xFF1E1E1E);
  static const Color tabInactive = Color(0xFF2D2D2D);
  static const Color tabBorder = Color(0xFF007ACC);

  // Icon sizes
  static const double iconSizeSmall = 14;
  static const double iconSizeMedium = 18;
  static const double iconSizeLarge = 24;

  // Font
  static const String editorFontFamily = 'JetBrains Mono';
  static const double editorFontSize = 13;
  static const double uiFontSize = 13;
}
