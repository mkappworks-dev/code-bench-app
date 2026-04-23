import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../_core/secure_storage.dart';
import 'credentials_repository.dart';

part 'credentials_repository_impl.g.dart';

@Riverpod(keepAlive: true)
CredentialsRepository credentialsRepository(Ref ref) => CredentialsRepositoryImpl(ref);

class CredentialsRepositoryImpl implements CredentialsRepository {
  CredentialsRepositoryImpl(this._ref);

  final Ref _ref;

  SecureStorage get _storage => _ref.read(secureStorageProvider);

  @override
  Future<String?> readApiKey(String provider) => _storage.readApiKey(provider);

  @override
  Future<void> writeApiKey(String provider, String key) => _storage.writeApiKey(provider, key);

  @override
  Future<void> deleteApiKey(String provider) => _storage.deleteApiKey(provider);

  @override
  Future<String?> readCustomApiKey() => _storage.readCustomApiKey();

  @override
  Future<void> writeCustomApiKey(String key) => _storage.writeCustomApiKey(key);

  @override
  Future<void> deleteCustomApiKey() => _storage.deleteCustomApiKey();
}
