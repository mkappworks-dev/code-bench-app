const int kMaxApplyContentBytes = 1024 * 1024; // 1 MB

sealed class ApplyException implements Exception {}

class ProjectMissingException extends ApplyException {
  ProjectMissingException(this.projectPath);
  final String projectPath;
  @override
  String toString() => 'Project folder is missing: $projectPath';
}

class ApplyTooLargeException extends ApplyException {
  ApplyTooLargeException(this.bytes);
  final int bytes;
  @override
  String toString() => 'Content too large: $bytes bytes (max $kMaxApplyContentBytes bytes)';
}

class PathEscapeException extends ApplyException {
  PathEscapeException(this.filePath, this.projectPath);
  final String filePath;
  final String projectPath;
  @override
  String toString() => 'Path "$filePath" is outside project root "$projectPath"';
}

/// Thrown when a path matches the in-project denylist (dotfiles, key material,
/// credential filenames). Distinct from [PathEscapeException] so the caller can
/// render a user-appropriate message without leaking that a denylist exists.
class BlockedPathException extends ApplyException {
  BlockedPathException(this.filePath, this.reason);
  final String filePath;
  final String reason;
  @override
  String toString() => 'Blocked: "$filePath" ($reason)';
}

/// Thrown when a filesystem I/O error occurs during an apply operation (e.g.
/// permission denied, disk full). Distinct from [ProjectMissingException] which
/// indicates the root project directory is gone.
class ApplyDiskException extends ApplyException {
  ApplyDiskException(this.message);
  final String message;
  @override
  String toString() => 'Disk I/O error: $message';
}
