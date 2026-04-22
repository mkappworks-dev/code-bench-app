import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/path_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../services/apply/apply_service.dart';

part 'write_file_tool.g.dart';

@riverpod
WriteFileTool writeFileTool(Ref ref) => WriteFileTool(applyService: ref.watch(applyServiceProvider));

class WriteFileTool extends Tool {
  WriteFileTool({required this.applyService});
  final ApplyService applyService;

  @override
  String get name => 'write_file';
  @override
  ToolCapability get capability => ToolCapability.mutatingFiles;
  @override
  String get description =>
      'Create or overwrite a file inside the active project. Prefer str_replace for targeted edits to existing files.';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
      'content': {'type': 'string'},
    },
    'required': ['path', 'content'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    final content = ctx.args['content'];
    if (content is! String) {
      return CodingToolResult.error('write_file requires a string "content"');
    }
    final p = ctx.safePath('path', verb: 'Write');
    if (p is PathErr) return p.result;
    final PathOk(:abs, :displayRaw) = p as PathOk;

    try {
      await applyService.applyChange(
        filePath: abs,
        projectPath: ctx.projectPath,
        newContent: content,
        sessionId: ctx.sessionId,
        messageId: ctx.messageId,
      );
      final bytes = utf8.encode(content).length;
      return CodingToolResult.success('Wrote $bytes bytes to $displayRaw.');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } on ApplyTooLargeException catch (e) {
      return CodingToolResult.error('File too large (${e.bytes} bytes).');
    } on ApplyDiskException catch (e) {
      dLog('[WriteFileTool] disk error: ${e.message}');
      return CodingToolResult.error('Cannot write "$displayRaw": ${e.message}.');
    }
  }
}
