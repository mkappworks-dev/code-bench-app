// lib/features/update/notifiers/update_failure.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_failure.freezed.dart';

@freezed
sealed class UpdateFailure with _$UpdateFailure {
  const factory UpdateFailure.networkError([String? detail]) = UpdateNetworkError;
  const factory UpdateFailure.downloadFailed([String? detail]) = UpdateDownloadFailed;
  const factory UpdateFailure.installFailed([String? detail]) = UpdateInstallFailed;
  const factory UpdateFailure.unknown(Object error) = UpdateUnknownError;
}
