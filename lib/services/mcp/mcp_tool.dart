import '../../core/utils/debug_logger.dart';
import '../../data/coding_tools/models/coding_tool_result.dart';
import '../../data/coding_tools/models/tool.dart';
import '../../data/coding_tools/models/tool_capability.dart';
import '../../data/coding_tools/models/tool_context.dart';
import '../../data/mcp/models/mcp_tool_info.dart';
import 'mcp_client_session.dart';

typedef McpExecutor = Future<String> Function(String toolName, Map<String, dynamic> args);

/// Bridges an MCP protocol tool into the app's [Tool] interface.
/// Wraps a tool execution function and normalizes errors to [CodingToolResult].
class McpTool implements Tool {
  McpTool({required String serverName, required McpToolInfo info, required McpExecutor execute})
    : _serverName = serverName,
      _info = info,
      _execute = execute;

  /// Creates an [McpTool] from an active [McpClientSession].
  factory McpTool.fromSession({required McpClientSession session, required McpToolInfo info}) => McpTool(
    serverName: session.config.name,
    info: info,
    execute: (toolName, args) => session.execute(toolName, args),
  );

  final String _serverName;
  final McpToolInfo _info;
  final McpExecutor _execute;

  @override
  String get name => '$_serverName/${_info.name}';

  @override
  String get description => _info.description;

  @override
  Map<String, dynamic> get inputSchema => _info.inputSchema;

  @override
  ToolCapability get capability => ToolCapability.shell;

  @override
  Map<String, dynamic> toOpenAiToolJson() => {
    'type': 'function',
    'function': {'name': name, 'description': description, 'parameters': inputSchema},
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    try {
      final result = await _execute(_info.name, ctx.args);
      return CodingToolResult.success(result);
    } on McpToolCallException catch (e) {
      dLog('[McpTool] tool error for $name: ${e.message}');
      return CodingToolResult.error(e.message);
    } catch (e, st) {
      dLog('[McpTool] unexpected error for $name: $e\n$st');
      return CodingToolResult.error('MCP tool call failed: $e');
    }
  }
}
