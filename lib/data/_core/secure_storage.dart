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
  // kSecUseDataProtectionKeychain = true (the flutter_secure_storage v10 default)
  // requires the keychain-access-groups entitlement on macOS 15+ (Sequoia removed
  // the legacy file-based keychain, making the false path fail with -34018).
  // The entitlement is declared in macos/Runner/DebugProfile.entitlements and
  // Release.entitlements. App Sandbox remains intentionally disabled — see
  // macos/Runner/README.md.
  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Keys
  static String _apiKeyKey(String provider) => 'api_key_$provider';
  static const String _githubTokenKey = 'github_token';
  static const String _githubAccountKey = 'github_account';
  static const String _ollamaUrlKey = 'ollama_base_url';
  static const String _anthropicTransportKey = 'anthropic_transport';
  static const String _openaiTransportKey = 'openai_transport';

  // API Keys
  Future<void> writeApiKey(String provider, String apiKey) async {
    try {
      await _storage.write(key: _apiKeyKey(provider), value: apiKey);
    } catch (e) {
      dLog('[SecureStorage] writeApiKey($provider) failed: $e');
      throw StorageException('Failed to store API key', originalError: e);
    }
  }

  Future<String?> readApiKey(String provider) async {
    try {
      return await _storage.read(key: _apiKeyKey(provider));
    } catch (e) {
      dLog('[SecureStorage] readApiKey($provider) failed: $e');
      throw StorageException('Failed to read API key', originalError: e);
    }
  }

  Future<void> deleteApiKey(String provider) async {
    try {
      final key = _apiKeyKey(provider);
      if (await _storage.containsKey(key: key)) {
        await _storage.delete(key: key);
      }
    } catch (e) {
      dLog('[SecureStorage] deleteApiKey($provider) failed: $e');
      throw StorageException('Failed to delete API key', originalError: e);
    }
  }

  // GitHub Token
  Future<void> writeGitHubToken(String token) async {
    try {
      await _storage.write(key: _githubTokenKey, value: token);
    } catch (e) {
      dLog('[SecureStorage] writeGitHubToken failed: $e');
      throw StorageException('Failed to store GitHub token', originalError: e);
    }
  }

  Future<String?> readGitHubToken() async {
    try {
      return await _storage.read(key: _githubTokenKey);
    } catch (e) {
      dLog('[SecureStorage] readGitHubToken failed: $e');
      throw StorageException('Failed to read GitHub token', originalError: e);
    }
  }

  Future<void> deleteGitHubToken() async {
    try {
      await _storage.delete(key: _githubTokenKey);
    } catch (e) {
      dLog('[SecureStorage] deleteGitHubToken failed: $e');
      throw StorageException('Failed to delete GitHub token', originalError: e);
    }
  }

  // GitHub Account cache (username, avatarUrl — avoids network call on startup)
  Future<void> writeGitHubAccount(String json) async {
    try {
      await _storage.write(key: _githubAccountKey, value: json);
    } catch (e) {
      dLog('[SecureStorage] writeGitHubAccount failed: $e');
      throw StorageException('Failed to store GitHub account', originalError: e);
    }
  }

  Future<String?> readGitHubAccount() async {
    try {
      return await _storage.read(key: _githubAccountKey);
    } catch (e) {
      dLog('[SecureStorage] readGitHubAccount failed: $e');
      throw StorageException('Failed to read GitHub account', originalError: e);
    }
  }

  Future<void> deleteGitHubAccount() async {
    try {
      await _storage.delete(key: _githubAccountKey);
    } catch (e) {
      dLog('[SecureStorage] deleteGitHubAccount failed: $e');
      throw StorageException('Failed to delete GitHub account', originalError: e);
    }
  }

  // Ollama URL
  Future<void> writeOllamaUrl(String url) async {
    try {
      await _storage.write(key: _ollamaUrlKey, value: url);
    } catch (e) {
      dLog('[SecureStorage] writeOllamaUrl failed: $e');
      throw StorageException('Failed to store Ollama URL', originalError: e);
    }
  }

  Future<String?> readOllamaUrl() async {
    try {
      return await _storage.read(key: _ollamaUrlKey);
    } catch (e) {
      dLog('[SecureStorage] readOllamaUrl failed: $e');
      throw StorageException('Failed to read Ollama URL', originalError: e);
    }
  }

  Future<void> deleteOllamaUrl() async {
    try {
      await _storage.delete(key: _ollamaUrlKey);
    } catch (e) {
      dLog('[SecureStorage] deleteOllamaUrl failed: $e');
      throw StorageException('Failed to delete Ollama URL', originalError: e);
    }
  }

  // Anthropic transport ('api-key' | 'cli')
  Future<void> writeAnthropicTransport(String value) async {
    try {
      await _storage.write(key: _anthropicTransportKey, value: value);
    } catch (e) {
      dLog('[SecureStorage] writeAnthropicTransport failed: $e');
      throw StorageException('Failed to store Anthropic transport', originalError: e);
    }
  }

  Future<String?> readAnthropicTransport() async {
    try {
      return await _storage.read(key: _anthropicTransportKey);
    } catch (e) {
      dLog('[SecureStorage] readAnthropicTransport failed: $e');
      throw StorageException('Failed to read Anthropic transport', originalError: e);
    }
  }

  Future<void> deleteAnthropicTransport() async {
    try {
      await _storage.delete(key: _anthropicTransportKey);
    } catch (e) {
      dLog('[SecureStorage] deleteAnthropicTransport failed: $e');
      throw StorageException('Failed to delete Anthropic transport', originalError: e);
    }
  }

  // OpenAI transport ('api-key' | 'cli')
  Future<void> writeOpenaiTransport(String value) async {
    try {
      await _storage.write(key: _openaiTransportKey, value: value);
    } catch (e) {
      dLog('[SecureStorage] writeOpenaiTransport failed: $e');
      throw StorageException('Failed to store OpenAI transport', originalError: e);
    }
  }

  Future<String?> readOpenaiTransport() async {
    try {
      return await _storage.read(key: _openaiTransportKey);
    } catch (e) {
      dLog('[SecureStorage] readOpenaiTransport failed: $e');
      throw StorageException('Failed to read OpenAI transport', originalError: e);
    }
  }

  Future<void> deleteOpenaiTransport() async {
    try {
      await _storage.delete(key: _openaiTransportKey);
    } catch (e) {
      dLog('[SecureStorage] deleteOpenaiTransport failed: $e');
      throw StorageException('Failed to delete OpenAI transport', originalError: e);
    }
  }

  Future<bool> hasAnyApiKey() async {
    try {
      final all = await _storage.readAll();
      return all.keys.any((k) => k.startsWith('api_key_'));
    } catch (e) {
      dLog('[SecureStorage] hasAnyApiKey failed — keychain unavailable: $e');
      throw StorageException('Failed to check API keys', originalError: e);
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
      dLog('[SecureStorage] deleteAll readAll failed: $e');
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
      dLog('[SecureStorage] writeCustomEndpoint failed: $e');
      throw StorageException('Failed to store custom endpoint', originalError: e);
    }
  }

  Future<String?> readCustomEndpoint() async {
    try {
      return await _storage.read(key: _customEndpointKey);
    } catch (e) {
      dLog('[SecureStorage] readCustomEndpoint failed: $e');
      throw StorageException('Failed to read custom endpoint', originalError: e);
    }
  }

  Future<void> deleteCustomEndpoint() async {
    try {
      await _storage.delete(key: _customEndpointKey);
    } catch (e) {
      dLog('[SecureStorage] deleteCustomEndpoint failed: $e');
      throw StorageException('Failed to delete custom endpoint', originalError: e);
    }
  }

  Future<void> writeCustomApiKey(String apiKey) async {
    try {
      await _storage.write(key: _customApiKeyKey, value: apiKey);
    } catch (e) {
      dLog('[SecureStorage] writeCustomApiKey failed: $e');
      throw StorageException('Failed to store custom API key', originalError: e);
    }
  }

  Future<String?> readCustomApiKey() async {
    try {
      return await _storage.read(key: _customApiKeyKey);
    } catch (e) {
      dLog('[SecureStorage] readCustomApiKey failed: $e');
      throw StorageException('Failed to read custom API key', originalError: e);
    }
  }

  Future<void> deleteCustomApiKey() async {
    try {
      await _storage.delete(key: _customApiKeyKey);
    } catch (e) {
      dLog('[SecureStorage] deleteCustomApiKey failed: $e');
      throw StorageException('Failed to delete custom API key', originalError: e);
    }
  }
}
