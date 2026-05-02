import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../datasource/mcp_config_datasource_drift.dart';
import '../models/mcp_server_config.dart';
import 'mcp_repository.dart';

part 'mcp_repository_impl.g.dart';

@Riverpod(keepAlive: true)
McpRepository mcpRepository(Ref ref) => McpRepositoryImpl(datasource: ref.watch(mcpConfigDatasourceProvider));

class McpRepositoryImpl implements McpRepository {
  McpRepositoryImpl({required McpConfigDatasourceDrift datasource}) : _ds = datasource;
  final McpConfigDatasourceDrift _ds;

  @override
  Stream<List<McpServerConfig>> watchAll() => _ds.watchAll().map((rows) => rows.map(_toDomain).toList());

  @override
  Future<List<McpServerConfig>> getAll() async => (await _ds.getAll()).map(_toDomain).toList();

  @override
  Future<List<McpServerConfig>> getEnabled() async => (await _ds.getEnabled()).map(_toDomain).toList();

  @override
  Future<void> upsert(McpServerConfig config) => _ds.upsertConfig(config);

  @override
  Future<void> delete(String id) => _ds.deleteById(id);

  @override
  Future<void> deleteAllServers() => _ds.deleteAllServers();

  McpServerConfig _toDomain(McpServerRow row) {
    List<String> args = const [];
    Map<String, String> env = const {};
    try {
      args = (jsonDecode(row.args) as List<dynamic>).cast<String>();
    } catch (e) {
      dLog('[McpRepository] args parse error for ${row.id}: $e');
    }
    try {
      env = (jsonDecode(row.env) as Map<String, dynamic>).cast<String, String>();
    } catch (e) {
      dLog('[McpRepository] env parse error for ${row.id}: $e');
    }
    return McpServerConfig(
      id: row.id,
      name: row.name,
      transport: McpTransport.values.firstWhere((t) => t.name == row.transport, orElse: () => McpTransport.stdio),
      command: row.command,
      args: args,
      env: env,
      url: row.url,
      enabled: row.enabled == 1,
    );
  }
}
