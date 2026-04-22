import '../models/mcp_server_config.dart';

abstract interface class McpRepository {
  Stream<List<McpServerConfig>> watchAll();
  Future<List<McpServerConfig>> getAll();
  Future<List<McpServerConfig>> getEnabled();
  Future<void> upsert(McpServerConfig config);
  Future<void> delete(String id);
}
