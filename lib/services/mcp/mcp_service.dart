import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/mcp/datasource/mcp_http_sse_datasource_dio.dart';
import '../../data/mcp/datasource/mcp_stdio_datasource_process.dart';
import '../../data/mcp/datasource/mcp_transport_datasource.dart';
import '../../data/mcp/models/mcp_server_config.dart';
import '../../data/mcp/repository/mcp_repository.dart';
import '../../data/mcp/repository/mcp_repository_impl.dart';
import '../../features/settings/notifiers/mcp_server_status_notifier.dart';
import '../../services/coding_tools/tool_registry.dart';
import 'mcp_client_session.dart';
import 'mcp_tool.dart';

part 'mcp_service.g.dart';

@riverpod
McpService mcpService(Ref ref) => McpService(
  repository: ref.watch(mcpRepositoryProvider),
  statusNotifier: ref.watch(mcpServerStatusProvider.notifier),
);

class McpService {
  McpService({
    required McpRepository repository,
    required McpServerStatusNotifier statusNotifier,
    McpTransportDatasource Function(McpServerConfig)? transportFactory,
  }) : _repository = repository,
       _statusNotifier = statusNotifier,
       _transportFactory = transportFactory ?? _defaultTransport;

  final McpRepository _repository;
  final McpServerStatusNotifier _statusNotifier;
  final McpTransportDatasource Function(McpServerConfig) _transportFactory;

  static McpTransportDatasource _defaultTransport(McpServerConfig config) => switch (config.transport) {
    McpTransport.stdio => McpStdioDatasourceProcess(),
    McpTransport.httpSse => McpHttpSseDatasourceDio(),
  };

  Future<Future<void> Function()> startSession({required ToolRegistry registry, required String sessionId}) async {
    final configs = await _repository.getEnabled();
    final sessions = <McpClientSession>[];
    final registeredNames = <String>[];

    for (final config in configs) {
      _statusNotifier.setStatus(config.id, const McpServerStatus.starting());
      try {
        final transport = _transportFactory(config);
        final session = await McpClientSession.start(
          config: config,
          datasource: transport,
          initTimeout: const Duration(seconds: 30),
        );
        sessions.add(session);

        for (final toolInfo in session.tools) {
          final tool = McpTool.fromSession(session: session, info: toolInfo);
          registry.register(tool);
          registeredNames.add(tool.name);
        }

        _statusNotifier.setStatus(config.id, const McpServerStatus.running());
      } catch (e, st) {
        dLog('[McpService] failed to start "${config.name}": $e\n$st');
        sLog('[McpService] server startup error for "${config.name}": ${e.runtimeType}');
        _statusNotifier.setStatus(config.id, McpServerStatus.error(e.toString()));
      }
    }

    return () async {
      for (final name in registeredNames) {
        registry.unregister(name);
      }
      for (final session in sessions) {
        try {
          await session.teardown();
          _statusNotifier.setStatus(session.config.id, const McpServerStatus.stopped());
        } catch (e) {
          dLog('[McpService] teardown error for "${session.config.name}": $e');
        }
      }
    };
  }
}
