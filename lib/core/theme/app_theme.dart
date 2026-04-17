import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      extensions: const [AppColors.dark],
      scaffoldBackgroundColor: AppColors.dark.background,
      colorScheme: ColorScheme.dark(
        primary: AppColors.dark.accent,
        onPrimary: AppColors.dark.onAccent,
        secondary: AppColors.dark.accentLight,
        onSecondary: AppColors.dark.onAccent,
        surface: AppColors.dark.sidebarBackground,
        onSurface: AppColors.dark.textPrimary,
        error: AppColors.dark.error,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyMedium: GoogleFonts.inter(color: AppColors.dark.textPrimary, fontSize: ThemeConstants.uiFontSize),
        bodySmall: GoogleFonts.inter(color: AppColors.dark.textSecondary, fontSize: 12),
        titleMedium: GoogleFonts.inter(color: AppColors.dark.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: GoogleFonts.inter(color: AppColors.dark.textSecondary, fontSize: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.dark.titleBar,
        foregroundColor: AppColors.dark.textPrimary,
        elevation: 0,
        toolbarHeight: 36,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: AppColors.dark.sidebarBackground),
      dividerTheme: DividerThemeData(color: AppColors.dark.dividerColor, thickness: 1, space: 1),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        hintStyle: TextStyle(color: AppColors.dark.textMuted),
        labelStyle: TextStyle(color: AppColors.dark.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark.accent,
          foregroundColor: AppColors.dark.onAccent,
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
          foregroundColor: AppColors.dark.accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.dark.textSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: AppColors.dark.textPrimary,
        iconColor: AppColors.dark.textSecondary,
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.dark.editorLineHighlight,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.dark.textMuted.withAlpha(100)),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.dark.titleBar,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.dark.borderColor),
        ),
        textStyle: TextStyle(color: AppColors.dark.textPrimary, fontSize: 12),
        waitDuration: const Duration(milliseconds: 500),
      ),
      cardTheme: CardThemeData(
        color: AppColors.dark.sidebarBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.dark.borderColor),
        ),
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      extensions: const [AppColors.light],
      scaffoldBackgroundColor: AppColors.light.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.light.accent,
        onPrimary: AppColors.light.onAccent,
        secondary: AppColors.light.accent,
        onSecondary: AppColors.light.onAccent,
        surface: AppColors.light.glassFill,
        onSurface: AppColors.light.textPrimary,
        error: AppColors.light.error,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyMedium: GoogleFonts.inter(color: AppColors.light.textPrimary, fontSize: ThemeConstants.uiFontSize),
        bodySmall: GoogleFonts.inter(color: AppColors.light.textSecondary, fontSize: 12),
        titleMedium: GoogleFonts.inter(color: AppColors.light.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: GoogleFonts.inter(color: AppColors.light.textSecondary, fontSize: 12),
      ),
      dividerTheme: DividerThemeData(color: AppColors.light.faintBorder, thickness: 1, space: 1),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        hintStyle: TextStyle(color: AppColors.light.textMuted),
        labelStyle: TextStyle(color: AppColors.light.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.light.accent,
          foregroundColor: AppColors.light.onAccent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.light.accent;
          return AppColors.light.switchTrackUnselected;
        }),
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return AppColors.light.switchTrackOutline;
        }),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.light.textMuted.withAlpha(100)),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.light.glassFill,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.light.fieldStroke),
        ),
        textStyle: TextStyle(color: AppColors.light.textPrimary, fontSize: 12),
        waitDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}
