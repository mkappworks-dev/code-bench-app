import '../../shared/ai_model.dart';

/// Domain interface for validating AI provider credentials and Ollama
/// connectivity via live HTTP probes.
///
/// Decouples [SettingsActions] from the concrete HTTP implementation so that
/// tests can inject a fake without making real network calls.
abstract interface class ApiKeyTestRepository {
  /// Returns `true` when [key] is accepted by [provider]'s API.
  Future<bool> testApiKey(AIProvider provider, String key);

  /// Returns `true` when an Ollama instance is reachable at [url].
  Future<bool> testOllamaUrl(String url);
}
