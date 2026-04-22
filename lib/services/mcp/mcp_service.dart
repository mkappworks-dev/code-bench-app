import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/mcp/datasource/mcp_http_sse_datasource_dio.dart';
import '../../data/mcp/datasource/mcp_stdio_datasource_process.dart';
import '../../data/mcp/datasource/mcp_transport_datasource.dart';
import '../../data/mcp/models/mcp_server_config.dart';
import '../../data/mcp/models/mcp_server_status.dart';
import '../../data/mcp/repository/mcp_repository.dart';
import '../../data/mcp/repository/mcp_repository_impl.dart';
import '../../services/coding_tools/tool_registry.dart';
import 'mcp_client_session.dart';
import 'mcp_tool.dart';

export '../../data/mcp/models/mcp_server_status.dart';

part 'mcp_service.g.dart';

/// Callback signature used to report server lifecycle status changes.
typedef McpStatusCallback = void Function(String serverId, McpServerStatus status);

/// Callback signature used to report server removal after teardown.
typedef McpRemoveCallback = void Function(String serverId);

@riverpod
McpService mcpService(Ref ref) {
  return McpService(repository: ref.watch(mcpRepositoryProvider));
}

class McpService {
  McpService({required McpRepository repository, McpTransportDatasource Function(McpServerConfig)? transportFactory})
    : _repository = repository,
      _transportFactory = transportFactory ?? _defaultTransport;

  final McpRepository _repository;
  final McpTransportDatasource Function(McpServerConfig) _transportFactory;

  static void _noopStatus(String id, McpServerStatus status) {}

  static void _noopRemove(String id) {}

  static McpTransportDatasource _defaultTransport(McpServerConfig config) => switch (config.transport) {
    McpTransport.stdio => McpStdioDatasourceProcess(),
    McpTransport.httpSse => McpHttpSseDatasourceDio(),
  };

  // ── CRUD delegation ──────────────────────────────────────────────────────

  /// Returns a stream of all configured MCP servers.
  Stream<List<McpServerConfig>> watchAll() => _repository.watchAll();

  /// Persists (insert-or-update) an MCP server configuration.
  Future<void> save(McpServerConfig config) => _repository.upsert(config);

  /// Deletes an MCP server configuration by [id].
  Future<void> delete(String id) => _repository.delete(id);

  // ── Session lifecycle ─────────────────────────────────────────────────────

  Future<Future<void> Function()> startSession({
    required ToolRegistry registry,
    required String sessionId,
    McpStatusCallback? onStatusChanged,
    McpRemoveCallback? onServerRemoved,
  }) async {
    final statusCb = onStatusChanged ?? _noopStatus;
    final removeCb = onServerRemoved ?? _noopRemove;

    final configs = await _repository.getEnabled();
    final sessions = <McpClientSession>[];
    final registeredNames = <String>[];

    for (final config in configs) {
      statusCb(config.id, const McpServerStatus.starting());
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

        statusCb(config.id, const McpServerStatus.running());
      } catch (e, st) {
        dLog('[McpService] failed to start "${config.name}": $e\n$st');
        sLog('[McpService] server startup error for "${config.name}": ${e.runtimeType}');
        statusCb(config.id, McpServerStatus.error(e.toString()));
      }
    }

    return () async {
      for (final name in registeredNames) {
        registry.unregister(name);
      }
      for (final session in sessions) {
        try {
          await session.teardown();
        } catch (e) {
          dLog('[McpService] teardown error for "${session.config.name}": $e');
        } finally {
          statusCb(session.config.id, const McpServerStatus.stopped());
          removeCb(session.config.id);
        }
      }
    };
  }
}
