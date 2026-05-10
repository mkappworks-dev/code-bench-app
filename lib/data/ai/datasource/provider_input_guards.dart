/// Shared input-validation guards used by AI provider datasources before
/// values cross the process / RPC boundary.
///
/// Centralized so every transport (Claude CLI, Codex app-server, future CLI
/// processes) validates `sessionId` against the same shape. Lives in the
/// datasource directory so it is colocated with its consumers.
library;

import 'package:path/path.dart' as p;

/// Accepts RFC-4122 lowercased UUIDs — the format our `Uuid.v4()` produces.
/// Anything else at the argv / RPC boundary is rejected defensively so a
/// stray value like `--dangerously-skip-perms` can never slip into flag
/// position, and a malformed resume cursor cannot hijack a foreign thread.
final RegExp uuidV4Regex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

/// Cross-platform workingDirectory guard. Rejects relative paths and the
/// filesystem root (POSIX `/`, Windows drive root like `C:\`). Existence is
/// checked separately by the caller (we don't depend on `dart:io` here).
bool isAcceptableWorkingDirectory(String path) {
  if (!p.isAbsolute(path)) return false;
  final normalized = p.normalize(path);
  final root = p.rootPrefix(normalized);
  if (normalized == root) return false;
  return true;
}
