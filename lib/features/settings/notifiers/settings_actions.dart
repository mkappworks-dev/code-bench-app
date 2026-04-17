import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/api_key_test/api_key_test_service.dart';
import '../../../services/settings/settings_service.dart';
import 'settings_actions_failure.dart';

part 'settings_actions.g.dart';

/// Imperative actions that don't own observable state: wipe all data,
/// save a single API key, mark onboarding complete.
@Riverpod(keepAlive: true)
class SettingsActions extends _$SettingsActions {
  @override
  FutureOr<void> build() {}

  SettingsActionsFailure _asFailure(Object e, String providerName) => switch (e) {
    StorageException() => SettingsActionsFailure.storageFailed(providerName),
    _ => SettingsActionsFailure.unknown(e),
  };

  /// Returns `true` when [key] is valid for [provider]. Never throws —
  /// returns `false` on any exception so the UI can show an inline error
  /// without crashing.
  Future<bool> testApiKey(AIProvider provider, String key) async {
    try {
      return await ref.read(apiKeyTestServiceProvider).testApiKey(provider, key);
    } catch (e, st) {
      dLog('[SettingsActions] testApiKey failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` when [url] is reachable as an Ollama endpoint. Never
  /// throws — returns `false` on any exception so the UI can show an inline
  /// error without crashing.
  Future<bool> testOllamaUrl(String url) async {
    try {
      return await ref.read(apiKeyTestServiceProvider).testOllamaUrl(url);
    } catch (e, st) {
      dLog('[SettingsActions] testOllamaUrl failed: $e\n$st');
      return false;
    }
  }

  /// Persists [key] for [provider]. Emits [SettingsStorageFailed] on error.
  /// Invalidates [aiRepositoryProvider] on success so the live datasource
  /// picks up the new key immediately.
  Future<void> saveApiKey(String provider, String key) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(settingsServiceProvider).writeApiKey(provider, key);
        ref.invalidate(aiRepositoryProvider);
      } catch (e, st) {
        dLog('[SettingsActions] saveApiKey failed: $e');
        Error.throwWithStackTrace(_asFailure(e, provider), st);
      }
    });
  }

  Future<void> markOnboardingCompleted() async {
    try {
      await ref.read(settingsServiceProvider).markOnboardingCompleted();
    } catch (e, st) {
      dLog('[SettingsActions] markOnboardingCompleted failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> replayOnboarding() => ref.read(settingsServiceProvider).resetOnboarding();

  /// Wipes all user data in sequence. Returns a list of step names that
  /// failed (empty means full success).
  Future<List<String>> wipeAllData() async {
    final failures = await ref.read(settingsServiceProvider).wipeAllData();
    ref.invalidate(aiRepositoryProvider);
    return failures;
  }
}
