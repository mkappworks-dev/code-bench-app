import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_server_status.freezed.dart';

/// Runtime lifecycle state for a single MCP server.
@freezed
sealed class McpServerStatus with _$McpServerStatus {
  const factory McpServerStatus.stopped() = McpServerStopped;
  const factory McpServerStatus.starting() = McpServerStarting;
  const factory McpServerStatus.running() = McpServerRunning;
  const factory McpServerStatus.error(String message) = McpServerError;
  const factory McpServerStatus.pendingRemoval() = McpServerPendingRemoval;
}
