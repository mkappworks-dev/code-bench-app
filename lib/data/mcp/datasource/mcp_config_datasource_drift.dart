import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../_core/app_database.dart';
import '../models/mcp_server_config.dart';

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
  Future<void> deleteAllServers() => _db.mcpDao.deleteAll();

  /// Convenience method: builds the companion from a domain [McpServerConfig]
  /// and persists it. Keeps all Drift [Value] usage inside this datasource.
  Future<void> upsertConfig(McpServerConfig config) => upsert(
    McpServersCompanion(
      id: Value(config.id),
      name: Value(config.name),
      transport: Value(config.transport.name),
      command: Value(config.command),
      args: Value(jsonEncode(config.args)),
      env: Value(jsonEncode(config.env)),
      url: Value(config.url),
      enabled: Value(config.enabled ? 1 : 0),
    ),
  );
}
