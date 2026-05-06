import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/update/models/update_info.dart';
import 'update_failure.dart';

part 'update_state.freezed.dart';

@freezed
sealed class UpdateState with _$UpdateState {
  const factory UpdateState.idle() = UpdateStateIdle;
  const factory UpdateState.checking() = UpdateStateChecking;
  const factory UpdateState.available(UpdateInfo info) = UpdateStateAvailable;
  const factory UpdateState.downloading(UpdateInfo info, double progress) = UpdateStateDownloading;
  const factory UpdateState.installing(UpdateInfo info) = UpdateStateInstalling;

  /// Install is complete; the bundle on disk is the new version.
  /// The relaunch path is re-derived from the live process at restart time
  /// (via [UpdateService.relaunchApp]) rather than being stored here.
  const factory UpdateState.readyToRestart(UpdateInfo info) = UpdateStateReadyToRestart;
  const factory UpdateState.upToDate() = UpdateStateUpToDate;
  const factory UpdateState.error(UpdateFailure failure) = UpdateStateError;
}
