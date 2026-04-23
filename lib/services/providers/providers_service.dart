// lib/services/providers/providers_service.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers/repository/providers_repository.dart';
import '../../data/providers/repository/providers_repository_impl.dart';

part 'providers_service.g.dart';

@Riverpod(keepAlive: true)
ProvidersService providersService(Ref ref) => ProvidersService(providers: ref.watch(providersRepositoryProvider));

class ProvidersService {
  ProvidersService({required ProvidersRepository providers}) : _providers = providers;

  final ProvidersRepository _providers;

  Future<String?> readApiKey(String provider) => _providers.readApiKey(provider);
  Future<void> writeApiKey(String provider, String key) => _providers.writeApiKey(provider, key);
  Future<void> deleteApiKey(String provider) => _providers.deleteApiKey(provider);
  Future<String?> readOllamaUrl() => _providers.readOllamaUrl();
  Future<void> writeOllamaUrl(String url) => _providers.writeOllamaUrl(url);
  Future<void> deleteOllamaUrl() => _providers.deleteOllamaUrl();
  Future<String?> readAnthropicTransport() => _providers.readAnthropicTransport();
  Future<void> writeAnthropicTransport(String value) => _providers.writeAnthropicTransport(value);
  Future<void> deleteAnthropicTransport() => _providers.deleteAnthropicTransport();
  Future<String?> readCustomEndpoint() => _providers.readCustomEndpoint();
  Future<void> writeCustomEndpoint(String url) => _providers.writeCustomEndpoint(url);
  Future<void> deleteCustomEndpoint() => _providers.deleteCustomEndpoint();
  Future<String?> readCustomApiKey() => _providers.readCustomApiKey();
  Future<void> writeCustomApiKey(String key) => _providers.writeCustomApiKey(key);
  Future<void> deleteCustomApiKey() => _providers.deleteCustomApiKey();

  /// Wipes all provider-owned secure storage entries. Called by
  /// SettingsService.wipeAllData() — not directly from widgets or notifiers.
  Future<void> deleteAll() => _providers.deleteAllSecureStorage();
}
