import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/github/models/device_code_response.dart';
import '../../../services/github/github_service.dart';
import 'github_auth_failure.dart';

// Re-exports so widgets only need to import this one notifier file.
export '../../../data/github/models/repository.dart' show GitHubAccount;
export '../../../services/github/github_service.dart' show GitHubAppInstallation;

part 'github_auth_notifier.g.dart';

@riverpod
Future<List<GitHubAppInstallation>> githubInstallations(Ref ref) async {
  final svc = await ref.watch(githubServiceProvider.future);
  try {
    return await svc.getInstallations();
  } catch (e) {
    dLog('[githubInstallationsProvider] failed: ${e.runtimeType}');
    rethrow;
  }
}

@Riverpod(keepAlive: true)
class GitHubAuthNotifier extends _$GitHubAuthNotifier {
  Completer<void>? _cancelSignal;

  // Saved before AsyncLoading so cancel can restore it without clobbering an
  // already-signed-in account during a re-auth attempt.
  GitHubAccount? _accountBeforeDeviceFlow;

  @override
  Future<GitHubAccount?> build() async {
    final svc = await ref.watch(githubServiceProvider.future);
    final account = await svc.getStoredAccount();
    if (account != null) {
      unawaited(_validateInBackground(svc));
    }
    return account;
  }

  Future<void> _validateInBackground(GitHubService svc) async {
    final bool isValid;
    try {
      isValid = await svc.validateStoredToken();
    } catch (e) {
      // Transient failure — leave the user signed in; the next action will surface it.
      dLog('[GitHubAuthNotifier] background token validation transient failure: ${e.runtimeType}');
      return;
    }

    if (!isValid) {
      sLog('[GitHubAuthNotifier] stored token rejected by GitHub — signing out');
      try {
        await svc.signOut();
      } catch (e, st) {
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
      // ignore: unnecessary_statements
      state; // throws StateError on a disposed notifier
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Starts Device Flow auth. Returns the device code for the dialog to
  /// display, or `null` if the request failed (notifier transitions to
  /// `AsyncError`). State: `AsyncLoading` → `AsyncData(account)` on success,
  /// `AsyncError` on failure, `AsyncData(null)` if cancelled.
  Future<DeviceCodeResponse?> startDeviceFlow() async {
    // Complete any in-flight poll first so it can't race and clobber this one.
    final prior = _cancelSignal;
    if (prior != null && !prior.isCompleted) prior.complete();

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
    // cancelDeviceFlow already restored prior state — don't clobber it.
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
      // state = result BEFORE invalidate: the invalidation cascades up to
      // gitHubAuthProvider (AsyncLoading → AsyncData(account)), which would
      // fire ref.listen a second time while the dialog is still dismissing,
      // causing a double-pop and the NavigatorState !_debugLocked assertion.
      state = result;
      // Without this, githubApiDatasourceProvider keeps its app-start null
      // value and the first API call after sign-in throws StateError.
      ref.invalidate(githubApiDatasourceProvider);
    }
  }

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

  /// Re-fetches the GitHub App installations. Routed through the notifier so
  /// widgets never call `ref.invalidate(githubInstallationsProvider)` directly
  /// (forbidden by the architecture rule). Used by lifecycle observers and the
  /// disconnect dialog to pick up changes made on github.com.
  void refreshInstallations() {
    ref.invalidate(githubInstallationsProvider);
  }

  // Delete-before-clear: an optimistic AsyncData(null) followed by a failed
  // keychain delete would leave the token on disk with the UI showing signed-out.
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final svc = await ref.read(githubServiceProvider.future);
      await svc.signOut();
      return null;
    });
    // Invalidate AFTER the guard writes state — invalidation cascades up
    // through repo → service → auth notifier and would otherwise rebuild
    // build() before the guard's success value lands on state.
    if (!state.hasError) {
      ref.invalidate(githubApiDatasourceProvider);
    }
  }
}
