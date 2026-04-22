import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/mcp/models/mcp_server_config.dart';
import '../../../services/mcp/mcp_service.dart';
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
        await ref.read(mcpServiceProvider).save(config);
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
        await ref.read(mcpServiceProvider).delete(id);
        ref.read(mcpServerStatusProvider.notifier).remove(id);
      } catch (e, st) {
        dLog('[McpServersActions] remove failed: $e');
        // Restore status so the card doesn't stay in pendingRemoval state.
        ref.read(mcpServerStatusProvider.notifier).setStatus(id, const McpServerStatus.stopped());
        Error.throwWithStackTrace(McpServersFailure.removeError(e.toString()), st);
      }
    });
  }
}
