import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/effective_denylist.dart';
import '../../../data/coding_tools/models/path_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../data/coding_tools/models/directory_entry.dart';
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
        // The root path is the project boundary itself and cannot be validated
        // by assertWithinProject (which requires the file to be strictly *inside*
        // the root). It is trusted because the user chose it at project-add time.
        // All entries returned from the root are still denylist-filtered in the
        // output loop via _isDeniedRel.
        if (!await repo.directoryExists(normalRoot)) {
          throw ProjectMissingException(ctx.projectPath);
        }
      }
      if (!await repo.directoryExists(abs)) {
        return CodingToolResult.error('"$displayRaw" is not a directory or does not exist.');
      }

      // For recursive listing, walk iteratively to prune denied subtrees before
      // descending into them. This avoids walking .git/objects or node_modules
      // in full before the denylist filter fires (DoS foot-gun + error leakage).
      final List<DirectoryEntry> entries;
      if (recursive) {
        final walked = <DirectoryEntry>[];
        await _walkDir(abs, ctx.projectPath, ctx.denylist, 1, walked);
        entries = walked;
      } else {
        entries = await repo.listDirectory(abs, recursive: false);
      }

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
    } catch (e, st) {
      dLog('[ListDirTool] listDirectory failed: ${e.runtimeType} $e\n$st');
      return CodingToolResult.error('Cannot list "$displayRaw": I/O error.');
    }
  }

  /// Walks [dir] recursively, pruning denied paths before descending into them.
  /// [depth] is 1-based (1 = direct children of the original listing root).
  /// Stops at [_kMaxListDepth] or [_kMaxListEntries] to bound I/O.
  Future<void> _walkDir(
    String dir,
    String projectPath,
    EffectiveDenylist denylist,
    int depth,
    List<DirectoryEntry> result,
  ) async {
    if (depth > _kMaxListDepth || result.length >= _kMaxListEntries) return;
    List<DirectoryEntry> dirEntries;
    try {
      dirEntries = await repo.listDirectory(dir, recursive: false);
    } on CodingToolsDiskException {
      // Skip directories we cannot read (permission denied, etc.) rather than
      // aborting the whole listing or leaking that a denied dir had odd permissions.
      return;
    }
    for (final entry in dirEntries) {
      if (result.length >= _kMaxListEntries) break;
      if (_isDeniedRel(p.relative(entry.path, from: projectPath), denylist)) continue;
      result.add(entry);
      if (entry.entityType == 'directory') {
        await _walkDir(entry.path, projectPath, denylist, depth + 1, result);
      }
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
