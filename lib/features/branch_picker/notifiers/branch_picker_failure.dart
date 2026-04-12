import 'package:freezed_annotation/freezed_annotation.dart';

part 'branch_picker_failure.freezed.dart';

@freezed
sealed class BranchPickerFailure with _$BranchPickerFailure {
  /// git binary missing or working directory deleted.
  const factory BranchPickerFailure.gitUnavailable() = BranchPickerGitUnavailable;

  /// Branch name fails validation (empty or starts with dash).
  const factory BranchPickerFailure.invalidName(String reason) = BranchPickerInvalidName;

  /// `git checkout` failed (e.g. uncommitted changes would be overwritten).
  const factory BranchPickerFailure.checkoutConflict(String message) = BranchPickerCheckoutConflict;

  /// `git checkout -b` failed (branch already exists, etc.).
  const factory BranchPickerFailure.createFailed(String message) = BranchPickerCreateFailed;

  const factory BranchPickerFailure.unknown(Object error) = BranchPickerUnknownError;
}
