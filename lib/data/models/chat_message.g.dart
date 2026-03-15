// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CodeBlockImpl _$$CodeBlockImplFromJson(Map<String, dynamic> json) =>
    _$CodeBlockImpl(
      code: json['code'] as String,
      language: json['language'] as String?,
      filename: json['filename'] as String?,
    );

Map<String, dynamic> _$$CodeBlockImplToJson(_$CodeBlockImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'language': instance.language,
      'filename': instance.filename,
    };

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      role: $enumDecode(_$MessageRoleEnumMap, json['role']),
      content: json['content'] as String,
      codeBlocks: (json['codeBlocks'] as List<dynamic>?)
              ?.map((e) => CodeBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      timestamp: DateTime.parse(json['timestamp'] as String),
      isStreaming: json['isStreaming'] as bool? ?? false,
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'content': instance.content,
      'codeBlocks': instance.codeBlocks,
      'timestamp': instance.timestamp.toIso8601String(),
      'isStreaming': instance.isStreaming,
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
  MessageRole.system: 'system',
};
