import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:code_bench_app/data/mcp/repository/mcp_repository.dart';
import 'package:code_bench_app/data/mcp/repository/mcp_repository_impl.dart';
import 'package:code_bench_app/features/settings/notifiers/mcp_servers_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo extends Fake implements McpRepository {
  final List<McpServerConfig> _configs;
  _FakeRepo([List<McpServerConfig>? configs]) : _configs = configs ?? [];

  @override
  Stream<List<McpServerConfig>> watchAll() => Stream.value(List.of(_configs));

  @override
  Future<List<McpServerConfig>> getAll() async => List.of(_configs);

  @override
  Future<List<McpServerConfig>> getEnabled() async => _configs.where((c) => c.enabled).toList();

  @override
  Future<void> upsert(McpServerConfig c) async => _configs.add(c);

  @override
  Future<void> delete(String id) async => _configs.removeWhere((c) => c.id == id);
}

void main() {
  group('McpServersNotifier', () {
    test('emits empty list when repository is empty', () async {
      final c = ProviderContainer(overrides: [mcpRepositoryProvider.overrideWithValue(_FakeRepo())]);
      addTearDown(c.dispose);
      // Subscribe to keep the auto-dispose provider alive during the async build.
      final sub = c.listen<AsyncValue<List<McpServerConfig>>>(mcpServersProvider, (_, __) {});
      addTearDown(sub.close);
      final state = await c.read(mcpServersProvider.future);
      expect(state, isEmpty);
    });

    test('emits configs from repository', () async {
      final repo = _FakeRepo([
        const McpServerConfig(id: '1', name: 'github', transport: McpTransport.stdio, command: 'npx mcp'),
      ]);
      final c = ProviderContainer(overrides: [mcpRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(c.dispose);
      // Subscribe to keep the auto-dispose provider alive during the async build.
      final sub = c.listen<AsyncValue<List<McpServerConfig>>>(mcpServersProvider, (_, __) {});
      addTearDown(sub.close);
      final state = await c.read(mcpServersProvider.future);
      expect(state, hasLength(1));
      expect(state.first.name, 'github');
    });
  });
}
