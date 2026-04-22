import 'package:code_bench_app/data/coding_tools/models/coding_tools_denylist_state.dart';
import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_capability.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_denylist_repository.dart';
import 'package:code_bench_app/data/mcp/datasource/mcp_transport_datasource.dart';
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:code_bench_app/data/mcp/repository/mcp_repository.dart';
import 'package:code_bench_app/services/coding_tools/tool_registry.dart';
import 'package:code_bench_app/services/mcp/mcp_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo extends Fake implements McpRepository {
  final List<McpServerConfig> enabled;
  _FakeRepo(this.enabled);

  @override
  Future<List<McpServerConfig>> getEnabled() async => enabled;

  @override
  Stream<List<McpServerConfig>> watchAll() => Stream.value([]);

  @override
  Future<List<McpServerConfig>> getAll() async => [];

  @override
  Future<void> upsert(McpServerConfig c) async {}

  @override
  Future<void> delete(String id) async {}
}

class _FakeTransport implements McpTransportDatasource {
  @override
  Future<void> connect(McpServerConfig c) async {}

  @override
  Future<Map<String, dynamic>> sendRequest(String m, [Map<String, dynamic>? p]) async {
    if (m == 'initialize') {
      return {
        'jsonrpc': '2.0',
        'id': 1,
        'result': {'protocolVersion': '2024-11-05', 'capabilities': {}, 'serverInfo': {}},
      };
    }
    if (m == 'tools/list') {
      return {
        'jsonrpc': '2.0',
        'id': 2,
        'result': {
          'tools': [
            {
              'name': 'search',
              'description': 'Search',
              'inputSchema': {'type': 'object'},
            },
          ],
        },
      };
    }
    return {'jsonrpc': '2.0', 'id': 3, 'result': {}};
  }

  @override
  void sendNotification(String m, [Map<String, dynamic>? p]) {}

  @override
  Future<void> close() async {}
}

/// Transport that succeeds on connect/initialize/tools-list but throws on close().
class _ThrowingCloseFakeTransport implements McpTransportDatasource {
  @override
  Future<void> connect(McpServerConfig c) async {}

  @override
  Future<Map<String, dynamic>> sendRequest(String m, [Map<String, dynamic>? p]) async {
    if (m == 'initialize') {
      return {
        'jsonrpc': '2.0',
        'id': 1,
        'result': {'protocolVersion': '2024-11-05', 'capabilities': {}, 'serverInfo': {}},
      };
    }
    if (m == 'tools/list') {
      return {
        'jsonrpc': '2.0',
        'id': 2,
        'result': {'tools': []},
      };
    }
    return {'jsonrpc': '2.0', 'id': 3, 'result': {}};
  }

  @override
  void sendNotification(String m, [Map<String, dynamic>? p]) {}

  @override
  Future<void> close() async => throw Exception('close failed');
}

class _EmptyDenylistRepo implements CodingToolsDenylistRepository {
  @override
  Future<CodingToolsDenylistState> load() async => CodingToolsDenylistState.empty();

  @override
  Future<CodingToolsDenylistState> save(CodingToolsDenylistState s) async => s;

  @override
  Future<Set<String>> effective(DenylistCategory c) async => {};

  @override
  Future<void> restoreAllDefaults() async {}
}

void main() {
  group('McpService.startSession()', () {
    test('registers one McpTool per discovered server tool', () async {
      final registry = ToolRegistry(builtIns: [], denylistRepo: _EmptyDenylistRepo());
      final statuses = <String, McpServerStatus>{};

      final svc = McpService(
        repository: _FakeRepo([
          const McpServerConfig(id: 'srv', name: 'test', transport: McpTransport.stdio, command: 'cmd'),
        ]),
        transportFactory: (_) => _FakeTransport(),
      );

      final teardown = await svc.startSession(
        registry: registry,
        sessionId: 'session-1',
        onStatusChanged: (id, status) => statuses[id] = status,
      );

      expect(registry.tools.where((t) => t.name == 'test/search'), hasLength(1));
      expect(registry.tools.firstWhere((t) => t.name == 'test/search').capability, ToolCapability.shell);

      await teardown();
      expect(registry.tools.where((t) => t.name.startsWith('test/')), isEmpty);
    });

    test('skips a server on startup error without failing the session', () async {
      final registry = ToolRegistry(builtIns: [], denylistRepo: _EmptyDenylistRepo());

      final svc = McpService(
        repository: _FakeRepo([
          const McpServerConfig(id: 'bad', name: 'broken', transport: McpTransport.stdio, command: 'bad-cmd'),
        ]),
        transportFactory: (_) => throw Exception('process not found'),
      );

      final teardown = await svc.startSession(registry: registry, sessionId: 's2');
      expect(registry.tools.where((t) => t.name.startsWith('broken/')), isEmpty);
      await teardown();
    });

    test('calls onStatusChanged(stopped) and onServerRemoved even when teardown throws', () async {
      final registry = ToolRegistry(builtIns: [], denylistRepo: _EmptyDenylistRepo());
      final statuses = <String, McpServerStatus>{};
      final removedIds = <String>[];

      final svc = McpService(
        repository: _FakeRepo([
          const McpServerConfig(id: 'srv2', name: 'flaky', transport: McpTransport.stdio, command: 'cmd'),
        ]),
        transportFactory: (_) => _ThrowingCloseFakeTransport(),
      );

      final teardown = await svc.startSession(
        registry: registry,
        sessionId: 'session-teardown-throws',
        onStatusChanged: (id, status) => statuses[id] = status,
        onServerRemoved: (id) => removedIds.add(id),
      );

      // Teardown should not throw to the caller.
      await teardown();

      expect(
        statuses['srv2'],
        isA<McpServerStopped>(),
        reason: 'onStatusChanged must be called with stopped even when teardown throws',
      );
      expect(removedIds, contains('srv2'), reason: 'onServerRemoved must be called even when teardown throws');
    });
  });
}
