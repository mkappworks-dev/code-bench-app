import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/_core/preferences/general_preferences.dart';
import '../models/app_theme_preference.dart';
import '../../../data/_core/preferences/onboarding_preferences.dart';
import '../../../data/_core/secure_storage.dart';
import 'settings_repository.dart';

part 'settings_repository_impl.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => SettingsRepositoryImpl(ref);

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._ref);

  final Ref _ref;

  SecureStorage get _storage => _ref.read(secureStorageProvider);
  GeneralPreferences get _generalPrefs => _ref.read(generalPreferencesProvider);
  OnboardingPreferences get _onboardingPrefs => _ref.read(onboardingPreferencesProvider);

  // ── API keys ──────────────────────────────────────────────────────────────

  @override
  Future<String?> readApiKey(String provider) => _storage.readApiKey(provider);

  @override
  Future<void> writeApiKey(String provider, String key) => _storage.writeApiKey(provider, key);

  @override
  Future<void> deleteApiKey(String provider) => _storage.deleteApiKey(provider);

  @override
  Future<String?> readOllamaUrl() => _storage.readOllamaUrl();

  @override
  Future<void> writeOllamaUrl(String url) => _storage.writeOllamaUrl(url);

  @override
  Future<void> deleteOllamaUrl() => _storage.deleteOllamaUrl();

  @override
  Future<String?> readCustomEndpoint() => _storage.readCustomEndpoint();

  @override
  Future<void> writeCustomEndpoint(String url) => _storage.writeCustomEndpoint(url);

  @override
  Future<void> deleteCustomEndpoint() => _storage.deleteCustomEndpoint();

  @override
  Future<String?> readCustomApiKey() => _storage.readCustomApiKey();

  @override
  Future<void> writeCustomApiKey(String key) => _storage.writeCustomApiKey(key);

  @override
  Future<void> deleteCustomApiKey() => _storage.deleteCustomApiKey();

  @override
  Future<void> deleteAllSecureStorage() => _storage.deleteAll();

  // ── General preferences ───────────────────────────────────────────────────

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

  // ── Onboarding ────────────────────────────────────────────────────────────

  @override
  Future<void> markOnboardingCompleted() => _onboardingPrefs.markCompleted();

  @override
  Future<void> resetOnboarding() => _onboardingPrefs.reset();
}
