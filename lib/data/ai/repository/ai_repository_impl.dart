import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/_core/secure_storage.dart';
import '../../../data/coding_tools/models/coding_tool_definition.dart';
import '../../../data/shared/ai_model.dart';
import '../../../data/shared/chat_message.dart';
import '../datasource/ai_remote_datasource.dart';
import '../datasource/anthropic_remote_datasource_dio.dart';
import '../datasource/custom_remote_datasource_dio.dart';
import '../datasource/gemini_remote_datasource_dio.dart';
import '../datasource/ollama_remote_datasource_dio.dart';
import '../datasource/openai_remote_datasource_dio.dart';
import '../models/stream_event.dart';
import 'ai_repository.dart';

part 'ai_repository_impl.g.dart';

@Riverpod(keepAlive: true)
Future<AIRepository> aiRepository(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  return AIRepositoryImpl(
    sources: {
      AIProvider.anthropic: AnthropicRemoteDatasourceDio(await storage.readApiKey('anthropic') ?? ''),
      AIProvider.openai: OpenAIRemoteDatasourceDio(await storage.readApiKey('openai') ?? ''),
      AIProvider.gemini: GeminiRemoteDatasourceDio(await storage.readApiKey('gemini') ?? ''),
      AIProvider.ollama: OllamaRemoteDatasourceDio(await storage.readOllamaUrl() ?? 'http://localhost:11434'),
      AIProvider.custom: CustomRemoteDatasourceDio(
        endpoint: await storage.readCustomEndpoint() ?? '',
        apiKey: await storage.readCustomApiKey() ?? '',
      ),
    },
  );
}

class AIRepositoryImpl implements AIRepository {
  AIRepositoryImpl({required Map<AIProvider, AIRemoteDatasource> sources}) : _sources = sources;

  final Map<AIProvider, AIRemoteDatasource> _sources;
  AIRemoteDatasource _source(AIProvider provider) {
    final src = _sources[provider];
    if (src == null) throw StateError('No datasource registered for $provider');
    return src;
  }

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) {
    return _source(
      model.provider,
    ).streamMessage(history: history, prompt: prompt, model: model, systemPrompt: systemPrompt);
  }

  @override
  Stream<StreamEvent> streamMessageWithTools({
    required List<Map<String, dynamic>> wireMessages,
    required List<CodingToolDefinition> tools,
    required AIModel model,
  }) {
    final src = _source(model.provider);
    if (src is! CustomRemoteDatasourceDio) {
      throw UnsupportedError('streamMessageWithTools is only supported on AIProvider.custom in the MVP');
    }
    return src.streamMessageWithTools(messages: wireMessages, tools: tools, model: model);
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) {
    return _source(model.provider).testConnection(model, apiKey);
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey) {
    return _source(provider).fetchAvailableModels(apiKey);
  }
}
