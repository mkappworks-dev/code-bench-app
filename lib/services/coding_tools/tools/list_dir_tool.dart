import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/effective_denylist.dart';
import '../../../data/coding_tools/models/path_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../data/coding_tools/repository/coding_tools_repository.dart';
import '../../../data/coding_tools/repository/coding_tools_repository_impl.dart';
import '../../../data/apply/apply_exceptions.dart';

part 'list_dir_tool.g.dart';

@riverpod
ListDirTool listDirTool(Ref ref) => ListDirTool(repo: ref.watch(codingToolsRepositoryProvider));

class ListDirTool extends Tool {
  ListDirTool({required this.repo});
  final CodingToolsRepository repo;

  static const int _kMaxListEntries = 500;
  static const int _kMaxListDepth = 3;

  @override
  String get name => 'list_dir';
  @override
  ToolCapability get capability => ToolCapability.readOnly;
  @override
  String get description => 'List entries in a directory inside the active project.';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
      'recursive': {'type': 'boolean', 'default': false},
    },
    'required': ['path'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    final raw = ctx.args['path'];
    if (raw is! String || raw.isEmpty) {
      return CodingToolResult.error('list_dir requires a non-empty "path"');
    }
    final displayRaw = ctx.sanitizeForError(raw);
    final recursive = ctx.args['recursive'] == true;
    final abs = p.isAbsolute(raw) ? p.normalize(raw) : p.normalize(p.join(ctx.projectPath, raw));

    try {
      final normalAbs = p.normalize(p.absolute(abs));
      final normalRoot = p.normalize(p.absolute(ctx.projectPath));
      if (normalAbs != normalRoot) {
        // Non-root: run full safePath check (boundary + denylist).
        final pr = ctx.safePath('path', verb: 'List', noun: 'directory');
        if (pr is PathErr) return pr.result;
      } else {
        // Root path is trusted (set by the user at project-add time); only
        // verify it still exists rather than running the full safePath ritual.
        if (!await repo.directoryExists(normalRoot)) {
          throw ProjectMissingException(ctx.projectPath);
        }
      }
      if (!await repo.directoryExists(abs)) {
        return CodingToolResult.error('"$displayRaw" is not a directory or does not exist.');
      }

      final entries = await repo.listDirectory(abs, recursive: recursive);
      final buffer = StringBuffer();
      var count = 0;
      for (final entry in entries) {
        final rel = p.relative(entry.path, from: abs);
        final depth = rel.split(p.separator).length;
        if (recursive && depth > _kMaxListDepth) continue;
        if (_isDeniedRel(p.relative(entry.path, from: ctx.projectPath), ctx.denylist)) continue;
        buffer.writeln('- $rel (${entry.entityType})');
        count++;
        if (count >= _kMaxListEntries) {
          buffer.writeln('(truncated, $_kMaxListEntries+ entries)');
          break;
        }
      }
      return CodingToolResult.success(buffer.toString().trimRight());
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } catch (e) {
      dLog('[ListDirTool] listDirectory failed: $e');
      return CodingToolResult.error('Cannot list "$displayRaw": I/O error.');
    }
  }

  bool _isDeniedRel(String relPath, EffectiveDenylist denylist) {
    for (final segRaw in p.split(relPath)) {
      final seg = segRaw.toLowerCase();
      if (seg.isEmpty || seg == '.' || seg == '..') continue;
      if (denylist.segments.contains(seg)) return true;
      if (denylist.filenames.contains(seg)) return true;
      if (denylist.prefixes.any(seg.startsWith)) return true;
      final ext = p.extension(seg).toLowerCase();
      if (ext.isNotEmpty && denylist.extensions.contains(ext)) return true;
    }
    return false;
  }
}
