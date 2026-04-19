// lib/features/settings/notifiers/settings_actions.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/settings/settings_service.dart';

part 'settings_actions.g.dart';

/// Imperative actions for onboarding and data wipe. API key test/save
/// methods have moved to ProvidersActions in features/providers/.
@Riverpod(keepAlive: true)
class SettingsActions extends _$SettingsActions {
  @override
  FutureOr<void> build() {}

  Future<void> markOnboardingCompleted() async {
    try {
      await ref.read(settingsServiceProvider).markOnboardingCompleted();
    } catch (e, st) {
      dLog('[SettingsActions] markOnboardingCompleted failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> replayOnboarding() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(settingsServiceProvider).resetOnboarding();
      } catch (e) {
        dLog('[SettingsActions] replayOnboarding failed: $e');
        rethrow;
      }
    });
  }

  /// Wipes all user data in sequence. Returns a list of step names that
  /// failed (empty means full success).
  Future<List<String>> wipeAllData() async {
    final failures = await ref.read(settingsServiceProvider).wipeAllData();
    ref.invalidate(aiRepositoryProvider);
    return failures;
  }
}
