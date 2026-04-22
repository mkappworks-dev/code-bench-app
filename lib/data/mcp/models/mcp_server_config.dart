import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_server_config.freezed.dart';
part 'mcp_server_config.g.dart';

enum McpTransport { stdio, httpSse }

@freezed
abstract class McpServerConfig with _$McpServerConfig {
  const factory McpServerConfig({
    required String id,
    required String name,
    required McpTransport transport,
    String? command,
    @Default([]) List<String> args,
    @Default({}) Map<String, String> env,
    String? url,
    @Default(true) bool enabled,
  }) = _McpServerConfig;

  factory McpServerConfig.fromJson(Map<String, dynamic> json) => _$McpServerConfigFromJson(json);
}
