import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/_core/secure_storage.dart';
import 'providers_repository.dart';

part 'providers_repository_impl.g.dart';

@Riverpod(keepAlive: true)
ProvidersRepository providersRepository(Ref ref) => ProvidersRepositoryImpl(ref);

class ProvidersRepositoryImpl implements ProvidersRepository {
  ProvidersRepositoryImpl(this._ref);

  final Ref _ref;

  SecureStorage get _storage => _ref.read(secureStorageProvider);

  @override
  Future<String?> readApiKey(String provider) => _storage.readApiKey(provider);

  @override
  Future<void> writeApiKey(String provider, String key) =>
      _storage.writeApiKey(provider, key);

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
}
