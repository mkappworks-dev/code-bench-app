// lib/features/providers/notifiers/providers_actions.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/api_key_test/api_key_test_service.dart';
import '../../../services/providers/providers_service.dart';
import 'providers_actions_failure.dart';

part 'providers_actions.g.dart';

@Riverpod(keepAlive: true)
class ProvidersActions extends _$ProvidersActions {
  @override
  FutureOr<void> build() {}

  ProvidersActionsFailure _asFailure(Object e, String providerName) => switch (e) {
    StorageException() => ProvidersActionsFailure.storageFailed(providerName),
    _ => ProvidersActionsFailure.unknown(e),
  };

  /// Returns `true` when [key] is valid for [provider]. Never throws.
  Future<bool> testApiKey(AIProvider provider, String key) async {
    try {
      return await ref.read(apiKeyTestServiceProvider).testApiKey(provider, key);
    } catch (e, st) {
      dLog('[ProvidersActions] testApiKey failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` when [url] is reachable as a custom OpenAI-compatible
  /// endpoint. Never throws.
  Future<bool> testCustomEndpoint(String url, String apiKey) async {
    try {
      return await ref
          .read(apiKeyTestServiceProvider)
          .testCustomEndpoint(url, apiKey);
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

  /// Persists [key] for [provider]. Emits [ProvidersStorageFailed] on error.
  /// Invalidates [aiRepositoryProvider] on success so the live datasource
  /// picks up the new key immediately.
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
}
