import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../_core/secure_storage.dart';
import 'provider_prefs_repository.dart';

part 'provider_prefs_repository_impl.g.dart';

@Riverpod(keepAlive: true)
ProviderPrefsRepository providerPrefsRepository(Ref ref) => ProviderPrefsRepositoryImpl(ref);

class ProviderPrefsRepositoryImpl implements ProviderPrefsRepository {
  ProviderPrefsRepositoryImpl(this._ref);

  final Ref _ref;

  SecureStorage get _storage => _ref.read(secureStorageProvider);

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
  Future<String?> readAnthropicTransport() => _storage.readAnthropicTransport();

  @override
  Future<void> writeAnthropicTransport(String value) => _storage.writeAnthropicTransport(value);

  @override
  Future<void> deleteAnthropicTransport() => _storage.deleteAnthropicTransport();
}
