import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/mcp/models/mcp_server_config.dart';
import '../../../services/mcp/mcp_service.dart';

part 'mcp_servers_notifier.g.dart';

@riverpod
class McpServersNotifier extends _$McpServersNotifier {
  @override
  Stream<List<McpServerConfig>> build() => ref.watch(mcpServiceProvider).watchAll();
}
