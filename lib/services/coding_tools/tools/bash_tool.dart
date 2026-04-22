import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/bash/datasource/bash_datasource_process.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';

part 'bash_tool.g.dart';

@riverpod
BashTool bashTool(Ref ref) => BashTool(datasource: BashDatasourceProcess());

class BashTool extends Tool {
  BashTool({required this.datasource});
  final BashDatasource datasource;

  @override
  String get name => 'bash';

  @override
  ToolCapability get capability => ToolCapability.shell;

  @override
  String get description =>
      'Execute a shell command in the project root. '
      'stdout and stderr are returned together with the exit code.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'command': {
        'type': 'string',
        'description':
            'The shell command to run. Executed via /bin/sh -c. '
            'Working directory is locked to the project root.',
      },
    },
    'required': ['command'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    final command = ctx.args['command'];
    if (command is! String || command.trim().isEmpty) {
      return CodingToolResult.error('bash requires a non-empty "command" argument.');
    }
    try {
      final result = await datasource.run(command: command, workingDirectory: ctx.projectPath);
      final header = result.timedOut ? 'Timed out after 120 s\n\n' : 'Exit ${result.exitCode}\n\n';
      return CodingToolResult.success('$header${result.output}');
    } on ProcessException catch (e) {
      dLog('[BashTool] ProcessException: $e');
      return CodingToolResult.error('bash failed to start: ${e.message}');
    }
  }
}
