import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_sidebar_failure.freezed.dart';

@freezed
sealed class ProjectSidebarFailure with _$ProjectSidebarFailure {
  /// A project at [path] is already tracked in Code Bench.
  const factory ProjectSidebarFailure.duplicatePath(String path) = ProjectSidebarDuplicatePath;

  /// The supplied path is invalid or does not exist on disk.
  const factory ProjectSidebarFailure.invalidPath(String reason) = ProjectSidebarInvalidPath;

  /// A database / storage operation failed.
  const factory ProjectSidebarFailure.storageError(String message) = ProjectSidebarStorageError;

  const factory ProjectSidebarFailure.unknown(Object error) = ProjectSidebarUnknownError;
}
