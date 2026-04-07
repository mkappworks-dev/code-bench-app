import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/app_exception.dart';

part 'secure_storage_source.g.dart';

@Riverpod(keepAlive: true)
SecureStorageSource secureStorageSource(Ref ref) {
  return SecureStorageSource();
}

class SecureStorageSource {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Keys
  static String _apiKeyKey(String provider) => 'api_key_$provider';
  static const String _githubTokenKey = 'github_token';
  static const String _ollamaUrlKey = 'ollama_base_url';

  // API Keys
  Future<void> writeApiKey(String provider, String apiKey) async {
    try {
      await _storage.write(key: _apiKeyKey(provider), value: apiKey);
    } catch (e) {
      throw StorageException('Failed to store API key', originalError: e);
    }
  }

  Future<String?> readApiKey(String provider) async {
    try {
      return await _storage.read(key: _apiKeyKey(provider));
    } catch (e) {
      throw StorageException('Failed to read API key', originalError: e);
    }
  }

  Future<void> deleteApiKey(String provider) async {
    try {
      await _storage.delete(key: _apiKeyKey(provider));
    } catch (e) {
      throw StorageException('Failed to delete API key', originalError: e);
    }
  }

  // GitHub Token
  Future<void> writeGitHubToken(String token) async {
    try {
      await _storage.write(key: _githubTokenKey, value: token);
    } catch (e) {
      throw StorageException('Failed to store GitHub token', originalError: e);
    }
  }

  Future<String?> readGitHubToken() async {
    try {
      return await _storage.read(key: _githubTokenKey);
    } catch (e) {
      throw StorageException('Failed to read GitHub token', originalError: e);
    }
  }

  Future<void> deleteGitHubToken() async {
    try {
      await _storage.delete(key: _githubTokenKey);
    } catch (e) {
      throw StorageException('Failed to delete GitHub token', originalError: e);
    }
  }

  // Ollama URL
  Future<void> writeOllamaUrl(String url) async {
    try {
      await _storage.write(key: _ollamaUrlKey, value: url);
    } catch (e) {
      throw StorageException('Failed to store Ollama URL', originalError: e);
    }
  }

  Future<String?> readOllamaUrl() async {
    try {
      return await _storage.read(key: _ollamaUrlKey);
    } catch (e) {
      throw StorageException('Failed to read Ollama URL', originalError: e);
    }
  }

  Future<bool> hasAnyApiKey() async {
    try {
      final all = await _storage.readAll();
      return all.keys.any((k) => k.startsWith('api_key_'));
    } catch (e) {
      return false;
    }
  }

  // Custom Endpoint
  static const String _customEndpointKey = 'custom_endpoint_url';
  static const String _customApiKeyKey = 'custom_endpoint_api_key';

  Future<void> writeCustomEndpoint(String url) async {
    try {
      await _storage.write(key: _customEndpointKey, value: url);
    } catch (e) {
      throw StorageException(
        'Failed to store custom endpoint',
        originalError: e,
      );
    }
  }

  Future<String?> readCustomEndpoint() async {
    try {
      return await _storage.read(key: _customEndpointKey);
    } catch (e) {
      throw StorageException(
        'Failed to read custom endpoint',
        originalError: e,
      );
    }
  }

  Future<void> writeCustomApiKey(String apiKey) async {
    try {
      await _storage.write(key: _customApiKeyKey, value: apiKey);
    } catch (e) {
      throw StorageException(
        'Failed to store custom API key',
        originalError: e,
      );
    }
  }

  Future<String?> readCustomApiKey() async {
    try {
      return await _storage.read(key: _customApiKeyKey);
    } catch (e) {
      throw StorageException('Failed to read custom API key', originalError: e);
    }
  }
}
