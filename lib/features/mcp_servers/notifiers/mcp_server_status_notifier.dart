import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/mcp/models/mcp_server_status.dart';

export '../../../data/mcp/models/mcp_server_status.dart';

part 'mcp_server_status_notifier.g.dart';

/// `keepAlive` so a captured instance survives the chat tab unmount while `ChatStreamService` is still emitting updates.
@Riverpod(keepAlive: true)
class McpServerStatusNotifier extends _$McpServerStatusNotifier {
  @override
  Map<String, McpServerStatus> build() => {};

  void setStatus(String serverId, McpServerStatus status) => state = {...state, serverId: status};

  void remove(String serverId) => state = Map.of(state)..remove(serverId);

  void clearAll() => state = {};
}
