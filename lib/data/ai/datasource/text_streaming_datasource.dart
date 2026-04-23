import '../../shared/ai_model.dart';
import '../../shared/chat_message.dart';

/// Capability for transports that stream raw text tokens.
///
/// Intentionally orthogonal to `AIRemoteDatasource`: a class opts into the
/// two interfaces independently so the "streams text" contract stays
/// minimal and doesn't bundle AI-provider concerns into unrelated consumers
/// that might want the capability later. HTTP-backed transports (OpenAI,
/// Anthropic, Gemini, Ollama, custom OpenAI-compatible) implement both
/// interfaces; CLI-backed transports implement only `AIRemoteDatasource`
/// and expose structured event streams through their concrete type.
abstract interface class TextStreamingDatasource {
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });
}
