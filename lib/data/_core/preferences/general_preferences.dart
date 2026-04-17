import '../../settings/models/app_theme_preference.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'general_preferences.g.dart';

@Riverpod(keepAlive: true)
GeneralPreferences generalPreferences(Ref ref) => GeneralPreferences();

class GeneralPreferences {
  static const _autoCommit = 'auto_commit_enabled';
  static const _terminalApp = 'terminal_app';
  static const _deleteConfirm = 'delete_confirmation_enabled';

  Future<bool> getAutoCommit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoCommit) ?? false;
  }

  Future<void> setAutoCommit(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCommit, value);
  }

  Future<String> getTerminalApp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_terminalApp) ?? 'Terminal';
  }

  Future<void> setTerminalApp(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_terminalApp, value);
  }

  Future<bool> getDeleteConfirmation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_deleteConfirm) ?? true;
  }

  Future<void> setDeleteConfirmation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deleteConfirm, value);
  }

  static const _themeMode = 'theme_mode'; // values: 'system', 'dark', 'light'

  Future<AppThemePreference> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeMode) ?? 'system';
    return switch (raw) {
      'dark' => AppThemePreference.dark,
      'light' => AppThemePreference.light,
      _ => AppThemePreference.system,
    };
  }

  Future<void> setThemeMode(AppThemePreference mode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = switch (mode) {
      AppThemePreference.dark => 'dark',
      AppThemePreference.light => 'light',
      AppThemePreference.system => 'system',
    };
    await prefs.setString(_themeMode, raw);
  }
}
