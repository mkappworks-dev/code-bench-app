// lib/features/providers/notifiers/providers_actions.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/api_key_test/api_key_test_service.dart';
import '../../../services/providers/providers_service.dart';
import 'providers_failure.dart';

part 'providers_actions.g.dart';

@Riverpod(keepAlive: true)
class ProvidersActions extends _$ProvidersActions {
  @override
  FutureOr<void> build() {}

  ProvidersFailure _asFailure(Object e, String operationName) => switch (e) {
    StorageException() => ProvidersFailure.storageFailed(operationName),
    _ => ProvidersFailure.unknown(e),
  };

  // ── Connection tests (never throw, return bool) ───────────────────────────

  /// Returns `true` when [key] is valid for [provider]. Never throws.
  Future<bool> testApiKey(AIProvider provider, String key) async {
    try {
      return await ref.read(apiKeyTestServiceProvider).testApiKey(provider, key);
    } catch (e, st) {
      dLog('[ProvidersActions] testApiKey failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` when [url] is reachable as a custom OpenAI-compatible endpoint. Never throws.
  Future<bool> testCustomEndpoint(String url, String apiKey) async {
    try {
      return await ref.read(apiKeyTestServiceProvider).testCustomEndpoint(url, apiKey);
    } catch (e, st) {
      dLog('[ProvidersActions] testCustomEndpoint failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` when [url] is reachable as an Ollama endpoint. Never throws.
  Future<bool> testOllamaUrl(String url) async {
    try {
      return await ref.read(apiKeyTestServiceProvider).testOllamaUrl(url);
    } catch (e, st) {
      dLog('[ProvidersActions] testOllamaUrl failed: $e\n$st');
      return false;
    }
  }

  // ── Mutations (emit ProvidersFailure on error) ────────────────────────────

  /// Persists [key] for [provider] (string name). Emits [ProvidersFailure] on error.
  Future<void> saveApiKey(String provider, String key) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(providersServiceProvider).writeApiKey(provider, key);
        ref.invalidate(aiRepositoryProvider);
      } catch (e, st) {
        dLog('[ProvidersActions] saveApiKey failed: $e');
        Error.throwWithStackTrace(_asFailure(e, provider), st);
      }
    });
  }

  /// Saves or deletes [key] for [provider]. Deletes when [key] trims to empty.
  Future<void> saveKey(AIProvider provider, String key) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final svc = ref.read(providersServiceProvider);
        if (key.trim().isNotEmpty) {
          await svc.writeApiKey(provider.name, key.trim());
        } else {
          await svc.deleteApiKey(provider.name);
        }
        ref.invalidate(aiRepositoryProvider);
      } catch (e, st) {
        dLog('[ProvidersActions] saveKey(${provider.name}) failed: $e');
        Error.throwWithStackTrace(_asFailure(e, provider.name), st);
      }
    });
  }

  /// Deletes the stored key for [provider].
  Future<void> deleteKey(AIProvider provider) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(providersServiceProvider).deleteApiKey(provider.name);
        ref.invalidate(aiRepositoryProvider);
      } catch (e, st) {
        dLog('[ProvidersActions] deleteKey(${provider.name}) failed: $e');
        Error.throwWithStackTrace(_asFailure(e, provider.name), st);
      }
    });
  }

  /// Persists the Ollama base URL.
  Future<void> saveOllamaUrl(String url) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(providersServiceProvider).writeOllamaUrl(url.trim());
        ref.invalidate(aiRepositoryProvider);
      } catch (e, st) {
        dLog('[ProvidersActions] saveOllamaUrl failed: $e');
        Error.throwWithStackTrace(_asFailure(e, 'ollamaUrl'), st);
      }
    });
  }

  /// Removes the stored Ollama base URL.
  Future<void> clearOllamaUrl() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(providersServiceProvider).deleteOllamaUrl();
        ref.invalidate(aiRepositoryProvider);
      } catch (e, st) {
        dLog('[ProvidersActions] clearOllamaUrl failed: $e');
        Error.throwWithStackTrace(_asFailure(e, 'ollamaUrl'), st);
      }
    });
  }

  /// Persists the custom endpoint URL and API key together.
  Future<void> saveCustomEndpoint(String url, String apiKey) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final svc = ref.read(providersServiceProvider);
        await svc.writeCustomEndpoint(url.trim());
        await svc.writeCustomApiKey(apiKey.trim());
        ref.invalidate(aiRepositoryProvider);
      } catch (e, st) {
        dLog('[ProvidersActions] saveCustomEndpoint failed: $e');
        Error.throwWithStackTrace(_asFailure(e, 'customEndpoint'), st);
      }
    });
  }

  /// Removes the stored custom endpoint URL.
  Future<void> clearCustomEndpoint() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(providersServiceProvider).deleteCustomEndpoint();
        ref.invalidate(aiRepositoryProvider);
      } catch (e, st) {
        dLog('[ProvidersActions] clearCustomEndpoint failed: $e');
        Error.throwWithStackTrace(_asFailure(e, 'customEndpoint'), st);
      }
    });
  }

  /// Removes the stored custom API key.
  Future<void> clearCustomApiKey() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(providersServiceProvider).deleteCustomApiKey();
        ref.invalidate(aiRepositoryProvider);
      } catch (e, st) {
        dLog('[ProvidersActions] clearCustomApiKey failed: $e');
        Error.throwWithStackTrace(_asFailure(e, 'customApiKey'), st);
      }
    });
  }

  /// Bulk-saves all provider keys, Ollama URL, and custom endpoint/key.
  Future<void> saveAll({
    required Map<AIProvider, String> providerKeys,
    required String ollamaUrl,
    required String customEndpoint,
    required String customApiKey,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final svc = ref.read(providersServiceProvider);
        for (final entry in providerKeys.entries) {
          final key = entry.value.trim();
          if (key.isNotEmpty) {
            await svc.writeApiKey(entry.key.name, key);
          } else {
            await svc.deleteApiKey(entry.key.name);
          }
        }
        if (ollamaUrl.trim().isNotEmpty) await svc.writeOllamaUrl(ollamaUrl.trim());
        await svc.writeCustomEndpoint(customEndpoint.trim());
        await svc.writeCustomApiKey(customApiKey.trim());
        ref.invalidate(aiRepositoryProvider);
      } catch (e, st) {
        dLog('[ProvidersActions] saveAll failed: $e');
        Error.throwWithStackTrace(_asFailure(e, 'saveAll'), st);
      }
    });
  }
}
