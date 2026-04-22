// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PermissionRequest _$PermissionRequestFromJson(Map<String, dynamic> json) =>
    _PermissionRequest(
      toolEventId: json['toolEventId'] as String,
      toolName: json['toolName'] as String,
      summary: json['summary'] as String,
      input: json['input'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$PermissionRequestToJson(_PermissionRequest instance) =>
    <String, dynamic>{
      'toolEventId': instance.toolEventId,
      'toolName': instance.toolName,
      'summary': instance.summary,
      'input': instance.input,
    };
