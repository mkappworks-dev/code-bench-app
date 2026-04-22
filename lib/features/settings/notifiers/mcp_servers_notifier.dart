import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/mcp/models/mcp_server_config.dart';
import '../../../data/mcp/repository/mcp_repository_impl.dart';

part 'mcp_servers_notifier.g.dart';

@riverpod
class McpServersNotifier extends _$McpServersNotifier {
  @override
  Stream<List<McpServerConfig>> build() => ref.watch(mcpRepositoryProvider).watchAll();
}
