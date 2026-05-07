import '../../shared/ai_model.dart';
import '../../shared/chat_message.dart';
import '../models/provider_capabilities.dart';
import '../models/provider_setting_drop.dart';
import '../models/provider_turn_settings.dart';

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
  /// Capability surface for the picked [model]; HTTP datasources may shrink the supported sets per model id.
  ProviderCapabilities capabilitiesFor(AIModel model);

  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
    ProviderTurnSettings? settings,
    ProviderSettingDropSink? onSettingDropped,
  });
}
