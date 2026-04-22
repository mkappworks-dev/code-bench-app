import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/path_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../data/coding_tools/repository/coding_tools_repository.dart';
import '../../../data/coding_tools/repository/coding_tools_repository_impl.dart';

part 'read_file_tool.g.dart';

@riverpod
ReadFileTool readFileTool(Ref ref) => ReadFileTool(repo: ref.watch(codingToolsRepositoryProvider));

class ReadFileTool extends Tool {
  ReadFileTool({required this.repo});
  final CodingToolsRepository repo;

  static const int _kMaxReadBytes = 2 * 1024 * 1024; // 2 MB

  @override
  String get name => 'read_file';
  @override
  ToolCapability get capability => ToolCapability.readOnly;
  @override
  String get description => 'Read the contents of a text file inside the active project.';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'path': {'type': 'string', 'description': 'Project-relative or absolute path to a file inside the project.'},
    },
    'required': ['path'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    final p = ctx.safePath('path', verb: 'Read');
    if (p is PathErr) return p.result;
    final PathOk(:abs, :displayRaw) = p as PathOk;

    try {
      final size = await repo.fileSizeBytes(abs);
      if (size > _kMaxReadBytes) {
        dLog('[ReadFileTool] rejected oversized file: $abs ($size bytes)');
        return CodingToolResult.error(
          'File too large ($size bytes; max $_kMaxReadBytes bytes). '
          'Consider str_replace for targeted edits.',
        );
      }
      return CodingToolResult.success(await repo.readTextFile(abs));
    } on CodingToolsNotFoundException {
      return CodingToolResult.error('File "$displayRaw" does not exist.');
    } on CodingToolNotTextEncodedException {
      return CodingToolResult.error('File "$displayRaw" is not text-encoded.');
    } on CodingToolsDiskException catch (e) {
      dLog('[ReadFileTool] disk error: ${e.message}');
      return CodingToolResult.error('Cannot read "$displayRaw": ${e.message}.');
    }
  }
}
