import '../../shared/ai_model.dart';
import '../../shared/chat_message.dart';

/// Single-provider I/O boundary. Speaks wire protocol only — no persistence,
/// no retries, no provider-selection logic.
abstract interface class AIRemoteDatasource {
  AIProvider get provider;

  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });

  Future<bool> testConnection(AIModel model, String apiKey);

  Future<List<AIModel>> fetchAvailableModels(String apiKey);
}
