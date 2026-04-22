import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/mcp/models/mcp_server_config.dart';
import '../../../data/mcp/repository/mcp_repository_impl.dart';
import 'mcp_server_status_notifier.dart';
import 'mcp_servers_failure.dart';

part 'mcp_servers_actions.g.dart';

@Riverpod(keepAlive: true)
class McpServersActions extends _$McpServersActions {
  @override
  FutureOr<void> build() {}

  Future<void> save(McpServerConfig config) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(mcpRepositoryProvider).upsert(config);
      } catch (e, st) {
        dLog('[McpServersActions] save failed: $e');
        Error.throwWithStackTrace(McpServersFailure.saveError(e.toString()), st);
      }
    });
  }

  Future<void> remove(String id) async {
    ref.read(mcpServerStatusProvider.notifier).setStatus(id, const McpServerStatus.pendingRemoval());
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(mcpRepositoryProvider).delete(id);
        ref.read(mcpServerStatusProvider.notifier).remove(id);
      } catch (e, st) {
        dLog('[McpServersActions] remove failed: $e');
        Error.throwWithStackTrace(McpServersFailure.removeError(e.toString()), st);
      }
    });
  }
}
