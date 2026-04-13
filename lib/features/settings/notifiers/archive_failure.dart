import 'package:freezed_annotation/freezed_annotation.dart';

part 'archive_failure.freezed.dart';

@freezed
sealed class ArchiveFailure with _$ArchiveFailure {
  const factory ArchiveFailure.storage([String? detail]) = ArchiveStorageError;
  const factory ArchiveFailure.unknown(Object error) = ArchiveUnknownError;
}
