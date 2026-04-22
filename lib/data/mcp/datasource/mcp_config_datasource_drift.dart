import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../_core/app_database.dart';

export '../../_core/app_database.dart' show McpServerRow, McpServersCompanion;

part 'mcp_config_datasource_drift.g.dart';

@Riverpod(keepAlive: true)
McpConfigDatasourceDrift mcpConfigDatasource(Ref ref) => McpConfigDatasourceDrift(ref.watch(appDatabaseProvider));

class McpConfigDatasourceDrift {
  McpConfigDatasourceDrift(this._db);
  final AppDatabase _db;

  Stream<List<McpServerRow>> watchAll() => _db.mcpDao.watchAll();
  Future<List<McpServerRow>> getAll() => _db.mcpDao.getAll();
  Future<List<McpServerRow>> getEnabled() => _db.mcpDao.getEnabled();
  Future<void> upsert(McpServersCompanion companion) => _db.mcpDao.upsert(companion);
  Future<void> deleteById(String id) => _db.mcpDao.deleteById(id);
}
