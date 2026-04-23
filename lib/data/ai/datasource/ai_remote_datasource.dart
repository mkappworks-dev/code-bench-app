import '../../shared/ai_model.dart';
import '../../shared/chat_message.dart';

/// Single-provider I/O boundary. Every concrete transport implements this.
/// Speaks wire protocol only — no persistence, no retries, no
/// provider-selection logic.
///
/// Text-token streaming is a separate, orthogonal capability declared by
/// [TextStreamingDatasource]. HTTP-backed transports implement both
/// interfaces; CLI-backed transports implement only [AIRemoteDatasource]
/// and expose structured events through their concrete type instead.
/// Callers that need raw text streaming must check
/// `ds is TextStreamingDatasource` before invoking `streamMessage`.
abstract interface class AIRemoteDatasource {
  AIProvider get provider;

  Future<bool> testConnection(AIModel model, String apiKey);

  Future<List<AIModel>> fetchAvailableModels(String apiKey);
}

/// Capability for transports that stream raw text tokens.
///
/// Intentionally orthogonal to [AIRemoteDatasource]: a class opts into the
/// two interfaces independently so the "streams text" contract stays
/// minimal and doesn't bundle AI-provider concerns into unrelated consumers
/// that might want the capability later.
abstract interface class TextStreamingDatasource {
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });
}
