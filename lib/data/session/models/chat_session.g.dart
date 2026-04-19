// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatSession _$ChatSessionFromJson(Map<String, dynamic> json) => _ChatSession(
  sessionId: json['sessionId'] as String,
  title: json['title'] as String,
  modelId: json['modelId'] as String,
  providerId: json['providerId'] as String,
  projectId: json['projectId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isPinned: json['isPinned'] as bool? ?? false,
  isArchived: json['isArchived'] as bool? ?? false,
  systemPrompt: json['systemPrompt'] as String?,
  mode: json['mode'] as String?,
  effort: json['effort'] as String?,
  permission: json['permission'] as String?,
);

Map<String, dynamic> _$ChatSessionToJson(_ChatSession instance) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'title': instance.title,
  'modelId': instance.modelId,
  'providerId': instance.providerId,
  'projectId': instance.projectId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isPinned': instance.isPinned,
  'isArchived': instance.isArchived,
  'systemPrompt': instance.systemPrompt,
  'mode': instance.mode,
  'effort': instance.effort,
  'permission': instance.permission,
};
