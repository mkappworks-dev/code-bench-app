import 'package:code_bench_app/data/mcp/datasource/mcp_transport_datasource.dart';
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:code_bench_app/services/mcp/mcp_client_session.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransport implements McpTransportDatasource {
  final notifications = <String>[];
  bool closed = false;

  final _responses = <String, Map<String, dynamic>>{
    'initialize': {
      'jsonrpc': '2.0',
      'id': 1,
      'result': {
        'protocolVersion': '2024-11-05',
        'serverInfo': {'name': 'test', 'version': '1.0'},
        'capabilities': {},
      },
    },
    'tools/list': {
      'jsonrpc': '2.0',
      'id': 2,
      'result': {
        'tools': [
          {
            'name': 'search',
            'description': 'Search the web',
            'inputSchema': {'type': 'object'},
          },
        ],
      },
    },
    'tools/call': {
      'jsonrpc': '2.0',
      'id': 3,
      'result': {
        'content': [
          {'type': 'text', 'text': 'Result text'},
        ],
        'isError': false,
      },
    },
  };

  @override
  Future<void> connect(McpServerConfig config) async {}

  @override
  Future<Map<String, dynamic>> sendRequest(String method, [Map<String, dynamic>? params]) async =>
      _responses[method] ?? {'jsonrpc': '2.0', 'id': 1, 'result': {}};

  @override
  void sendNotification(String method, [Map<String, dynamic>? params]) => notifications.add(method);

  @override
  Future<void> close() async => closed = true;
}

const _cfg = McpServerConfig(id: 'srv', name: 'test', transport: McpTransport.stdio, command: 'npx test-server');

void main() {
  group('McpClientSession.start()', () {
    test('discovers tools from tools/list', () async {
      final session = await McpClientSession.start(
        config: _cfg,
        datasource: _FakeTransport(),
        initTimeout: const Duration(seconds: 5),
      );
      expect(session.tools, hasLength(1));
      expect(session.tools.first.name, 'search');
    });

    test('sends notifications/initialized after initialize', () async {
      final transport = _FakeTransport();
      await McpClientSession.start(config: _cfg, datasource: transport, initTimeout: const Duration(seconds: 5));
      expect(transport.notifications, contains('notifications/initialized'));
    });
  });

  group('McpClientSession.execute()', () {
    test('returns text content from tools/call response', () async {
      final session = await McpClientSession.start(
        config: _cfg,
        datasource: _FakeTransport(),
        initTimeout: const Duration(seconds: 5),
      );
      final result = await session.execute('search', {'query': 'flutter'});
      expect(result, 'Result text');
    });

    test('throws McpToolCallException when isError is true', () async {
      final transport = _FakeTransport();
      transport._responses['tools/call'] = {
        'jsonrpc': '2.0',
        'id': 3,
        'result': {
          'content': [
            {'type': 'text', 'text': 'something broke'},
          ],
          'isError': true,
        },
      };
      final session = await McpClientSession.start(
        config: _cfg,
        datasource: transport,
        initTimeout: const Duration(seconds: 5),
      );
      expect(() => session.execute('search', {}), throwsA(isA<McpToolCallException>()));
    });
  });

  group('McpClientSession.teardown()', () {
    test('closes the transport', () async {
      final transport = _FakeTransport();
      final session = await McpClientSession.start(
        config: _cfg,
        datasource: transport,
        initTimeout: const Duration(seconds: 5),
      );
      await session.teardown();
      expect(transport.closed, isTrue);
    });
  });
}
