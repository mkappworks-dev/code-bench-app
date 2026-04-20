import '../../coding_tools/models/coding_tool_definition.dart';
import '../../shared/ai_model.dart';
import '../../shared/chat_message.dart';
import '../models/stream_event.dart';

/// Domain-level AI API. Abstracts provider selection and stream buffering.
abstract interface class AIRepository {
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });

  /// Function-calling stream. MVP only supports [AIProvider.custom]. For all
  /// other providers this throws [UnsupportedError] (caller gates on provider).
  Stream<StreamEvent> streamMessageWithTools({
    required List<Map<String, dynamic>> wireMessages,
    required List<CodingToolDefinition> tools,
    required AIModel model,
  });

  Future<bool> testConnection(AIModel model, String apiKey);

  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey);
}
