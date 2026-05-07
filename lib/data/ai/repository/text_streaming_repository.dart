import '../../shared/ai_model.dart';
import '../../shared/chat_message.dart';
import '../models/provider_capabilities.dart';
import '../models/provider_setting_drop.dart';
import '../models/provider_turn_settings.dart';

/// Capability for repositories that stream raw text tokens.
///
/// Intentionally orthogonal to `AIRepository`: callers that only need text
/// streaming depend on this narrow interface, and repositories that can't
/// provide text streaming (CLI-backed routes handled at the SessionService
/// layer) don't have to declare a method they can't honour.
abstract interface class TextStreamingRepository {
  /// Capability surface for [model] on its registered HTTP datasource.
  /// Returns `null` when no HTTP datasource is registered for the model's
  /// provider (CLI-only providers).
  ProviderCapabilities? capabilitiesFor(AIModel model);

  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
    ProviderTurnSettings? settings,
    ProviderSettingDropSink? onSettingDropped,
  });
}
