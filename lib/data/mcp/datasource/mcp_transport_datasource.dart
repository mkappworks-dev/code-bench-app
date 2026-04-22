import '../models/mcp_server_config.dart';

abstract class McpTransportDatasource {
  /// Opens the transport connection (spawns process or opens SSE stream).
  /// No MCP-level handshaking — that happens in McpClientSession.
  Future<void> connect(McpServerConfig config);

  /// Sends a JSON-RPC 2.0 request and returns the response matched by `id`.
  Future<Map<String, dynamic>> sendRequest(String method, [Map<String, dynamic>? params]);

  /// Sends a JSON-RPC notification (no `id` field, no response expected).
  void sendNotification(String method, [Map<String, dynamic>? params]);

  /// Closes the connection and cancels all pending requests.
  Future<void> close();
}
