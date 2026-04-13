import 'package:freezed_annotation/freezed_annotation.dart';

part 'ide_launch_failure.freezed.dart';

@freezed
sealed class IdeLaunchFailure with _$IdeLaunchFailure {
  const factory IdeLaunchFailure.launchFailed(String message) = IdeLaunchFailed;
  const factory IdeLaunchFailure.unknown(Object error) = IdeLaunchUnknownError;
}
