abstract interface class SettingsRepository {
  // ── API keys ──────────────────────────────────────────────────────────────

  Future<String?> readApiKey(String provider);
  Future<void> writeApiKey(String provider, String key);
  Future<void> deleteApiKey(String provider);

  Future<String?> readOllamaUrl();
  Future<void> writeOllamaUrl(String url);

  Future<String?> readCustomEndpoint();
  Future<void> writeCustomEndpoint(String url);

  Future<String?> readCustomApiKey();
  Future<void> writeCustomApiKey(String key);

  Future<void> deleteAllSecureStorage();

  // ── General preferences ───────────────────────────────────────────────────

  Future<bool> getAutoCommit();
  Future<void> setAutoCommit(bool value);

  Future<String> getTerminalApp();
  Future<void> setTerminalApp(String value);

  Future<bool> getDeleteConfirmation();
  Future<void> setDeleteConfirmation(bool value);

  // ── Onboarding ────────────────────────────────────────────────────────────

  Future<void> markOnboardingCompleted();
  Future<void> resetOnboarding();
}
