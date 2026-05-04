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

/// Snapshot of the most recent check attempt — both the timestamp and whether
/// it failed. Persisting on failure too means "Last checked" reflects the last
/// time we actually tried, not just the last time we succeeded.
typedef UpdateLastChecked = ({DateTime at, bool failed});

@Riverpod(keepAlive: true)
Future<UpdateLastChecked?> updateLastChecked(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final iso = prefs.getString(AppConstants.prefUpdateLastChecked);
  if (iso == null) return null;
  final at = DateTime.tryParse(iso);
  if (at == null) {
    // Pref store has a value that no longer parses as ISO-8601 — log a
    // breadcrumb (a silent collapse to "Never checked" hides this from any
    // future debugging) and clear both keys so we don't keep tripping on it.
    // The clear itself can fail on a wedged pref store; surface that as a
    // separate `sLog` so the corruption signal isn't doubly silent.
    dLog('[UpdateLastChecked] discarding malformed ISO of length ${iso.length}');
    try {
      await prefs.remove(AppConstants.prefUpdateLastChecked);
      await prefs.remove(AppConstants.prefUpdateLastCheckedFailed);
    } on Exception catch (e, st) {
      sLog('[UpdateLastChecked] failed to clear malformed pref: ${e.runtimeType}: $e\n$st');
    }
    return null;
  }
  final failed = prefs.getBool(AppConstants.prefUpdateLastCheckedFailed) ?? false;
  return (at: at, failed: failed);
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
    if (state is UpdateStateChecking ||
        state is UpdateStateDownloading ||
        state is UpdateStateInstalling ||
        state is UpdateStateReadyToRestart) {
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
      await _persistLastChecked(failed: true);
      return;
    } catch (e, st) {
      dLog('[UpdateNotifier] checkForUpdates failed: $e\n$st');
      state = UpdateState.error(_asFailure(e));
      await _persistLastChecked(failed: true);
      return;
    }

    state = info != null ? UpdateState.available(info) : const UpdateState.upToDate();
    await _persistLastChecked(failed: false);
  }

  /// Persist the most recent check attempt — both the timestamp and whether
  /// it failed. A SharedPreferences hiccup must not poison the in-memory state
  /// transition that was already made by the caller, but the swallow is
  /// narrowed to `Exception` (not `Object`) so programming `Error` types
  /// (TypeError, ArgumentError) still surface during development.
  /// `Exception` rather than `PlatformException` covers `MissingPluginException`
  /// too — they're sibling classes, and missing-plugin races during hot-restart
  /// would otherwise crash the notifier. The user-visible signal that
  /// persistence failed is that "Last checked" stays put — by design, since
  /// `state` already carries any operation error.
  Future<void> _persistLastChecked({required bool failed}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUpdateLastChecked, DateTime.now().toIso8601String());
      await prefs.setBool(AppConstants.prefUpdateLastCheckedFailed, failed);
      ref.invalidate(updateLastCheckedProvider);
    } on Exception catch (e, st) {
      // `sLog` (not `dLog`) — this only ever shows up in production and has
      // no user-visible signal; we need it in release-build logs.
      sLog('[UpdateNotifier] persisting lastChecked failed: ${e.runtimeType}: $e\n$st');
    }
  }

  Future<void> downloadAndInstall(UpdateInfo info) async {
    if (state is UpdateStateDownloading || state is UpdateStateInstalling || state is UpdateStateReadyToRestart) {
      dLog('[UpdateNotifier] downloadAndInstall skipped — busy in ${state.runtimeType}');
      return;
    }

    // Phase 1 — download
    state = UpdateState.downloading(info, 0);
    final String zipPath;
    try {
      zipPath = await ref
          .read(updateServiceProvider)
          .downloadUpdate(
            info: info,
            onProgress: (progress) => state = UpdateState.downloading(info, progress.clamp(0.0, 1.0)),
          );
    } on UpdateDownloadException catch (e, st) {
      dLog('[UpdateNotifier] download failed: $e\n$st');
      state = UpdateState.error(UpdateFailure.downloadFailed(e.message));
      return;
    } catch (e, st) {
      dLog('[UpdateNotifier] downloadAndInstall download unexpected error: $e\n$st');
      state = UpdateState.error(_asFailure(e));
      return;
    }

    // Phase 2 — install
    state = UpdateState.installing(info);
    try {
      await ref.read(updateServiceProvider).applyUpdate(zipPath);
      state = UpdateState.readyToRestart(info);
    } on UpdateInstallException catch (e, st) {
      dLog('[UpdateNotifier] install failed: $e\n$st');
      state = UpdateState.error(UpdateFailure.installFailed(e.message));
    } catch (e, st) {
      dLog('[UpdateNotifier] downloadAndInstall install unexpected error: $e\n$st');
      state = UpdateState.error(_asFailure(e));
    }
  }

  void dismiss() => state = const UpdateState.idle();

  Future<void> restartNow() async {
    try {
      await ref.read(updateServiceProvider).relaunchApp();
      // If Process.start succeeded, exit(0) is called inside relaunchApp.
      // This catch fires only if Process.start throws before the process exits.
    } catch (e, st) {
      dLog('[UpdateNotifier] restartNow failed: $e\n$st');
      // Use relaunchFailed — NOT _asFailure — because applyUpdate already
      // succeeded: the bundle on disk is the new version. The user can recover
      // by reopening Code Bench from Finder without re-downloading.
      state = UpdateState.error(UpdateFailure.relaunchFailed(e.toString()));
    }
  }

  /// Reads the install-status sentinel left behind by the relaunch script of
  /// a previous attempt; if it reports a failure, surfaces it as state and
  /// then clears the sentinel so we don't show the same error twice.
  Future<void> _surfacePreviousInstallStatus() async {
    try {
      final svc = ref.read(updateServiceProvider);
      final status = await svc.readLastInstallStatus();
      if (status == null) return;
      if (status.status != 'ok') {
        if (state is UpdateStateIdle) {
          dLog('[UpdateNotifier] previous install reported failure: ${status.detail}');
          state = UpdateState.error(UpdateFailure.installFailed(status.detail));
        } else {
          dLog('[UpdateNotifier] previous install failure not surfaced — state is ${state.runtimeType}');
        }
      }
      await svc.clearLastInstallStatus();
    } catch (e, st) {
      // `sLog` (not `dLog`) — this fires once per session and has no other
      // user-visible signal. If the install-status sentinel is unreadable in
      // production, we need a release-build breadcrumb.
      sLog('[UpdateNotifier] _surfacePreviousInstallStatus failed: $e\n$st');
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
