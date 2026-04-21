import 'package:freezed_annotation/freezed_annotation.dart';

part 'coding_tools_denylist_failure.freezed.dart';

@freezed
sealed class CodingToolsDenylistFailure with _$CodingToolsDenylistFailure {
  /// Entry text was empty, whitespace only, or matched no legal shape.
  const factory CodingToolsDenylistFailure.invalidEntry() = CodingToolsDenylistInvalidEntry;

  /// Entry is already present (user-added) or is already active (baseline).
  const factory CodingToolsDenylistFailure.duplicate() = CodingToolsDenylistDuplicate;

  /// SharedPreferences write failed.
  const factory CodingToolsDenylistFailure.saveFailed() = CodingToolsDenylistSaveFailed;

  const factory CodingToolsDenylistFailure.unknown(Object error) = CodingToolsDenylistUnknown;
}
