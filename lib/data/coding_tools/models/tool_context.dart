import 'package:path/path.dart' as p;

import '../../../core/utils/debug_logger.dart';
import '../../apply/apply_exceptions.dart';
import '../../apply/repository/apply_repository.dart';
import 'coding_tool_result.dart';
import 'effective_denylist.dart';
import 'path_result.dart';

/// Request-scoped inputs to a [Tool.execute] call. Carries safety helpers that centralize path validation and denylist checks.
class ToolContext {
  ToolContext({
    required this.projectPath,
    required this.sessionId,
    required this.messageId,
    required this.args,
    required this.denylist,
  }) : assert(p.isAbsolute(projectPath), 'projectPath must be absolute');

  final String projectPath;
  final String sessionId;
  final String messageId;
  final Map<String, dynamic> args;
  final EffectiveDenylist denylist;

  /// Reads a path-shaped arg, enforces project-boundary + denylist.
  /// Returns [PathOk] with the vetted absolute path, or [PathErr] carrying
  /// a pre-built error result (with verb-aware phrasing) the caller
  /// should return.
  ///
  /// [verb] — the tool's action phrasing ("Read"/"Write"/"List"/"Edit"),
  /// used in the path-escape and denylist error messages.
  /// [noun] — what the tool operates on: "file" for read/write/edit,
  /// "directory" for list. Controls the `(sensitive {noun})` suffix in
  /// denylist-block errors. Defaults to "file".
  PathResult safePath(String argName, {required String verb, String noun = 'file'}) {
    final raw = args[argName];
    if (raw is! String || raw.isEmpty) {
      return PathErr(CodingToolResult.error('${_toolNameFromVerb(verb)} requires a non-empty "$argName"'));
    }
    final displayRaw = sanitizeForError(raw);
    final abs = p.isAbsolute(raw) ? p.normalize(raw) : p.normalize(p.join(projectPath, raw));

    try {
      ApplyRepository.assertWithinProject(abs, projectPath);
    } on PathEscapeException {
      sLog('[ToolContext] path-escape rejected: verb=$verb rel="${sanitizeForError(raw)}"');
      return PathErr(CodingToolResult.error('Path "$displayRaw" is outside the project root.'));
    } on ProjectMissingException {
      sLog('[ToolContext] project-missing rejected: verb=$verb');
      return PathErr(CodingToolResult.error('Project folder is missing.'));
    }

    final block = _checkDenied(abs);
    if (block != null) {
      sLog('[ToolContext] denied ${block.kind}: "${p.relative(abs, from: projectPath)}" ($block)');
      return PathErr(CodingToolResult.error('${verb}ing "$displayRaw" is blocked for safety (sensitive $noun).'));
    }

    return PathOk(abs, displayRaw);
  }

  /// Strips control chars and truncates to [max] characters. Used when
  /// embedding a raw arg into an error message fed back to the model.
  String sanitizeForError(String raw, {int max = 120}) {
    final stripped = raw.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ');
    return stripped.length > max ? '${stripped.substring(0, max)}…' : stripped;
  }

  _DenyMatch? _checkDenied(String abs) {
    final rel = p.relative(abs, from: projectPath);
    for (final segRaw in p.split(rel)) {
      final seg = segRaw.toLowerCase();
      if (seg.isEmpty || seg == '.' || seg == '..') continue;
      if (denylist.segments.contains(seg)) return _DenyMatch('segment', seg);
      if (denylist.filenames.contains(seg)) return _DenyMatch('filename', seg);
      if (denylist.prefixes.any(seg.startsWith)) return _DenyMatch('prefix', seg);
      final ext = p.extension(seg).toLowerCase();
      if (ext.isNotEmpty && denylist.extensions.contains(ext)) return _DenyMatch('extension', ext);
    }
    return null;
  }

  String _toolNameFromVerb(String verb) => switch (verb) {
    'Read' => 'read_file',
    'Write' => 'write_file',
    'List' => 'list_dir',
    'Edit' => 'str_replace',
    _ => verb.toLowerCase(),
  };
}

class _DenyMatch {
  const _DenyMatch(this.kind, this.value);
  final String kind; // 'segment' | 'filename' | 'prefix' | 'extension'
  final String value;

  @override
  String toString() => '$kind=$value';
}
