/// Raised when `read_file` is asked for a file larger than [maxBytes].
class CodingToolFileTooLargeException implements Exception {
  const CodingToolFileTooLargeException(this.actualBytes, this.maxBytes);
  final int actualBytes;
  final int maxBytes;

  @override
  String toString() => 'CodingToolFileTooLargeException($actualBytes > $maxBytes)';
}

/// Raised when `read_file` cannot decode a file as UTF-8.
class CodingToolNotTextEncodedException implements Exception {
  const CodingToolNotTextEncodedException(this.path);
  final String path;

  @override
  String toString() => 'CodingToolNotTextEncodedException($path)';
}

/// Raised when `str_replace`'s `old_str` does not occur exactly once.
class CodingToolAmbiguousMatchException implements Exception {
  const CodingToolAmbiguousMatchException(this.matchCount);
  final int matchCount;

  @override
  String toString() => 'CodingToolAmbiguousMatchException($matchCount)';
}
