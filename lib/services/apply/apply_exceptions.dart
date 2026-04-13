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
