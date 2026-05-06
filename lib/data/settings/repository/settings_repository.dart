import '../models/app_theme_preference.dart';

abstract interface class SettingsRepository {
  Future<bool> getAutoCommit();
  Future<void> setAutoCommit(bool value);
  Future<String> getTerminalApp();
  Future<void> setTerminalApp(String value);
  Future<bool> getDeleteConfirmation();
  Future<void> setDeleteConfirmation(bool value);
  Future<AppThemePreference> getThemeMode();
  Future<void> setThemeMode(AppThemePreference mode);

  Future<void> markOnboardingCompleted();
  Future<void> resetOnboarding();
}
