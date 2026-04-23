/// Secrets: per-provider API keys and the custom-endpoint API key.
///
/// Split from the earlier unified `ProvidersRepository` so sensitive
/// credentials live behind a different interface than provider-level
/// preference flags (see [ProviderPrefsRepository]).
abstract interface class CredentialsRepository {
  Future<String?> readApiKey(String provider);
  Future<void> writeApiKey(String provider, String key);
  Future<void> deleteApiKey(String provider);

  Future<String?> readCustomApiKey();
  Future<void> writeCustomApiKey(String key);
  Future<void> deleteCustomApiKey();
}
