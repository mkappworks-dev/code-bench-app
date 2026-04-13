import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/models/ai_model.dart';
import '../../../data/ai/repository/ai_repository_impl.dart';
import '../../../data/ai/repository/api_key_test_repository_impl.dart';
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
      return await ref.read(apiKeyTestRepositoryProvider).testApiKey(provider, key);
    } catch (e, st) {
      dLog('[SettingsActions] testApiKey failed: $e\n$st');
      return false;
    }
  }

  Future<bool> testOllamaUrl(String url) => ref.read(apiKeyTestRepositoryProvider).testOllamaUrl(url);

  /// Persists [key] for [provider]. Emits [SettingsStorageFailed] on error.
  Future<void> saveApiKey(String provider, String key) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(settingsServiceProvider).writeApiKey(provider, key);
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
