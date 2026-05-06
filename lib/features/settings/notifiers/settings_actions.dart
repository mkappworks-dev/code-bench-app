import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/settings/settings_service.dart';
import '../../github/notifiers/github_auth_notifier.dart';

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

  /// Wipes all user data in sequence. Returns the list of step names that
  /// failed (empty means full success) and whether GitHub was successfully
  /// signed out — callers should prompt the user to revoke the token on
  /// GitHub's side when [githubSignedOut] is true.
  Future<({List<String> failures, bool githubSignedOut})> wipeAllData() async {
    final failures = <String>[];
    var githubSignedOut = false;

    // Sign out from GitHub before the keychain/DB wipe so the notifier state
    // is cleared. On failure we still proceed with the remaining steps.
    if (ref.read(gitHubAuthProvider).value != null) {
      await ref.read(gitHubAuthProvider.notifier).signOut();
      if (ref.read(gitHubAuthProvider).hasError) {
        dLog('[SettingsActions] wipeAllData GitHub sign-out failed');
        failures.add('GitHub sign-out');
      } else {
        githubSignedOut = true;
      }
    }

    failures.addAll(await ref.read(settingsServiceProvider).wipeAllData());
    ref.invalidate(aiRepositoryProvider);
    return (failures: failures, githubSignedOut: githubSignedOut);
  }
}
