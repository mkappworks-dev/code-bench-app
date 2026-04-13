import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/ai/repository/ai_repository.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/models/ai_model.dart';
import '../../data/models/chat_message.dart';

export '../../data/models/ai_model.dart' show AIProvider;

part 'ai_service.g.dart';

@Riverpod(keepAlive: true)
Future<AIService> aiService(Ref ref) async {
  final repo = await ref.watch(aiRepositoryProvider.future);
  return AIService(repo: repo);
}

/// Owns stream-buffering logic for AI message generation.
///
/// [AIRepository] retains [streamMessage], [testConnection], and
/// [fetchAvailableModels] as primitives. [sendMessage] — the buffering
/// composition — lives here.
class AIService {
  AIService({required AIRepository repo, String Function()? uuidGen})
    : _repo = repo,
      _uuidGen = uuidGen ?? (() => const Uuid().v4());

  final AIRepository _repo;
  final String Function() _uuidGen;

  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) => _repo.streamMessage(history: history, prompt: prompt, model: model, systemPrompt: systemPrompt);

  Future<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in _repo.streamMessage(
      history: history,
      prompt: prompt,
      model: model,
      systemPrompt: systemPrompt,
    )) {
      buffer.write(chunk);
    }
    return ChatMessage(
      id: _uuidGen(),
      sessionId: history.isNotEmpty ? history.first.sessionId : '',
      role: MessageRole.assistant,
      content: buffer.toString(),
      timestamp: DateTime.now(),
    );
  }

  Future<bool> testConnection(AIModel model, String apiKey) => _repo.testConnection(model, apiKey);

  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey) =>
      _repo.fetchAvailableModels(provider, apiKey);
}
