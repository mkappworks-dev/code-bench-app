import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/_core/secure_storage.dart';
import '../../data/providers/repository/credentials_repository.dart';
import '../../data/providers/repository/credentials_repository_impl.dart';
import '../../data/providers/repository/provider_prefs_repository.dart';
import '../../data/providers/repository/provider_prefs_repository_impl.dart';
import '../../data/shared/ai_model.dart';

part 'providers_service.g.dart';

@Riverpod(keepAlive: true)
ProvidersService providersService(Ref ref) => ProvidersService(
  credentials: ref.watch(credentialsRepositoryProvider),
  prefs: ref.watch(providerPrefsRepositoryProvider),
  storage: ref.watch(secureStorageProvider),
);

// Facade: [CredentialsRepository] for secrets, [ProviderPrefsRepository] for non-secret flags — split invisible above service layer.
class ProvidersService {
  ProvidersService({
    required CredentialsRepository credentials,
    required ProviderPrefsRepository prefs,
    required SecureStorage storage,
  }) : _credentials = credentials,
       _prefs = prefs,
       _storage = storage;

  final CredentialsRepository _credentials;
  final ProviderPrefsRepository _prefs;
  final SecureStorage _storage;

  Future<String?> readApiKey(String provider) => _credentials.readApiKey(provider);
  Future<void> writeApiKey(String provider, String key) => _credentials.writeApiKey(provider, key);
  Future<void> deleteApiKey(String provider) => _credentials.deleteApiKey(provider);

  Future<String?> readCustomApiKey() => _credentials.readCustomApiKey();
  Future<void> writeCustomApiKey(String key) => _credentials.writeCustomApiKey(key);
  Future<void> deleteCustomApiKey() => _credentials.deleteCustomApiKey();

  Future<String?> readOllamaUrl() => _prefs.readOllamaUrl();
  Future<void> writeOllamaUrl(String url) => _prefs.writeOllamaUrl(url);
  Future<void> deleteOllamaUrl() => _prefs.deleteOllamaUrl();

  Future<String?> readCustomEndpoint() => _prefs.readCustomEndpoint();
  Future<void> writeCustomEndpoint(String url) => _prefs.writeCustomEndpoint(url);
  Future<void> deleteCustomEndpoint() => _prefs.deleteCustomEndpoint();

  Future<String?> readAnthropicTransport() => _prefs.readAnthropicTransport();
  Future<void> writeAnthropicTransport(String value) => _prefs.writeAnthropicTransport(value);
  Future<void> deleteAnthropicTransport() => _prefs.deleteAnthropicTransport();

  Future<String?> readOpenaiTransport() => _prefs.readOpenaiTransport();
  Future<void> writeOpenaiTransport(String value) => _prefs.writeOpenaiTransport(value);
  Future<void> deleteOpenaiTransport() => _prefs.deleteOpenaiTransport();

  Future<bool> hasCredentialsFor(AIProvider provider) async {
    return switch (provider) {
      AIProvider.anthropic ||
      AIProvider.openai ||
      AIProvider.gemini => (await readApiKey(provider.name) ?? '').isNotEmpty,
      AIProvider.ollama => (await readOllamaUrl() ?? 'http://localhost:11434').isNotEmpty,
      AIProvider.custom => (await readCustomEndpoint() ?? '').isNotEmpty,
    };
  }

  Future<void> deleteAll() => _storage.deleteAll();
}
