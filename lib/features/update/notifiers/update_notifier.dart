// lib/features/update/notifiers/update_notifier.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/update/models/update_info.dart';
import '../../../data/update/models/update_state.dart';
import '../../../data/update/update_exception.dart';
import '../../../services/update/update_service.dart';
import 'update_failure.dart';

part 'update_notifier.g.dart';

@Riverpod(keepAlive: true)
Future<String?> updateLastChecked(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.prefUpdateLastChecked);
}

@Riverpod(keepAlive: true)
class UpdateNotifier extends _$UpdateNotifier {
  @override
  UpdateState build() => const UpdateState.idle();

  Future<void> checkForUpdates() async {
    // Guard: do not interrupt an in-progress download or install
    if (state is UpdateStateChecking || state is UpdateStateDownloading || state is UpdateStateInstalling) return;

    state = const UpdateState.checking();
    try {
      final info = await ref.read(updateServiceProvider).checkForUpdate();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUpdateLastChecked, DateTime.now().toIso8601String());
      ref.invalidate(updateLastCheckedProvider);
      state = info != null ? UpdateState.available(info) : const UpdateState.upToDate();
    } on UpdateNetworkException catch (e, st) {
      dLog('[UpdateNotifier] checkForUpdates network error: $e\n$st');
      state = UpdateState.error(UpdateFailure.networkError(e.message));
    } catch (e, st) {
      dLog('[UpdateNotifier] checkForUpdates failed: $e\n$st');
      state = UpdateState.error(UpdateFailure.unknown(e));
    }
  }

  Future<void> downloadAndInstall(UpdateInfo info) async {
    state = const UpdateState.downloading(0);
    try {
      final zipPath = await ref
          .read(updateServiceProvider)
          .downloadUpdate(info: info, onProgress: (progress) => state = UpdateState.downloading(progress));
      state = const UpdateState.installing();
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
      state = UpdateState.error(UpdateFailure.unknown(e));
    }
  }

  void dismiss() => state = const UpdateState.idle();
}
