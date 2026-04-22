import 'package:freezed_annotation/freezed_annotation.dart';

part 'general_prefs_failure.freezed.dart';

@freezed
sealed class GeneralPrefsFailure with _$GeneralPrefsFailure {
  /// A preference write to secure / shared storage failed.
  const factory GeneralPrefsFailure.saveFailed() = GeneralPrefsSaveFailed;

  const factory GeneralPrefsFailure.unknown(Object error) = GeneralPrefsUnknownError;
}
