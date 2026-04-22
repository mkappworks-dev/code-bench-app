import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/path_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../data/coding_tools/repository/coding_tools_repository.dart';
import '../../../data/coding_tools/repository/coding_tools_repository_impl.dart';
import '../../../services/apply/apply_service.dart';

part 'str_replace_tool.g.dart';

@riverpod
StrReplaceTool strReplaceTool(Ref ref) =>
    StrReplaceTool(repo: ref.watch(codingToolsRepositoryProvider), applyService: ref.watch(applyServiceProvider));

class StrReplaceTool extends Tool {
  StrReplaceTool({required this.repo, required this.applyService});
  final CodingToolsRepository repo;
  final ApplyService applyService;

  @override
  String get name => 'str_replace';
  @override
  ToolCapability get capability => ToolCapability.mutatingFiles;
  @override
  String get description =>
      'Replace the first exact occurrence of old_str with new_str in a file. '
      'The match must be unique — if zero or multiple matches exist, this tool '
      'returns an error and the file is unchanged.';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
      'old_str': {'type': 'string'},
      'new_str': {'type': 'string'},
    },
    'required': ['path', 'old_str', 'new_str'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    final oldStr = ctx.args['old_str'];
    final newStr = ctx.args['new_str'];
    if (oldStr is! String || oldStr.isEmpty) {
      return CodingToolResult.error('str_replace requires "old_str"');
    }
    if (newStr is! String) {
      return CodingToolResult.error('str_replace requires "new_str"');
    }
    final pr = ctx.safePath('path', verb: 'Edit');
    if (pr is PathErr) return pr.result;
    final PathOk(:abs, :displayRaw) = pr as PathOk;

    try {
      final original = await repo.readTextFile(abs);
      final checksum = applyService.checksumOf(original);
      final matchCount = _countOccurrences(original, oldStr);
      if (matchCount == 0) {
        return CodingToolResult.error(
          'old_str not found in $displayRaw. The match must be exact, including whitespace.',
        );
      }
      if (matchCount > 1) {
        return CodingToolResult.error(
          'old_str matches $matchCount times in $displayRaw. Include more surrounding context to make it unique.',
        );
      }
      final updated = original.replaceFirst(oldStr, newStr);
      await applyService.applyChange(
        filePath: abs,
        projectPath: ctx.projectPath,
        newContent: updated,
        sessionId: ctx.sessionId,
        messageId: ctx.messageId,
        expectedChecksum: checksum,
      );
      return CodingToolResult.success('Replaced 1 match in $displayRaw.');
    } on CodingToolsNotFoundException {
      return CodingToolResult.error('File "$displayRaw" does not exist.');
    } on CodingToolNotTextEncodedException {
      return CodingToolResult.error('File "$displayRaw" is not text-encoded.');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } on ApplyContentChangedException {
      return CodingToolResult.error('File "$displayRaw" was modified externally. Please retry str_replace.');
    } on ApplyTooLargeException catch (e) {
      return CodingToolResult.error('File too large (${e.bytes} bytes).');
    } on CodingToolsDiskException catch (e) {
      dLog('[StrReplaceTool] disk error reading: ${e.message}');
      return CodingToolResult.error('Cannot edit "$displayRaw": ${e.message}.');
    } on ApplyDiskException catch (e) {
      dLog('[StrReplaceTool] disk error writing: ${e.message}');
      return CodingToolResult.error('Cannot edit "$displayRaw": ${e.message}.');
    }
  }
}

int _countOccurrences(String haystack, String needle) {
  if (needle.isEmpty) return 0;
  var count = 0;
  var idx = 0;
  while ((idx = haystack.indexOf(needle, idx)) != -1) {
    count++;
    idx += needle.length;
  }
  return count;
}
