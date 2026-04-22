import 'package:freezed_annotation/freezed_annotation.dart';

part 'code_apply_failure.freezed.dart';

@freezed
sealed class CodeApplyFailure with _$CodeApplyFailure {
  /// Project folder was deleted or moved off disk.
  const factory CodeApplyFailure.projectMissing() = CodeApplyProjectMissing;

  /// Attempted to write outside the project root.
  const factory CodeApplyFailure.outsideProject() = CodeApplyOutsideProject;

  /// Content or original file exceeded the size limit.
  const factory CodeApplyFailure.tooLarge(int bytes) = CodeApplyTooLarge;

  /// Low-level disk write failure.
  const factory CodeApplyFailure.diskWrite(String message) = CodeApplyDiskWrite;

  /// File was modified externally between the tool's read and write.
  const factory CodeApplyFailure.contentChanged() = CodeApplyContentChanged;

  const factory CodeApplyFailure.unknown(Object error) = CodeApplyUnknownError;
}
