class DuplicateProjectPathException implements Exception {
  DuplicateProjectPathException(this.path);
  final String path;

  @override
  String toString() => 'A project at "$path" already exists in Code Bench.';
}

/// macOS denied filesystem access to [path] via TCC. Raised when a project
/// folder lives in a TCC-protected directory (Documents/Downloads/Desktop)
/// and the user has not yet granted permission. The OS-level prompt is
/// asynchronous, so the access call itself fails — the caller must surface
/// a "click Allow on the system dialog and retry" UX rather than crashing.
class ProjectPermissionDeniedException implements Exception {
  ProjectPermissionDeniedException(this.path);
  final String path;

  @override
  String toString() => 'macOS denied access to "$path".';
}
