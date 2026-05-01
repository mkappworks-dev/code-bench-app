// lib/features/update/notifiers/update_notifier.dart
import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/update/models/update_info.dart';
import '../../../data/update/update_exception.dart';
import '../../../services/update/update_service.dart';
import 'update_failure.dart';
import 'update_state.dart';

part 'update_notifier.g.dart';

@Riverpod(keepAlive: true)
Future<String?> updateLastChecked(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.prefUpdateLastChecked);
}

@Riverpod(keepAlive: true)
Future<String> packageVersion(Ref ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

@Riverpod(keepAlive: true)
class UpdateNotifier extends _$UpdateNotifier {
  @override
  UpdateState build() {
    // Surface a previous-install failure on the very first build so the user
    // sees an error instead of a silent "we restarted with no explanation."
    unawaited(_surfacePreviousInstallStatus());
    return const UpdateState.idle();
  }

  Future<void> checkForUpdates() async {
    if (state is UpdateStateChecking || state is UpdateStateDownloading || state is UpdateStateInstalling) {
      dLog('[UpdateNotifier] checkForUpdates skipped — busy in ${state.runtimeType}');
      return;
    }

    state = const UpdateState.checking();
    UpdateInfo? info;
    try {
      info = await ref.read(updateServiceProvider).checkForUpdate();
    } on UpdateNetworkException catch (e, st) {
      dLog('[UpdateNotifier] checkForUpdates network error: $e\n$st');
      state = UpdateState.error(UpdateFailure.networkError(e.message));
      return;
    } catch (e, st) {
      dLog('[UpdateNotifier] checkForUpdates failed: $e\n$st');
      state = UpdateState.error(_asFailure(e));
      return;
    }

    state = info != null ? UpdateState.available(info) : const UpdateState.upToDate();

    // Persist last-checked separately — a SharedPreferences hiccup must not
    // poison a successful check.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUpdateLastChecked, DateTime.now().toIso8601String());
      ref.invalidate(updateLastCheckedProvider);
    } catch (e, st) {
      dLog('[UpdateNotifier] persisting lastChecked failed: $e\n$st');
    }
  }

  Future<void> downloadAndInstall(UpdateInfo info) async {
    state = UpdateState.downloading(info, 0);
    try {
      final zipPath = await ref
          .read(updateServiceProvider)
          .downloadUpdate(info: info, onProgress: (progress) => state = UpdateState.downloading(info, progress));
      state = UpdateState.installing(info);
      await ref.read(updateServiceProvider).installUpdate(zipPath);
      // exit(0) is called inside installUpdate — code below is unreachable on success
    } on UpdateDownloadException catch (e, st) {
      dLog('[UpdateNotifier] download failed: $e\n$st');
      state = UpdateState.error(UpdateFailure.downloadFailed(e.message));
    } on UpdateInstallException catch (e, st) {
      dLog('[UpdateNotifier] install failed: $e\n$st');
      state = UpdateState.error(UpdateFailure.installFailed(e.message));
    } catch (e, st) {
      dLog('[UpdateNotifier] downloadAndInstall failed: $e\n$st');
      state = UpdateState.error(_asFailure(e));
    }
  }

  void dismiss() => state = const UpdateState.idle();

  /// Reads the install-status sentinel left behind by the relaunch script of
  /// a previous attempt; if it reports a failure, surfaces it as state and
  /// then clears the sentinel so we don't show the same error twice.
  Future<void> _surfacePreviousInstallStatus() async {
    try {
      final svc = ref.read(updateServiceProvider);
      final status = await svc.readLastInstallStatus();
      if (status == null) return;
      if (status.status != 'ok' && state is UpdateStateIdle) {
        dLog('[UpdateNotifier] previous install reported failure: ${status.detail}');
        state = UpdateState.error(UpdateFailure.installFailed(status.detail));
      }
      await svc.clearLastInstallStatus();
    } catch (e, st) {
      dLog('[UpdateNotifier] _surfacePreviousInstallStatus failed: $e\n$st');
    }
  }

  UpdateFailure _asFailure(Object e) => switch (e) {
    UpdateNetworkException() => UpdateFailure.networkError(e.message),
    UpdateDownloadException() => UpdateFailure.downloadFailed(e.message),
    UpdateInstallException() => UpdateFailure.installFailed(e.message),
    FormatException() => UpdateFailure.networkError(e.message),
    _ => UpdateFailure.unknown(e),
  };
}
