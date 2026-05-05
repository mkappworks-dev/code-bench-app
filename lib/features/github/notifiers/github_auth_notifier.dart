import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/github/models/app_installation.dart';
import '../../../data/github/models/device_code_response.dart';
import '../../../data/github/models/repository.dart';
import '../../../services/github/github_service.dart';
import 'github_auth_failure.dart';

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

  // Saved before AsyncLoading so cancel can restore it on re-auth.
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
      // Assign state before invalidating — invalidation cascades into build() and double-fires ref.listen, causing a double-pop.
      state = result;
      // Datasource holds a null token until invalidated after first sign-in.
      svc.invalidateApiDatasource();
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

  void refreshInstallations() {
    ref.invalidate(githubInstallationsProvider);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final svc = await ref.read(githubServiceProvider.future);
    state = await AsyncValue.guard(() async {
      await svc.signOut();
      return null;
    });
    // Invalidate after guard — cascades to build() and would overwrite the success state.
    if (!state.hasError) {
      svc.invalidateApiDatasource();
    }
  }
}
