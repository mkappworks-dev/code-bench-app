import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_server_status_notifier.freezed.dart';
part 'mcp_server_status_notifier.g.dart';

@freezed
sealed class McpServerStatus with _$McpServerStatus {
  const factory McpServerStatus.stopped() = McpServerStopped;
  const factory McpServerStatus.starting() = McpServerStarting;
  const factory McpServerStatus.running() = McpServerRunning;
  const factory McpServerStatus.error(String message) = McpServerError;
  const factory McpServerStatus.pendingRemoval() = McpServerPendingRemoval;
}

@riverpod
class McpServerStatusNotifier extends _$McpServerStatusNotifier {
  @override
  Map<String, McpServerStatus> build() => {};

  void setStatus(String serverId, McpServerStatus status) => state = {...state, serverId: status};

  void remove(String serverId) => state = Map.of(state)..remove(serverId);

  void clearAll() => state = {};
}
