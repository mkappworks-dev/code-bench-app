import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:code_bench_app/data/mcp/repository/mcp_repository.dart';
import 'package:code_bench_app/data/mcp/repository/mcp_repository_impl.dart';
import 'package:code_bench_app/features/settings/notifiers/mcp_servers_actions.dart';
import 'package:code_bench_app/features/settings/notifiers/mcp_servers_failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo extends Fake implements McpRepository {
  final List<McpServerConfig> _configs = [];
  bool throwOnSave = false;
  bool throwOnDelete = false;

  @override
  Stream<List<McpServerConfig>> watchAll() => Stream.value(List.of(_configs));

  @override
  Future<List<McpServerConfig>> getAll() async => List.of(_configs);

  @override
  Future<List<McpServerConfig>> getEnabled() async => _configs.where((c) => c.enabled).toList();

  @override
  Future<void> upsert(McpServerConfig config) async {
    if (throwOnSave) throw Exception('DB error');
    _configs.removeWhere((c) => c.id == config.id);
    _configs.add(config);
  }

  @override
  Future<void> delete(String id) async {
    if (throwOnDelete) throw Exception('DB error');
    _configs.removeWhere((c) => c.id == id);
  }
}

const _cfg = McpServerConfig(id: 'x', name: 'server', transport: McpTransport.stdio, command: 'cmd');

void main() {
  group('McpServersActions.save()', () {
    test('calls upsert and transitions to AsyncData', () async {
      final repo = _FakeRepo();
      final c = ProviderContainer(overrides: [mcpRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(c.dispose);
      await c.read(mcpServersActionsProvider.notifier).save(_cfg);
      expect(c.read(mcpServersActionsProvider).hasValue, isTrue);
      expect(repo._configs, hasLength(1));
    });

    test('transitions to AsyncError with McpServersSaveError on failure', () async {
      final repo = _FakeRepo()..throwOnSave = true;
      final c = ProviderContainer(overrides: [mcpRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(c.dispose);
      await c.read(mcpServersActionsProvider.notifier).save(_cfg);
      expect(c.read(mcpServersActionsProvider).hasError, isTrue);
      expect(c.read(mcpServersActionsProvider).error, isA<McpServersSaveError>());
    });
  });

  group('McpServersActions.remove()', () {
    test('calls delete and transitions to AsyncData', () async {
      final repo = _FakeRepo().._configs.add(_cfg);
      final c = ProviderContainer(overrides: [mcpRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(c.dispose);
      await c.read(mcpServersActionsProvider.notifier).remove('x');
      expect(c.read(mcpServersActionsProvider).hasValue, isTrue);
      expect(repo._configs, isEmpty);
    });

    test('transitions to AsyncError with McpServersRemoveError on failure', () async {
      final repo = _FakeRepo()
        .._configs.add(_cfg)
        ..throwOnDelete = true;
      final c = ProviderContainer(overrides: [mcpRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(c.dispose);
      await c.read(mcpServersActionsProvider.notifier).remove('x');
      expect(c.read(mcpServersActionsProvider).error, isA<McpServersRemoveError>());
    });
  });
}
