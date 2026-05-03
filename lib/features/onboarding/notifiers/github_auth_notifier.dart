import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/github/models/device_code_response.dart';
import '../../../services/github/github_service.dart';
import 'github_auth_failure.dart';

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
    final account = await svc.getStoredAccount();
    if (account != null) {
      // Best-effort: ask GitHub whether the token is still good without
      // blocking the UI. A 401 here means the token was revoked while
      // the app was closed, in which case we transition to
      // AsyncError(GitHubAuthFailure.tokenRevoked()). Network/5xx are
      // silent — the next user-initiated call will surface the failure
      // if the token really is bad.
      unawaited(_validateInBackground(svc));
    }
    return account;
  }

  Future<void> _validateInBackground(GitHubService svc) async {
    final bool isValid;
    try {
      isValid = await svc.validateStoredToken();
    } catch (e) {
      // Transient (5xx, network timeout) — leave the user signed in and
      // let the next action surface it if the token is truly broken.
      dLog('[GitHubAuthNotifier] background token validation transient failure: ${e.runtimeType}');
      return;
    }

    if (!isValid) {
      sLog('[GitHubAuthNotifier] stored token rejected by GitHub — signing out');
      try {
        await svc.signOut();
      } catch (e, st) {
        // Keychain delete failed. Surface as a typed error so the UI can
        // prompt the user to sign out again.
        if (!_isMounted) return;
        state = AsyncError(GitHubAuthFailure.signOutFailed(userMessage(e)), st);
        return;
      }
      if (!_isMounted) return;
      state = AsyncError(GitHubAuthFailure.tokenRevoked(), StackTrace.current);
    }
  }

  bool get _isMounted {
    try {
      // Reading state on a disposed notifier throws StateError.
      // ignore: unnecessary_statements
      state;
      return true;
    } catch (_) {
      return false;
    }
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
    // Complete any in-flight poll before starting a new one. Prevents a
    // stale poller from racing and clobbering the fresh flow's result.
    final prior = _cancelSignal;
    if (prior != null && !prior.isCompleted) prior.complete();

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
      state = AsyncError(GitHubAuthFailure.requestFailed(userMessage(e)), st);
      return null;
    }
  }

  Future<void> _pollInBackground(GitHubService svc, DeviceCodeResponse code, Completer<void> cancelSignal) async {
    final result = await AsyncValue.guard(() async {
      return svc.pollForUserToken(code.deviceCode, code.interval, code.expiresIn, cancelSignal: cancelSignal.future);
    });
    // If the user cancelled, [cancelDeviceFlow] has already restored the
    // pre-existing account state — don't clobber it with whatever the
    // poller returned (typically null on cancel, but never meaningful).
    if (cancelSignal.isCompleted) {
      if (result is AsyncError) {
        dLog('[GitHubAuthNotifier] dropping post-cancel error: ${result.error.runtimeType}');
      }
      return;
    }
    if (!_isMounted) return;
    if (result is AsyncError) {
      state = AsyncError(GitHubAuthFailure.pollFailed(userMessage(result.error!)), result.stackTrace!);
    } else {
      state = result;
    }
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
}
