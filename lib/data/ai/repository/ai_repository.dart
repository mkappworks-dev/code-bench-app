import '../../models/ai_model.dart';
import '../../models/chat_message.dart';

/// Domain-level AI API. Abstracts provider selection and stream buffering.
abstract interface class AIRepository {
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });

  /// Buffers [streamMessage] into a single [ChatMessage]. The buffering
  /// logic is implemented once here — not duplicated per provider.
  Future<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });

  Future<bool> testConnection(AIModel model, String apiKey);

  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey);
}
