// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ToolEvent _$ToolEventFromJson(Map<String, dynamic> json) => _ToolEvent(
  id: json['id'] as String,
  type: json['type'] as String,
  toolName: json['toolName'] as String,
  status: $enumDecodeNullable(_$ToolStatusEnumMap, json['status']) ?? ToolStatus.running,
  input: json['input'] as Map<String, dynamic>? ?? const {},
  output: json['output'] as String?,
  filePath: json['filePath'] as String?,
  durationMs: (json['durationMs'] as num?)?.toInt(),
  tokensIn: (json['tokensIn'] as num?)?.toInt(),
  tokensOut: (json['tokensOut'] as num?)?.toInt(),
  error: json['error'] as String?,
);

Map<String, dynamic> _$ToolEventToJson(_ToolEvent instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'toolName': instance.toolName,
  'status': _$ToolStatusEnumMap[instance.status]!,
  'input': instance.input,
  'output': instance.output,
  'filePath': instance.filePath,
  'durationMs': instance.durationMs,
  'tokensIn': instance.tokensIn,
  'tokensOut': instance.tokensOut,
  'error': instance.error,
};

const _$ToolStatusEnumMap = {
  ToolStatus.running: 'running',
  ToolStatus.success: 'success',
  ToolStatus.error: 'error',
  ToolStatus.cancelled: 'cancelled',
};
