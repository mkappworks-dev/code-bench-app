import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/ai/models/provider_capabilities.dart';
import '../../../data/shared/ai_model.dart';
import '../../../services/ai/provider_capabilities_service.dart';
import '../../providers/notifiers/providers_notifier.dart';
import 'chat_notifier.dart';

part 'chat_input_bar_options_notifier.g.dart';

/// Capabilities for the currently selected model + transport; null while prefs haven't loaded so the input bar can disable the strip.
@riverpod
ProviderCapabilities? chatInputBarOptions(Ref ref) {
  final model = ref.watch(selectedModelProvider);
  final prefs = ref.watch(apiKeysProvider).value;
  if (prefs == null) return null;
  return ref
      .read(providerCapabilitiesServiceProvider)
      .capabilitiesFor(model: model, cliProviderId: _resolveCliProviderId(model, prefs));
}

String? _resolveCliProviderId(AIModel model, ApiKeysNotifierState prefs) {
  return switch ((model.provider, prefs)) {
    (AIProvider.anthropic, ApiKeysNotifierState(anthropicTransport: 'cli')) => 'claude-cli',
    (AIProvider.openai, ApiKeysNotifierState(openaiTransport: 'cli')) => 'codex',
    _ => null,
  };
}
