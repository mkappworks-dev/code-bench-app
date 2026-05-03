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

  /// Snapshot of the account at the moment [startDeviceFlow] was called.
  /// Used by [cancelDeviceFlow] to restore state if the user cancels a
  /// re-authentication attempt — without this, `state = AsyncLoading()`
  /// would have already wiped any prior `AsyncData` value.
  GitHubAccount? _accountBeforeDeviceFlow;

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
    // Snapshot the prior account before transitioning to AsyncLoading so a
    // subsequent cancel can restore it (see [cancelDeviceFlow]).
    _accountBeforeDeviceFlow = state.value;
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
    final result = await AsyncValue.guard(() async {
      return svc.pollForUserToken(code.deviceCode, code.interval, cancelSignal: cancelSignal.future);
    });
    // If the user cancelled, [cancelDeviceFlow] has already restored the
    // pre-existing account state — don't clobber it with whatever the
    // poller returned (typically null on cancel, but never meaningful).
    if (cancelSignal.isCompleted) return;
    state = result;
  }

  /// Cancels in-flight polling.
  ///
  /// Cancellation only transitions state when the device flow is actually
  /// in progress (`AsyncLoading`). In that case we restore the account
  /// snapshot taken at [startDeviceFlow], so cancelling a re-auth attempt
  /// does not clobber an existing signed-in account. If state is already
  /// `AsyncData` or `AsyncError`, cancel is a no-op against state and only
  /// releases the poll loop.
  void cancelDeviceFlow() {
    final signal = _cancelSignal;
    if (signal != null && !signal.isCompleted) {
      signal.complete();
    }
    _cancelSignal = null;
    if (state is AsyncLoading) {
      state = AsyncData(_accountBeforeDeviceFlow);
    }
    _accountBeforeDeviceFlow = null;
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
