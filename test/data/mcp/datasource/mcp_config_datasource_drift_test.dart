import 'package:code_bench_app/data/_core/app_database.dart';
import 'package:code_bench_app/data/mcp/datasource/mcp_config_datasource_drift.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late McpConfigDatasourceDrift ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = McpConfigDatasourceDrift(db);
  });
  tearDown(() => db.close());

  group('McpConfigDatasourceDrift', () {
    test('upsert then getAll returns the row', () async {
      await ds.upsert(
        McpServersCompanion.insert(
          id: 'srv-1',
          name: 'github',
          transport: 'stdio',
          enabled: const Value(1),
          sortOrder: const Value(0),
        ),
      );
      final rows = await ds.getAll();
      expect(rows, hasLength(1));
      expect(rows.first.id, 'srv-1');
      expect(rows.first.name, 'github');
    });

    test('getEnabled filters disabled rows', () async {
      await ds.upsert(
        McpServersCompanion.insert(
          id: 'a',
          name: 'enabled',
          transport: 'stdio',
          enabled: const Value(1),
          sortOrder: const Value(0),
        ),
      );
      await ds.upsert(
        McpServersCompanion.insert(
          id: 'b',
          name: 'disabled',
          transport: 'stdio',
          enabled: const Value(0),
          sortOrder: const Value(1),
        ),
      );
      final enabled = await ds.getEnabled();
      expect(enabled, hasLength(1));
      expect(enabled.first.id, 'a');
    });

    test('upsert updates existing row by id', () async {
      await ds.upsert(
        McpServersCompanion.insert(
          id: 'srv-1',
          name: 'old',
          transport: 'stdio',
          enabled: const Value(1),
          sortOrder: const Value(0),
        ),
      );
      await ds.upsert(
        McpServersCompanion.insert(
          id: 'srv-1',
          name: 'new',
          transport: 'stdio',
          enabled: const Value(1),
          sortOrder: const Value(0),
        ),
      );
      final rows = await ds.getAll();
      expect(rows, hasLength(1));
      expect(rows.first.name, 'new');
    });

    test('deleteById removes the row', () async {
      await ds.upsert(
        McpServersCompanion.insert(
          id: 'del-me',
          name: 'temp',
          transport: 'stdio',
          enabled: const Value(1),
          sortOrder: const Value(0),
        ),
      );
      await ds.deleteById('del-me');
      expect(await ds.getAll(), isEmpty);
    });
  });
}
