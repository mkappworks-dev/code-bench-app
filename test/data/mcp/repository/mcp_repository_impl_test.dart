import 'package:code_bench_app/data/_core/app_database.dart';
import 'package:code_bench_app/data/mcp/datasource/mcp_config_datasource_drift.dart';
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:code_bench_app/data/mcp/repository/mcp_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late McpRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = McpRepositoryImpl(datasource: McpConfigDatasourceDrift(db));
  });
  tearDown(() => db.close());

  group('McpRepositoryImpl', () {
    test('upsert then getEnabled returns McpServerConfig', () async {
      const config = McpServerConfig(
        id: 'srv-1',
        name: 'github',
        transport: McpTransport.stdio,
        command: 'npx github-mcp',
        args: ['--port', '3000'],
        env: {'TOKEN': 'abc'},
        enabled: true,
      );
      await repo.upsert(config);
      final enabled = await repo.getEnabled();
      expect(enabled, hasLength(1));
      expect(enabled.first.id, 'srv-1');
      expect(enabled.first.transport, McpTransport.stdio);
      expect(enabled.first.command, 'npx github-mcp');
      expect(enabled.first.args, ['--port', '3000']);
      expect(enabled.first.env, {'TOKEN': 'abc'});
    });

    test('disabled config excluded from getEnabled', () async {
      const config = McpServerConfig(
        id: 'off',
        name: 'server',
        transport: McpTransport.httpSse,
        url: 'http://localhost:3000',
        enabled: false,
      );
      await repo.upsert(config);
      expect(await repo.getEnabled(), isEmpty);
      expect(await repo.getAll(), hasLength(1));
    });

    test('httpSse transport round-trips', () async {
      const config = McpServerConfig(
        id: 'sse-1',
        name: 'remote',
        transport: McpTransport.httpSse,
        url: 'https://api.example.com/mcp',
      );
      await repo.upsert(config);
      final all = await repo.getAll();
      expect(all.first.transport, McpTransport.httpSse);
      expect(all.first.url, 'https://api.example.com/mcp');
    });

    test('delete removes the config', () async {
      const config = McpServerConfig(id: 'del-me', name: 'temp', transport: McpTransport.stdio, command: 'cmd');
      await repo.upsert(config);
      await repo.delete('del-me');
      expect(await repo.getAll(), isEmpty);
    });
  });
}
