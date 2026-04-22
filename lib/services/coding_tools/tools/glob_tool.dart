import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../data/coding_tools/repository/coding_tools_repository.dart';
import '../../../data/coding_tools/repository/coding_tools_repository_impl.dart';

part 'glob_tool.g.dart';

@riverpod
GlobTool globTool(Ref ref) => GlobTool(repo: ref.watch(codingToolsRepositoryProvider));

class GlobTool extends Tool {
  GlobTool({required this.repo});
  final CodingToolsRepository repo;

  static const int _kMaxPaths = 500;

  @override
  String get name => 'glob';

  @override
  ToolCapability get capability => ToolCapability.readOnly;

  @override
  String get description =>
      'Expand a glob pattern to matching file paths inside the active project. '
      'Returns one project-relative path per line. Caps at 500 paths.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'pattern': {'type': 'string', 'description': 'Glob pattern, e.g. lib/**/*.dart or test/**/*_test.dart'},
    },
    'required': ['pattern'],
  };

  /// Builds a list of [Glob] instances to use for matching.
  ///
  /// The `glob` package treats `/**/` as one-or-more directory levels, but the
  /// conventional expectation is zero-or-more. To bridge the gap, when the
  /// pattern contains `/**/` we also add a variant with `/**/` replaced by `/`
  /// so that e.g. `lib/**/*.dart` matches both `lib/a.dart` (zero extra dirs)
  /// and `lib/sub/a.dart` (one extra dir).
  List<Glob> _buildGlobs(String pattern) {
    final globs = <Glob>[Glob(pattern)];
    if (pattern.contains('/**/')) {
      globs.add(Glob(pattern.replaceAll('/**/', '/')));
    }
    return globs;
  }

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    final pattern = ctx.args['pattern'];
    if (pattern is! String || pattern.isEmpty) {
      return CodingToolResult.error('glob requires a non-empty "pattern"');
    }
    if (pattern.contains('..')) {
      return CodingToolResult.error('Pattern must not contain ".."; use a path relative to the project root.');
    }

    try {
      final globs = _buildGlobs(pattern);
      // Walk the project directory recursively and filter with glob.matches()
      // so that `**` is treated as zero-or-more path segments (standard expectation).
      final root = Directory(ctx.projectPath);
      final paths = <String>[];
      await for (final entity in root.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final rel = p.relative(entity.path, from: ctx.projectPath);
        if (globs.any((g) => g.matches(rel))) paths.add(rel);
      }
      paths.sort();

      if (paths.isEmpty) return CodingToolResult.success('No paths matched.');

      final buf = StringBuffer();
      final capped = paths.length > _kMaxPaths;
      for (final path in paths.take(_kMaxPaths)) {
        buf.writeln(path);
      }
      buf.writeln();
      if (capped) {
        buf.write(
          '$_kMaxPaths paths shown (pattern matched more). '
          'Refine the pattern to narrow results.',
        );
      } else {
        final n = paths.length;
        buf.write('$n ${n == 1 ? 'path' : 'paths'} matched.');
      }
      return CodingToolResult.success(buf.toString());
    } catch (e, st) {
      dLog('[GlobTool] error: $e\n$st');
      return CodingToolResult.error('Glob error: $e');
    }
  }
}
