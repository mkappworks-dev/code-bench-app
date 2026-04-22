import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_capability.dart';
import 'package:code_bench_app/data/mcp/models/mcp_tool_info.dart';
import 'package:code_bench_app/services/mcp/mcp_client_session.dart';
import 'package:code_bench_app/services/mcp/mcp_tool.dart';
import 'package:flutter_test/flutter_test.dart';

import '../coding_tools/_helpers/tool_test_helpers.dart';

const _info = McpToolInfo(name: 'search', description: 'Search the web', inputSchema: {'type': 'object'});

void main() {
  group('McpTool', () {
    test('name is "serverName/toolName"', () {
      final tool = McpTool(serverName: 'github', info: _info, execute: (_, __) async => 'ok');
      expect(tool.name, 'github/search');
    });

    test('capability is shell', () {
      final tool = McpTool(serverName: 'github', info: _info, execute: (_, __) async => 'ok');
      expect(tool.capability, ToolCapability.shell);
    });

    test('description delegates to info.description', () {
      final tool = McpTool(serverName: 'github', info: _info, execute: (_, __) async => 'ok');
      expect(tool.description, 'Search the web');
    });

    test('inputSchema delegates to info.inputSchema', () {
      final tool = McpTool(serverName: 'github', info: _info, execute: (_, __) async => 'ok');
      expect(tool.inputSchema, {'type': 'object'});
    });

    test('execute returns CodingToolResult.success with text', () async {
      final tool = McpTool(serverName: 'github', info: _info, execute: (name, args) async => 'found: ${args['query']}');
      final result = await tool.execute(fakeCtx(projectPath: '/tmp/proj', args: {'query': 'flutter'}));
      expect(result, isA<CodingToolResultSuccess>());
      expect((result as CodingToolResultSuccess).output, 'found: flutter');
    });

    test('execute returns CodingToolResult.error on McpToolCallException', () async {
      final tool = McpTool(
        serverName: 'github',
        info: _info,
        execute: (_, __) async => throw McpToolCallException('server error'),
      );
      final result = await tool.execute(fakeCtx(projectPath: '/tmp/proj'));
      expect(result, isA<CodingToolResultError>());
      expect((result as CodingToolResultError).message, contains('server error'));
    });

    test('execute returns CodingToolResult.error on unexpected exception', () async {
      final tool = McpTool(serverName: 'github', info: _info, execute: (_, __) async => throw StateError('unexpected'));
      final result = await tool.execute(fakeCtx(projectPath: '/tmp/proj'));
      expect(result, isA<CodingToolResultError>());
      expect((result as CodingToolResultError).message, contains('MCP tool call failed'));
    });

    test('toOpenAiToolJson() returns valid OpenAI schema', () {
      final tool = McpTool(serverName: 'github', info: _info, execute: (_, __) async => 'ok');
      final json = tool.toOpenAiToolJson();
      expect(json['type'], 'function');
      expect(json['function']['name'], 'github/search');
      expect(json['function']['description'], 'Search the web');
      expect(json['function']['parameters'], {'type': 'object'});
    });
  });
}
