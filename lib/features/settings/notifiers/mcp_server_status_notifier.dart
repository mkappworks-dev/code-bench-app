import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/mcp/models/mcp_server_status.dart';

export '../../../data/mcp/models/mcp_server_status.dart';

part 'mcp_server_status_notifier.g.dart';

@riverpod
class McpServerStatusNotifier extends _$McpServerStatusNotifier {
  @override
  Map<String, McpServerStatus> build() => {};

  void setStatus(String serverId, McpServerStatus status) => state = {...state, serverId: status};

  void remove(String serverId) => state = Map.of(state)..remove(serverId);

  void clearAll() => state = {};
}
