import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../data/ai/repository/ai_repository.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/ai/repository/text_streaming_repository.dart';
import '../../data/shared/ai_model.dart';
import '../../data/shared/chat_message.dart';

export '../../data/ai/repository/ai_repository_impl.dart' show aiRepositoryProvider;
export '../../data/shared/ai_model.dart' show AIProvider;

part 'ai_service.g.dart';

@Riverpod(keepAlive: true)
Future<AIService> aiService(Ref ref) async {
  final repo = await ref.watch(aiRepositoryProvider.future);
  // The same [AIRepositoryImpl] instance satisfies both narrow interfaces.
  return AIService(repo: repo, streaming: repo);
}

/// Owns stream-buffering logic for AI message generation.
///
/// Depends on two narrow capabilities instead of one fat repository: the
/// provider-selection primitives come from [AIRepository], text streaming
/// comes from [TextStreamingRepository]. Both are satisfied by the same
/// concrete instance in production, but the split keeps each dependency
/// precise and mockable.
class AIService {
  AIService({required AIRepository repo, required TextStreamingRepository streaming, String Function()? uuidGen})
    : _repo = repo,
      _streaming = streaming,
      _uuidGen = uuidGen ?? (() => const Uuid().v4());

  final AIRepository _repo;
  final TextStreamingRepository _streaming;
  final String Function() _uuidGen;

  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    try {
      yield* _streaming.streamMessage(history: history, prompt: prompt, model: model, systemPrompt: systemPrompt);
    } on NetworkException catch (e, st) {
      Error.throwWithStackTrace(
        NetworkException(
          _mapStatusCode(e.statusCode, provider: model.provider),
          statusCode: e.statusCode,
          originalError: e.originalError,
        ),
        st,
      );
    }
  }

  static String _mapStatusCode(int? statusCode, {required AIProvider provider}) {
    final name = provider.displayName;
    return switch (statusCode) {
      401 => 'Invalid API key — go to Settings → Providers to update it.',
      403 => 'Access denied — check your $name API key permissions.',
      429 => 'Rate limit reached — try again in a moment.',
      500 || 502 || 503 || 504 => '$name is temporarily unavailable — try again.',
      _ => '$name request failed.',
    };
  }

  Future<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in _streaming.streamMessage(
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
