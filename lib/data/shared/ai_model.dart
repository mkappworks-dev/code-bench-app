import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_model.freezed.dart';
part 'ai_model.g.dart';

enum AIProvider {
  openai,
  anthropic,
  gemini,
  ollama,
  custom;

  String get displayName {
    switch (this) {
      case AIProvider.openai:
        return 'OpenAI';
      case AIProvider.anthropic:
        return 'Anthropic';
      case AIProvider.gemini:
        return 'Gemini';
      case AIProvider.ollama:
        return 'Ollama';
      case AIProvider.custom:
        return 'Custom';
    }
  }
}

@freezed
abstract class AIModel with _$AIModel {
  const factory AIModel({
    required String id,
    required AIProvider provider,
    required String name,
    required String modelId,
    String? endpoint,
    @Default(128000) int contextWindow,
    @Default(true) bool supportsStreaming,
    @Default(false) bool isDefault,
  }) = _AIModel;

  factory AIModel.fromJson(Map<String, dynamic> json) => _$AIModelFromJson(json);
}

// Predefined models
class AIModels {
  static const gpt4o = AIModel(
    id: 'gpt-4o',
    provider: AIProvider.openai,
    name: 'GPT-4o',
    modelId: 'gpt-4o',
    contextWindow: 128000,
    supportsStreaming: true,
    isDefault: true,
  );

  static const gpt4oMini = AIModel(
    id: 'gpt-4o-mini',
    provider: AIProvider.openai,
    name: 'GPT-4o Mini',
    modelId: 'gpt-4o-mini',
    contextWindow: 128000,
    supportsStreaming: true,
  );

  static const claude35Sonnet = AIModel(
    id: 'claude-3-5-sonnet-20241022',
    provider: AIProvider.anthropic,
    name: 'Claude 3.5 Sonnet',
    modelId: 'claude-3-5-sonnet-20241022',
    contextWindow: 200000,
    supportsStreaming: true,
    isDefault: true,
  );

  static const claude3Haiku = AIModel(
    id: 'claude-3-haiku-20240307',
    provider: AIProvider.anthropic,
    name: 'Claude 3 Haiku',
    modelId: 'claude-3-haiku-20240307',
    contextWindow: 200000,
    supportsStreaming: true,
  );

  static const geminiFlash = AIModel(
    id: 'gemini-2.0-flash',
    provider: AIProvider.gemini,
    name: 'Gemini 2.0 Flash',
    modelId: 'gemini-2.0-flash',
    contextWindow: 1000000,
    supportsStreaming: true,
    isDefault: true,
  );

  static const customModel = AIModel(
    id: 'custom',
    provider: AIProvider.custom,
    name: 'Custom',
    modelId: 'custom',
    contextWindow: 128000,
    supportsStreaming: true,
  );

  static List<AIModel> get defaults => [gpt4o, gpt4oMini, claude35Sonnet, claude3Haiku, geminiFlash, customModel];

  static AIModel? fromId(String modelId) => defaults.firstWhereOrNull((m) => m.modelId == modelId);
}
