import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_failure.freezed.dart';

@freezed
sealed class UpdateFailure with _$UpdateFailure {
  const factory UpdateFailure.networkError([String? detail]) = UpdateNetworkError;
  const factory UpdateFailure.downloadFailed([String? detail]) = UpdateDownloadFailed;
  const factory UpdateFailure.installFailed([String? detail]) = UpdateInstallFailed;

  /// The bundle was successfully swapped but the `open`/`exit` step failed.
  /// The new version is already on disk — the user can recover by reopening
  /// the app from Finder or Spotlight without re-downloading.
  const factory UpdateFailure.relaunchFailed([String? detail]) = UpdateRelaunchFailed;
  const factory UpdateFailure.unknown(Object error) = UpdateUnknownError;
}
