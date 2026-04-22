import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/datasource/grep_datasource.dart';
import '../../../data/coding_tools/datasource/grep_datasource_io.dart';
import '../../../data/coding_tools/datasource/grep_datasource_process.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/effective_denylist.dart';
import '../../../data/coding_tools/models/grep_match.dart';
import '../../../data/coding_tools/models/path_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../data/coding_tools/coding_tools_exceptions.dart';
import '../ripgrep_availability_service.dart';

export '../../../data/coding_tools/datasource/grep_datasource.dart';

part 'grep_tool.g.dart';

@riverpod
GrepTool grepTool(Ref ref) {
  final availability = ref.watch(ripgrepAvailabilityProvider);
  if (availability is AsyncError) {
    dLog('[GrepTool] ripgrep availability check failed: ${availability.error}');
  }
  final isAvailable = availability.value ?? false;
  return GrepTool(datasource: isAvailable ? GrepDatasourceProcess() : GrepDatasourceIo());
}

class GrepTool extends Tool {
  GrepTool({required this.datasource});
  final GrepDatasource datasource;

  static const int _kMaxMatches = 100;
  static final _validExtensionRe = RegExp(r'^[A-Za-z0-9_]+$');

  @override
  String get name => 'grep';

  @override
  ToolCapability get capability => ToolCapability.readOnly;

  @override
  String get description =>
      'Search file contents by regex pattern inside the active project. '
      'Returns matching lines with 2 lines of context. Caps at 100 matches.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'pattern': {'type': 'string', 'description': 'Regex pattern to search for.'},
      'path': {
        'type': 'string',
        'description':
            'Project-relative or absolute path to search within. '
            'Use "." for the project root.',
      },
      'extensions': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'File extensions to include, e.g. ["dart", "yaml"]. Omit for all files.',
      },
    },
    'required': ['pattern', 'path'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    final rawPath = ctx.args['path'];
    if (rawPath is! String || rawPath.isEmpty) {
      return CodingToolResult.error('grep requires a non-empty "path"');
    }
    final normalAbs = p.normalize(
      p.absolute(p.isAbsolute(rawPath) ? rawPath : p.join(ctx.projectPath, rawPath)),
    );
    final normalRoot = p.normalize(p.absolute(ctx.projectPath));

    // If the resolved path is the project root itself, trust it directly
    // (assertWithinProject requires the path to be strictly *inside* the root).
    // For all subdirectory paths, run the full boundary + denylist check.
    String searchPath;
    if (normalAbs != normalRoot) {
      final pr = ctx.safePath('path', verb: 'Search', noun: 'directory');
      if (pr is PathErr) return pr.result;
      searchPath = (pr as PathOk).abs;
    } else {
      searchPath = ctx.projectPath;
    }

    final patternRaw = ctx.args['pattern'];
    if (patternRaw is! String || patternRaw.isEmpty) {
      return CodingToolResult.error('grep requires a non-empty "pattern"');
    }
    try {
      RegExp(patternRaw);
    } on FormatException catch (e) {
      return CodingToolResult.error('Invalid regex pattern: ${e.message}');
    }

    final extensionsRaw = ctx.args['extensions'];
    final extensions = extensionsRaw is List
        ? extensionsRaw.whereType<String>().where(_validExtensionRe.hasMatch).toList()
        : const <String>[];

    try {
      final result = await datasource.grep(
        pattern: patternRaw,
        rootPath: searchPath,
        maxMatches: _kMaxMatches,
        fileExtensions: extensions,
      );
      final filteredMatches = result.matches
          .where((m) => !_isDeniedRel(m.file, ctx.denylist))
          .toList();
      return CodingToolResult.success(
        _formatResult(GrepResult(
          matches: filteredMatches,
          totalFound: filteredMatches.length,
          wasCapped: result.wasCapped,
        )),
      );
    } on CodingToolsNotFoundException {
      return CodingToolResult.error('Path does not exist.');
    } on CodingToolsDiskException catch (e) {
      dLog('[GrepTool] disk error: $e');
      return CodingToolResult.error('Cannot search: ${e.message}');
    }
  }

  static bool _isDeniedRel(String relPath, EffectiveDenylist denylist) {
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

  static String _formatResult(GrepResult result) {
    if (result.matches.isEmpty) return 'No matches found.';

    final buf = StringBuffer();
    for (var i = 0; i < result.matches.length; i++) {
      final m = result.matches[i];
      for (var j = 0; j < m.contextBefore.length; j++) {
        final lineNo = m.lineNumber - m.contextBefore.length + j;
        buf.writeln('${m.file}:$lineNo-${m.contextBefore[j]}');
      }
      buf.writeln('${m.file}:${m.lineNumber}:${m.lineContent}');
      for (var j = 0; j < m.contextAfter.length; j++) {
        final lineNo = m.lineNumber + 1 + j;
        buf.writeln('${m.file}:$lineNo-${m.contextAfter[j]}');
      }
      if (i < result.matches.length - 1) buf.writeln('--');
    }
    buf.writeln();
    if (result.wasCapped) {
      buf.write(
        'Found 100+ matches (showing first $_kMaxMatches). '
        'Narrow your search with a more specific pattern or path.',
      );
    } else {
      final n = result.matches.length;
      buf.write('Found $n ${n == 1 ? 'match' : 'matches'}.');
    }
    return buf.toString();
  }
}
