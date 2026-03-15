// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AIModelImpl _$$AIModelImplFromJson(Map<String, dynamic> json) =>
    _$AIModelImpl(
      id: json['id'] as String,
      provider: $enumDecode(_$AIProviderEnumMap, json['provider']),
      name: json['name'] as String,
      modelId: json['modelId'] as String,
      endpoint: json['endpoint'] as String?,
      contextWindow: (json['contextWindow'] as num?)?.toInt() ?? 128000,
      supportsStreaming: json['supportsStreaming'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
    );

Map<String, dynamic> _$$AIModelImplToJson(_$AIModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'provider': _$AIProviderEnumMap[instance.provider]!,
      'name': instance.name,
      'modelId': instance.modelId,
      'endpoint': instance.endpoint,
      'contextWindow': instance.contextWindow,
      'supportsStreaming': instance.supportsStreaming,
      'isDefault': instance.isDefault,
    };

const _$AIProviderEnumMap = {
  AIProvider.openai: 'openai',
  AIProvider.anthropic: 'anthropic',
  AIProvider.gemini: 'gemini',
  AIProvider.ollama: 'ollama',
  AIProvider.custom: 'custom',
};
