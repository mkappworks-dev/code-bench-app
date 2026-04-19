// lib/data/settings/repository/settings_repository.dart
import '../models/app_theme_preference.dart';

abstract interface class SettingsRepository {
  // ── General preferences ───────────────────────────────────────────────────
  Future<bool> getAutoCommit();
  Future<void> setAutoCommit(bool value);
  Future<String> getTerminalApp();
  Future<void> setTerminalApp(String value);
  Future<bool> getDeleteConfirmation();
  Future<void> setDeleteConfirmation(bool value);
  Future<AppThemePreference> getThemeMode();
  Future<void> setThemeMode(AppThemePreference mode);

  // ── Onboarding ────────────────────────────────────────────────────────────
  Future<void> markOnboardingCompleted();
  Future<void> resetOnboarding();
}
