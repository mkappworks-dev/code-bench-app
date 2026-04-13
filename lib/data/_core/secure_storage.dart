import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/debug_logger.dart';

part 'secure_storage.g.dart';

@Riverpod(keepAlive: true)
SecureStorage secureStorage(Ref ref) {
  return SecureStorage();
}

class SecureStorage {
  static const _storage = FlutterSecureStorage(
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

  /// Deletes every entry this app has written to secure storage. Used by the
  /// debug "Wipe all data" action.
  ///
  /// We deliberately do NOT call `_storage.deleteAll()` — on macOS without
  /// App Sandbox (see macos/Runner/README.md), the plugin's batch sweep can
  /// abort if a single keychain item returns unexpected accessibility attrs,
  /// leaving the wipe partially done AND throwing. Instead, we enumerate
  /// every key the bundle owns via `readAll()` and call `delete(key:)`
  /// per-key, which is the same code path as our normal writeXxx/deleteXxx
  /// methods and is reliable on macOS.
  ///
  /// Per-key failures are logged but do not abort the loop — we want the
  /// wipe to make as much progress as possible even if one entry is stuck.
  /// If ANY deletes failed, the method throws at the end so the caller can
  /// surface a "partial wipe" message to the dev.
  Future<void> deleteAll() async {
    Map<String, String> all;
    try {
      all = await _storage.readAll();
    } catch (e) {
      throw StorageException('Failed to enumerate secure storage for wipe', originalError: e);
    }

    final failedKeys = <String>[];
    for (final key in all.keys) {
      try {
        await _storage.delete(key: key);
      } catch (e) {
        dLog('[SecureStorage] delete($key) failed: $e');
        failedKeys.add(key);
      }
    }

    if (failedKeys.isNotEmpty) {
      throw StorageException(
        'Failed to wipe ${failedKeys.length} secure storage entries',
        originalError: failedKeys.join(', '),
      );
    }
  }

  // Custom Endpoint
  static const String _customEndpointKey = 'custom_endpoint_url';
  static const String _customApiKeyKey = 'custom_endpoint_api_key';

  Future<void> writeCustomEndpoint(String url) async {
    try {
      await _storage.write(key: _customEndpointKey, value: url);
    } catch (e) {
      throw StorageException('Failed to store custom endpoint', originalError: e);
    }
  }

  Future<String?> readCustomEndpoint() async {
    try {
      return await _storage.read(key: _customEndpointKey);
    } catch (e) {
      throw StorageException('Failed to read custom endpoint', originalError: e);
    }
  }

  Future<void> writeCustomApiKey(String apiKey) async {
    try {
      await _storage.write(key: _customApiKeyKey, value: apiKey);
    } catch (e) {
      throw StorageException('Failed to store custom API key', originalError: e);
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
