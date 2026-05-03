import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/github/models/device_code_response.dart';
import '../../../services/github/github_service.dart';

part 'github_auth_notifier.g.dart';

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubService] directly.
@Riverpod(keepAlive: true)
class GitHubAuthNotifier extends _$GitHubAuthNotifier {
  Completer<void>? _cancelSignal;

  @override
  Future<GitHubAccount?> build() async {
    final svc = await ref.watch(githubServiceProvider.future);
    return svc.getStoredAccount();
  }

  /// Requests a device code from GitHub and starts background polling.
  ///
  /// Returns the device code immediately so the dialog can display it, or
  /// `null` if the request itself failed (e.g. network down, GitHub
  /// unreachable, bad client_id) — in that case the notifier transitions to
  /// [AsyncError] so the dialog's `ref.listen` can render the error.
  ///
  /// Notifier state transitions:
  /// - `AsyncLoading` → set immediately on call
  /// - `AsyncError`   → request-device-code failure (returns `null`)
  /// - `AsyncData(GitHubAccount)` → user authorizes (set by background poll)
  /// - `AsyncError`   → polling failure (set by background poll)
  /// - `AsyncData(null)` → user cancels via [cancelDeviceFlow]
  Future<DeviceCodeResponse?> startDeviceFlow() async {
    state = const AsyncLoading();
    try {
      final svc = await ref.read(githubServiceProvider.future);
      final code = await svc.requestDeviceCode();

      final cancelSignal = Completer<void>();
      _cancelSignal = cancelSignal;
      unawaited(_pollInBackground(svc, code, cancelSignal));
      return code;
    } catch (e, st) {
      dLog('[GitHubAuthNotifier] startDeviceFlow request failed: ${e.runtimeType}');
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> _pollInBackground(GitHubService svc, DeviceCodeResponse code, Completer<void> cancelSignal) async {
    state = await AsyncValue.guard(() async {
      return svc.pollForUserToken(code.deviceCode, code.interval, cancelSignal: cancelSignal.future);
    });
  }

  /// Cancels in-flight polling. State returns to AsyncData(null).
  void cancelDeviceFlow() {
    final signal = _cancelSignal;
    if (signal != null && !signal.isCompleted) {
      signal.complete();
    }
    _cancelSignal = null;
    state = const AsyncData(null);
  }

  /// Deletes the stored token, then clears account state on success.
  ///
  /// We must delete before clearing: an optimistic `AsyncData(null)` followed
  /// by a failed keychain delete would leave the token on disk while the UI
  /// reports "signed out", and the next `build()` would silently
  /// re-authenticate from the leaked credential. On cleanup failure the
  /// notifier surfaces an [AsyncError] so a listener can warn the user.
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final svc = await ref.read(githubServiceProvider.future);
      await svc.signOut();
      return null;
    });
  }

  /// Validates [token] against the GitHub API, persists it on success, and
  /// updates state. The token never leaves the service layer.
  Future<void> signInWithPat(String token) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final svc = await ref.read(githubServiceProvider.future);
      return svc.signInWithPat(token);
    });
  }
}
