import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/_core/preferences/general_preferences.dart';
import '../../data/_core/preferences/onboarding_preferences.dart';
import '../../data/_core/secure_storage.dart';

part 'settings_service.g.dart';

@Riverpod(keepAlive: true)
SettingsService settingsService(Ref ref) => SettingsService(ref);

/// Adapter that gives the notifier layer a single, stable seam over the three
/// settings data-sources: [SecureStorage] (API keys / GitHub token),
/// [GeneralPreferences] (SharedPreferences flags), and [OnboardingPreferences].
class SettingsService {
  SettingsService(this._ref);

  final Ref _ref;

  SecureStorage get _storage => _ref.read(secureStorageProvider);
  GeneralPreferences get _generalPrefs => _ref.read(generalPreferencesProvider);
  OnboardingPreferences get _onboardingPrefs => _ref.read(onboardingPreferencesProvider);

  // ── API keys ───────────────────────────────────────────────────────────────

  Future<String?> readApiKey(String provider) => _storage.readApiKey(provider);
  Future<void> writeApiKey(String provider, String key) => _storage.writeApiKey(provider, key);
  Future<void> deleteApiKey(String provider) => _storage.deleteApiKey(provider);

  Future<String?> readOllamaUrl() => _storage.readOllamaUrl();
  Future<void> writeOllamaUrl(String url) => _storage.writeOllamaUrl(url);

  Future<String?> readCustomEndpoint() => _storage.readCustomEndpoint();
  Future<void> writeCustomEndpoint(String url) => _storage.writeCustomEndpoint(url);

  Future<String?> readCustomApiKey() => _storage.readCustomApiKey();
  Future<void> writeCustomApiKey(String key) => _storage.writeCustomApiKey(key);

  Future<void> deleteAllSecureStorage() => _storage.deleteAll();

  // ── General preferences ────────────────────────────────────────────────────

  Future<bool> getAutoCommit() => _generalPrefs.getAutoCommit();
  Future<void> setAutoCommit(bool value) => _generalPrefs.setAutoCommit(value);

  Future<String> getTerminalApp() => _generalPrefs.getTerminalApp();
  Future<void> setTerminalApp(String value) => _generalPrefs.setTerminalApp(value);

  Future<bool> getDeleteConfirmation() => _generalPrefs.getDeleteConfirmation();
  Future<void> setDeleteConfirmation(bool value) => _generalPrefs.setDeleteConfirmation(value);

  // ── Onboarding ─────────────────────────────────────────────────────────────

  Future<void> markOnboardingCompleted() => _onboardingPrefs.markCompleted();
  Future<void> resetOnboarding() => _onboardingPrefs.reset();
}
