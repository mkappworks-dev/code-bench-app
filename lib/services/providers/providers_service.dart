// lib/services/providers/providers_service.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/_core/secure_storage.dart';
import '../../data/providers/repository/credentials_repository.dart';
import '../../data/providers/repository/credentials_repository_impl.dart';
import '../../data/providers/repository/provider_prefs_repository.dart';
import '../../data/providers/repository/provider_prefs_repository_impl.dart';

part 'providers_service.g.dart';

@Riverpod(keepAlive: true)
ProvidersService providersService(Ref ref) => ProvidersService(
  credentials: ref.watch(credentialsRepositoryProvider),
  prefs: ref.watch(providerPrefsRepositoryProvider),
  storage: ref.watch(secureStorageProvider),
);

/// Facade over the split provider-config repositories.
///
/// Two stores back this service: [CredentialsRepository] for secrets
/// (API keys) and [ProviderPrefsRepository] for non-secret flags
/// (Ollama URL, custom endpoint, Anthropic transport). The facade
/// preserves a single call surface for notifiers so the split is
/// invisible above the service layer.
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

  // ── Credentials ──────────────────────────────────────────────────────

  Future<String?> readApiKey(String provider) => _credentials.readApiKey(provider);
  Future<void> writeApiKey(String provider, String key) => _credentials.writeApiKey(provider, key);
  Future<void> deleteApiKey(String provider) => _credentials.deleteApiKey(provider);

  Future<String?> readCustomApiKey() => _credentials.readCustomApiKey();
  Future<void> writeCustomApiKey(String key) => _credentials.writeCustomApiKey(key);
  Future<void> deleteCustomApiKey() => _credentials.deleteCustomApiKey();

  // ── Preferences ──────────────────────────────────────────────────────

  Future<String?> readOllamaUrl() => _prefs.readOllamaUrl();
  Future<void> writeOllamaUrl(String url) => _prefs.writeOllamaUrl(url);
  Future<void> deleteOllamaUrl() => _prefs.deleteOllamaUrl();

  Future<String?> readCustomEndpoint() => _prefs.readCustomEndpoint();
  Future<void> writeCustomEndpoint(String url) => _prefs.writeCustomEndpoint(url);
  Future<void> deleteCustomEndpoint() => _prefs.deleteCustomEndpoint();

  Future<String?> readAnthropicTransport() => _prefs.readAnthropicTransport();
  Future<void> writeAnthropicTransport(String value) => _prefs.writeAnthropicTransport(value);
  Future<void> deleteAnthropicTransport() => _prefs.deleteAnthropicTransport();

  // ── Cross-cutting wipe ───────────────────────────────────────────────

  /// Wipes every provider-owned secure storage entry. Called by
  /// SettingsService.wipeAllData() — not directly from widgets or notifiers.
  /// Bypasses the per-domain repos because the wipe is inherently
  /// cross-cutting (and matches the existing bundle-wide keychain sweep
  /// behaviour in [SecureStorage.deleteAll]).
  Future<void> deleteAll() => _storage.deleteAll();
}
