// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_turn_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProviderTurnSettings _$ProviderTurnSettingsFromJson(Map<String, dynamic> json) => _ProviderTurnSettings(
  modelId: json['modelId'] as String?,
  systemPrompt: json['systemPrompt'] as String?,
  mode: $enumDecodeNullable(_$ChatModeEnumMap, json['mode']),
  effort: $enumDecodeNullable(_$ChatEffortEnumMap, json['effort']),
  permission: $enumDecodeNullable(_$ChatPermissionEnumMap, json['permission']),
);

Map<String, dynamic> _$ProviderTurnSettingsToJson(_ProviderTurnSettings instance) => <String, dynamic>{
  'modelId': instance.modelId,
  'systemPrompt': instance.systemPrompt,
  'mode': _$ChatModeEnumMap[instance.mode],
  'effort': _$ChatEffortEnumMap[instance.effort],
  'permission': _$ChatPermissionEnumMap[instance.permission],
};

const _$ChatModeEnumMap = {ChatMode.chat: 'chat', ChatMode.plan: 'plan', ChatMode.act: 'act'};

const _$ChatEffortEnumMap = {
  ChatEffort.low: 'low',
  ChatEffort.medium: 'medium',
  ChatEffort.high: 'high',
  ChatEffort.max: 'max',
};

const _$ChatPermissionEnumMap = {
  ChatPermission.readOnly: 'readOnly',
  ChatPermission.askBefore: 'askBefore',
  ChatPermission.fullAccess: 'fullAccess',
};
