import '../../shared/ai_model.dart';
import '../../shared/chat_message.dart';

/// Capability for repositories that stream raw text tokens.
///
/// Intentionally orthogonal to `AIRepository`: callers that only need text
/// streaming depend on this narrow interface, and repositories that can't
/// provide text streaming (CLI-backed routes handled at the SessionService
/// layer) don't have to declare a method they can't honour.
abstract interface class TextStreamingRepository {
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });
}
