import '../../data/mcp/datasource/mcp_transport_datasource.dart';
import '../../data/mcp/models/mcp_server_config.dart';
import '../../data/mcp/models/mcp_tool_info.dart';

class McpClientSession {
  McpClientSession._({required this.config, required this.tools, required McpTransportDatasource datasource})
    : _datasource = datasource;

  final McpServerConfig config;
  final List<McpToolInfo> tools;
  final McpTransportDatasource _datasource;

  static Future<McpClientSession> start({
    required McpServerConfig config,
    required McpTransportDatasource datasource,
    Duration initTimeout = const Duration(seconds: 30),
  }) async {
    await datasource.connect(config);

    await datasource
        .sendRequest('initialize', {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {'name': 'code-bench', 'version': '1.0'},
        })
        .timeout(initTimeout);

    datasource.sendNotification('notifications/initialized');

    final toolsResponse = await datasource.sendRequest('tools/list').timeout(initTimeout);

    final rawTools = (toolsResponse['result']?['tools'] as List<dynamic>?) ?? [];
    final tools = rawTools
        .whereType<Map<String, dynamic>>()
        .map(
          (t) => McpToolInfo(
            name: t['name'] as String,
            description: (t['description'] as String?) ?? '',
            inputSchema: (t['inputSchema'] as Map<String, dynamic>?) ?? const {},
          ),
        )
        .toList();

    return McpClientSession._(config: config, tools: tools, datasource: datasource);
  }

  Future<String> execute(
    String toolName,
    Map<String, dynamic> args, {
    Duration timeout = const Duration(seconds: 120),
  }) async {
    final response = await _datasource
        .sendRequest('tools/call', {'name': toolName, 'arguments': args})
        .timeout(timeout);

    final result = response['result'] as Map<String, dynamic>?;
    final isError = result?['isError'] as bool? ?? false;
    final content = (result?['content'] as List<dynamic>?) ?? [];

    final text = content
        .whereType<Map<String, dynamic>>()
        .where((c) => c['type'] == 'text')
        .map((c) => (c['text'] as String?) ?? '')
        .join('\n');

    if (isError) throw McpToolCallException(text);
    return text;
  }

  Future<void> teardown() => _datasource.close();
}

class McpToolCallException implements Exception {
  McpToolCallException(this.message);
  final String message;
  @override
  String toString() => 'McpToolCallException: $message';
}
