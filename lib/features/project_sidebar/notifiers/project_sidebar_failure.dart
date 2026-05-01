import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_sidebar_failure.freezed.dart';

@freezed
sealed class ProjectSidebarFailure with _$ProjectSidebarFailure {
  /// A project at [path] is already tracked in Code Bench.
  const factory ProjectSidebarFailure.duplicatePath(String path) = ProjectSidebarDuplicatePath;

  /// The supplied path is invalid or does not exist on disk.
  const factory ProjectSidebarFailure.invalidPath(String reason) = ProjectSidebarInvalidPath;

  /// macOS denied filesystem access to [path] via TCC. Surfaced when the user
  /// has not yet granted permission for the parent directory (Documents,
  /// Downloads, Desktop) — the OS-level prompt is asynchronous, so the first
  /// access attempt always fails. Widgets must instruct the user to click
  /// **Allow** on the system dialog and retry, rather than crashing.
  const factory ProjectSidebarFailure.permissionDenied(String path) = ProjectSidebarPermissionDenied;

  /// A database / storage operation failed.
  const factory ProjectSidebarFailure.storageError(String message) = ProjectSidebarStorageError;

  const factory ProjectSidebarFailure.unknown(Object error) = ProjectSidebarUnknownError;
}
