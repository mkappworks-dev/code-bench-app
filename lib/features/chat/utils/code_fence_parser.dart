import 'package:path/path.dart' as p;

/// Maximum filename length accepted from a code fence info string.
/// Prevents DoS via megabyte-long filename headers and matches the
/// common POSIX/Windows PATH_MAX ballpark.
const int kMaxFilenameLength = 260;

final RegExp _windowsAbsoluteRe = RegExp(r'^([A-Za-z]:[/\\]|\\\\)');

bool _isWindowsAbsolute(String path) => _windowsAbsoluteRe.hasMatch(path);

/// Splits a code fence info string (e.g. "dart lib/main.dart") into
/// (language, filename?). Filename is null if no second word is present.
///
/// The filename is **untrusted AI input** and is validated here:
/// rejects empty, absolute paths, null bytes, control characters,
/// line breaks, and paths longer than [kMaxFilenameLength]. Invalid
/// filenames are dropped (treated as no filename) rather than raising,
/// so the Diff button simply does not appear.
(String language, String? filename) parseCodeFenceInfo(String info) {
  final parts = info.trim().split(RegExp(r'\s+'));
  final language = parts.first;
  if (parts.length < 2) return (language, null);

  // Whitespace (including \n, \r, \t) is stripped by the \s+ split, so we
  // only need to guard against null-byte injection, over-length, and
  // absolute paths that would bypass the project-root join.
  //
  // p.isAbsolute uses the host platform's context, so on macOS it misses
  // Windows drive-letter (C:\...) and UNC (\\server\...) paths. We check
  // those explicitly since AI-generated filenames can contain any syntax.
  final candidate = parts.sublist(1).join(' ');
  if (candidate.isEmpty ||
      candidate.length > kMaxFilenameLength ||
      candidate.contains('\u0000') ||
      p.isAbsolute(candidate) ||
      _isWindowsAbsolute(candidate)) {
    return (language, null);
  }
  return (language, candidate);
}
