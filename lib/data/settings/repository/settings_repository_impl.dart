import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/_core/preferences/general_preferences.dart';
import '../../../data/_core/preferences/onboarding_preferences.dart';
import '../models/app_theme_preference.dart';
import 'settings_repository.dart';

part 'settings_repository_impl.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => SettingsRepositoryImpl(ref);

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._ref);

  final Ref _ref;

  GeneralPreferences get _generalPrefs => _ref.read(generalPreferencesProvider);
  OnboardingPreferences get _onboardingPrefs => _ref.read(onboardingPreferencesProvider);

  @override
  Future<bool> getAutoCommit() => _generalPrefs.getAutoCommit();

  @override
  Future<void> setAutoCommit(bool value) => _generalPrefs.setAutoCommit(value);

  @override
  Future<String> getTerminalApp() => _generalPrefs.getTerminalApp();

  @override
  Future<void> setTerminalApp(String value) => _generalPrefs.setTerminalApp(value);

  @override
  Future<bool> getDeleteConfirmation() => _generalPrefs.getDeleteConfirmation();

  @override
  Future<void> setDeleteConfirmation(bool value) => _generalPrefs.setDeleteConfirmation(value);

  @override
  Future<AppThemePreference> getThemeMode() => _generalPrefs.getThemeMode();

  @override
  Future<void> setThemeMode(AppThemePreference mode) => _generalPrefs.setThemeMode(mode);

  @override
  Future<void> markOnboardingCompleted() => _onboardingPrefs.markCompleted();

  @override
  Future<void> resetOnboarding() => _onboardingPrefs.reset();
}
