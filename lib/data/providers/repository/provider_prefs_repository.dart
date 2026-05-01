/// Non-secret provider preferences: Ollama base URL, custom-endpoint URL,
/// Anthropic transport choice (`'api-key'` vs `'sdk'`).
///
/// Split from the earlier unified `ProvidersRepository` so preference flags
/// have a distinct evolution path from secrets (see [CredentialsRepository]).
/// Flags here are safe to surface in logs or UI summaries; credentials
/// aren't.
abstract interface class ProviderPrefsRepository {
  Future<String?> readOllamaUrl();
  Future<void> writeOllamaUrl(String url);
  Future<void> deleteOllamaUrl();

  Future<String?> readCustomEndpoint();
  Future<void> writeCustomEndpoint(String url);
  Future<void> deleteCustomEndpoint();

  Future<String?> readAnthropicTransport();
  Future<void> writeAnthropicTransport(String value);
  Future<void> deleteAnthropicTransport();

  Future<String?> readOpenaiTransport();
  Future<void> writeOpenaiTransport(String value);
  Future<void> deleteOpenaiTransport();
}
