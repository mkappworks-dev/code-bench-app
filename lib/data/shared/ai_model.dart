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

// Offline-fallback list and the seed `AIModels.fromId` uses to resolve a stored modelId back to a typed [AIModel].
class AIModels {
  static const gpt5 = AIModel(
    id: 'gpt-5',
    provider: AIProvider.openai,
    name: 'GPT-5',
    modelId: 'gpt-5',
    contextWindow: 400000,
    supportsStreaming: true,
    isDefault: true,
  );

  static const gpt5Mini = AIModel(
    id: 'gpt-5-mini',
    provider: AIProvider.openai,
    name: 'GPT-5 Mini',
    modelId: 'gpt-5-mini',
    contextWindow: 400000,
    supportsStreaming: true,
  );

  static const gpt5Codex = AIModel(
    id: 'gpt-5-codex',
    provider: AIProvider.openai,
    name: 'GPT-5 Codex',
    modelId: 'gpt-5-codex',
    contextWindow: 400000,
    supportsStreaming: true,
  );

  static const gpt4o = AIModel(
    id: 'gpt-4o',
    provider: AIProvider.openai,
    name: 'GPT-4o',
    modelId: 'gpt-4o',
    contextWindow: 128000,
    supportsStreaming: true,
  );

  static const gpt4oMini = AIModel(
    id: 'gpt-4o-mini',
    provider: AIProvider.openai,
    name: 'GPT-4o Mini',
    modelId: 'gpt-4o-mini',
    contextWindow: 128000,
    supportsStreaming: true,
  );

  static const opus47 = AIModel(
    id: 'claude-opus-4-7',
    provider: AIProvider.anthropic,
    name: 'Claude Opus 4.7',
    modelId: 'claude-opus-4-7',
    contextWindow: 200000,
    supportsStreaming: true,
  );

  static const sonnet46 = AIModel(
    id: 'claude-sonnet-4-6',
    provider: AIProvider.anthropic,
    name: 'Claude Sonnet 4.6',
    modelId: 'claude-sonnet-4-6',
    contextWindow: 200000,
    supportsStreaming: true,
    isDefault: true,
  );

  static const haiku45 = AIModel(
    id: 'claude-haiku-4-5-20251001',
    provider: AIProvider.anthropic,
    name: 'Claude Haiku 4.5',
    modelId: 'claude-haiku-4-5-20251001',
    contextWindow: 200000,
    supportsStreaming: true,
  );

  static const gemini3Pro = AIModel(
    id: 'gemini-3-pro',
    provider: AIProvider.gemini,
    name: 'Gemini 3 Pro',
    modelId: 'gemini-3-pro',
    contextWindow: 2000000,
    supportsStreaming: true,
  );

  static const gemini25Pro = AIModel(
    id: 'gemini-2.5-pro',
    provider: AIProvider.gemini,
    name: 'Gemini 2.5 Pro',
    modelId: 'gemini-2.5-pro',
    contextWindow: 2000000,
    supportsStreaming: true,
  );

  static const gemini25Flash = AIModel(
    id: 'gemini-2.5-flash',
    provider: AIProvider.gemini,
    name: 'Gemini 2.5 Flash',
    modelId: 'gemini-2.5-flash',
    contextWindow: 1000000,
    supportsStreaming: true,
    isDefault: true,
  );

  static const gemini20Flash = AIModel(
    id: 'gemini-2.0-flash',
    provider: AIProvider.gemini,
    name: 'Gemini 2.0 Flash',
    modelId: 'gemini-2.0-flash',
    contextWindow: 1000000,
    supportsStreaming: true,
  );

  static List<AIModel> get defaults => [
    gpt5,
    gpt5Mini,
    gpt5Codex,
    gpt4o,
    gpt4oMini,
    opus47,
    sonnet46,
    haiku45,
    gemini3Pro,
    gemini25Pro,
    gemini25Flash,
    gemini20Flash,
  ];

  static const openAiChatModelPrefixes = <String>['gpt-', 'o1', 'o3', 'o4-mini', 'codex-'];

  /// Disqualifies non-chat OpenAI ids that share a chat prefix (image, audio, realtime, search-preview).
  static const openAiNonChatSubstrings = <String>['image', 'audio', 'realtime', 'transcribe', 'tts', 'search-preview'];

  /// Disqualifies Gemini ids that contain "gemini" but aren't chat (image, embedding, tts, live, native-audio).
  static const geminiNonChatSubstrings = <String>['image', 'embedding', 'tts', 'live', 'native-audio'];

  /// Subset of [openAiChatModelPrefixes] that accepts `reasoning_effort` — `gpt-4o*` is chat but not reasoning.
  static const openAiReasoningPrefixes = <String>['o1', 'o3', 'o4-mini', 'gpt-5'];

  /// Anthropic adaptive-only models — the API rejects a manual `thinking.budget_tokens` so mappers omit the field.
  static const anthropicAdaptiveOnlyIds = <String>{'claude-opus-4-7', 'claude-opus-4-7-20251201'};

  static bool isOpenAiChatModelId(String modelId) {
    if (!openAiChatModelPrefixes.any(modelId.startsWith)) return false;
    if (openAiNonChatSubstrings.any(modelId.contains)) return false;
    return true;
  }

  static bool isOpenAiReasoningModel(String modelId) => openAiReasoningPrefixes.any(modelId.startsWith);

  static bool isAnthropicAdaptiveOnly(String modelId) => anthropicAdaptiveOnlyIds.contains(modelId);

  static bool isGemini3(String modelId) => modelId.startsWith('gemini-3');

  /// Pre-2.5 Gemini ignores `generationConfig.thinkingConfig`; only 2.5 and 3 honour it.
  static bool supportsGeminiThinking(String modelId) =>
      modelId.startsWith('gemini-2.5') || modelId.startsWith('gemini-3');

  static AIModel? fromId(String modelId) => defaults.firstWhereOrNull((m) => m.modelId == modelId);
}
