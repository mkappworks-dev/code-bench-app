/// Raised by denylist mutations when the entry value is blank after trimming.
class CodingToolsInvalidEntryException implements Exception {
  const CodingToolsInvalidEntryException();

  @override
  String toString() => 'CodingToolsInvalidEntryException()';
}

/// Raised by denylist mutations when the entry already exists in the
/// user-added set or in the baseline defaults.
class CodingToolsDuplicateEntryException implements Exception {
  const CodingToolsDuplicateEntryException();

  @override
  String toString() => 'CodingToolsDuplicateEntryException()';
}

/// Raised when a file or directory path does not exist.
class CodingToolsNotFoundException implements Exception {
  CodingToolsNotFoundException(this.path);
  final String path;
  @override
  String toString() => 'Not found: $path';
}

/// Raised when a filesystem I/O error occurs (permission denied, disk full,
/// etc.). Distinct from [CodingToolsNotFoundException].
class CodingToolsDiskException implements Exception {
  CodingToolsDiskException(this.message);
  final String message;
  @override
  String toString() => 'Disk I/O error: $message';
}

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

  /// 0 = not found; >1 = multiple occurrences.
  final int matchCount;

  @override
  String toString() => 'CodingToolAmbiguousMatchException($matchCount)';
}
