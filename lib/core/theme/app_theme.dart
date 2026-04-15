import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: ThemeConstants.background,
      colorScheme: const ColorScheme.dark(
        primary: ThemeConstants.accent,
        onPrimary: ThemeConstants.onAccent,
        secondary: ThemeConstants.accentLight,
        onSecondary: ThemeConstants.onAccent,
        surface: ThemeConstants.sidebarBackground,
        onSurface: ThemeConstants.textPrimary,
        error: ThemeConstants.error,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyMedium: GoogleFonts.inter(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize),
        bodySmall: GoogleFonts.inter(color: ThemeConstants.textSecondary, fontSize: 12),
        titleMedium: GoogleFonts.inter(color: ThemeConstants.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: GoogleFonts.inter(color: ThemeConstants.textSecondary, fontSize: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ThemeConstants.titleBar,
        foregroundColor: ThemeConstants.textPrimary,
        elevation: 0,
        toolbarHeight: 36,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: ThemeConstants.sidebarBackground),
      dividerTheme: const DividerThemeData(color: ThemeConstants.dividerColor, thickness: 1, space: 1),
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConstants.accent,
          foregroundColor: ThemeConstants.onAccent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ThemeConstants.accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ThemeConstants.textSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: ThemeConstants.textPrimary,
        iconColor: ThemeConstants.textSecondary,
        tileColor: Colors.transparent,
        selectedTileColor: ThemeConstants.editorLineHighlight,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(ThemeConstants.textMuted.withAlpha(100)),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ThemeConstants.titleBar,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ThemeConstants.borderColor),
        ),
        textStyle: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 12),
        waitDuration: const Duration(milliseconds: 500),
      ),
      cardTheme: CardThemeData(
        color: ThemeConstants.sidebarBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: ThemeConstants.borderColor),
        ),
      ),
    );
  }

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
        bodyMedium: GoogleFonts.inter(color: ThemeConstants.lightText, fontSize: ThemeConstants.uiFontSize),
        bodySmall: GoogleFonts.inter(color: ThemeConstants.lightTextSecondary, fontSize: 12),
        titleMedium: GoogleFonts.inter(color: ThemeConstants.lightText, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: GoogleFonts.inter(color: ThemeConstants.lightTextTertiary, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(color: ThemeConstants.lightDivider, thickness: 1, space: 1),
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
        thumbColor: WidgetStateProperty.all(ThemeConstants.lightTextMuted.withAlpha(100)),
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
}
