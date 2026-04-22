// lib/data/coding_tools/models/grep_match.dart

/// One matched line returned by a grep datasource, with surrounding context.
class GrepMatch {
  const GrepMatch({
    required this.file,
    required this.lineNumber,
    required this.lineContent,
    required this.contextBefore,
    required this.contextAfter,
  });

  /// Project-relative path to the file containing the match.
  final String file;
  final int lineNumber;

  /// The matching line, trimmed of trailing newline.
  final String lineContent;

  /// Up to N lines before the match (N = contextLines requested).
  final List<String> contextBefore;

  /// Up to N lines after the match.
  final List<String> contextAfter;
}

/// Aggregate result from a grep datasource call.
class GrepResult {
  const GrepResult({required this.matches, required this.totalFound, required this.wasCapped});

  final List<GrepMatch> matches;

  /// Total matches found before the cap. When [wasCapped] is true this equals
  /// maxMatches + 1 (sentinel); the true total may be higher.
  final int totalFound;

  /// True when results were truncated at the cap.
  final bool wasCapped;
}
