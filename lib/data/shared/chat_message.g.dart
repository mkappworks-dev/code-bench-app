// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CodeBlock _$CodeBlockFromJson(Map<String, dynamic> json) => _CodeBlock(
  code: json['code'] as String,
  language: json['language'] as String?,
  filename: json['filename'] as String?,
);

Map<String, dynamic> _$CodeBlockToJson(_CodeBlock instance) => <String, dynamic>{
  'code': instance.code,
  'language': instance.language,
  'filename': instance.filename,
};

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: json['id'] as String,
  sessionId: json['sessionId'] as String,
  role: $enumDecode(_$MessageRoleEnumMap, json['role']),
  content: json['content'] as String,
  codeBlocks:
      (json['codeBlocks'] as List<dynamic>?)?.map((e) => CodeBlock.fromJson(e as Map<String, dynamic>)).toList() ??
      const [],
  toolEvents:
      (json['toolEvents'] as List<dynamic>?)?.map((e) => ToolEvent.fromJson(e as Map<String, dynamic>)).toList() ??
      const [],
  timestamp: DateTime.parse(json['timestamp'] as String),
  isStreaming: json['isStreaming'] as bool? ?? false,
  askQuestion: json['askQuestion'] == null
      ? null
      : AskUserQuestion.fromJson(json['askQuestion'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) => <String, dynamic>{
  'id': instance.id,
  'sessionId': instance.sessionId,
  'role': _$MessageRoleEnumMap[instance.role]!,
  'content': instance.content,
  'codeBlocks': instance.codeBlocks,
  'toolEvents': instance.toolEvents,
  'timestamp': instance.timestamp.toIso8601String(),
  'isStreaming': instance.isStreaming,
  'askQuestion': instance.askQuestion,
};

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
  MessageRole.system: 'system',
};
