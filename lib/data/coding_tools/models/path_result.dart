// lib/data/coding_tools/models/path_result.dart

import 'coding_tool_result.dart';

/// Return type for [ToolContext.safePath]. Either carries the vetted
/// absolute path (plus a display-safe form of the raw arg) or a pre-built
/// [CodingToolResult] error the caller should return directly.
sealed class PathResult {
  const PathResult();
}

final class PathOk extends PathResult {
  const PathOk(this.abs, this.displayRaw);

  /// Absolute, normalized path that passed project-boundary and denylist
  /// checks. Safe to hand to the filesystem repository.
  final String abs;

  /// Sanitized raw arg (control chars stripped, length-capped) suitable
  /// for embedding in success or error messages returned to the model.
  final String displayRaw;
}

final class PathErr extends PathResult {
  const PathErr(this.result);

  /// Pre-built [CodingToolResult.error] the caller should return directly.
  final CodingToolResult result;
}
