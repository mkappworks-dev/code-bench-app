// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_tool_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_McpToolInfo _$McpToolInfoFromJson(Map<String, dynamic> json) => _McpToolInfo(
  name: json['name'] as String,
  description: json['description'] as String,
  inputSchema: json['inputSchema'] as Map<String, dynamic>,
);

Map<String, dynamic> _$McpToolInfoToJson(_McpToolInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'inputSchema': instance.inputSchema,
    };
