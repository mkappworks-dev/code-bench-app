// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_server_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_McpServerConfig _$McpServerConfigFromJson(Map<String, dynamic> json) =>
    _McpServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      transport: $enumDecode(_$McpTransportEnumMap, json['transport']),
      command: json['command'] as String?,
      args:
          (json['args'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      env:
          (json['env'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      url: json['url'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$McpServerConfigToJson(_McpServerConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'transport': _$McpTransportEnumMap[instance.transport]!,
      'command': instance.command,
      'args': instance.args,
      'env': instance.env,
      'url': instance.url,
      'enabled': instance.enabled,
    };

const _$McpTransportEnumMap = {
  McpTransport.stdio: 'stdio',
  McpTransport.httpSse: 'httpSse',
};
