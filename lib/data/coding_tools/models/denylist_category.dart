/// The four match categories used by the coding-tools path guard.
/// Order matches the order they appear in the Settings UI (top → bottom).
enum DenylistCategory {
  /// Matches a whole path segment (case-insensitive). Covers entire
  /// directory trees, e.g. `.git`, `.ssh`.
  segment,

  /// Exact filename match (case-insensitive) at any depth. E.g. `.env`.
  filename,

  /// Trailing extension (case-insensitive). E.g. `.pem`.
  extension,

  /// Filename prefix (case-insensitive). E.g. `.env.` matches
  /// `.env.local`, `.env.production`.
  prefix,
}
