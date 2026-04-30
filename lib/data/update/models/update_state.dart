// lib/data/update/models/update_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../features/settings/notifiers/update_failure.dart';
import 'update_info.dart';

part 'update_state.freezed.dart';

@freezed
sealed class UpdateState with _$UpdateState {
  const factory UpdateState.idle() = UpdateStateIdle;
  const factory UpdateState.checking() = UpdateStateChecking;
  const factory UpdateState.available(UpdateInfo info) = UpdateStateAvailable;
  const factory UpdateState.downloading(double progress) = UpdateStateDownloading;
  const factory UpdateState.installing() = UpdateStateInstalling;
  const factory UpdateState.upToDate() = UpdateStateUpToDate;
  const factory UpdateState.error(UpdateFailure failure) = UpdateStateError;
}
