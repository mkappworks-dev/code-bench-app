import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  /// Returns the device code immediately so the dialog can display it.
  /// Notifier state transitions to AsyncData(GitHubAccount) when the user
  /// authorizes, AsyncError on failure, or AsyncData(null) on cancel.
  Future<DeviceCodeResponse> startDeviceFlow() async {
    state = const AsyncLoading();
    final svc = await ref.read(githubServiceProvider.future);
    final code = await svc.requestDeviceCode();

    final cancelSignal = Completer<void>();
    _cancelSignal = cancelSignal;
    unawaited(_pollInBackground(svc, code, cancelSignal));
    return code;
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
