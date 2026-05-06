import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/ai/models/provider_capabilities.dart';
import '../../../data/ai/repository/ai_repository_impl.dart';
import '../../../data/shared/ai_model.dart';
import '../../../services/ai_provider/ai_provider_service.dart';
import '../../providers/notifiers/providers_notifier.dart';
import 'chat_notifier.dart';

part 'chat_input_bar_options_provider.g.dart';

/// Capabilities for the *currently selected* model on its active transport.
///
/// CLI providers (claude-cli, codex) advertise capabilities via their
/// `AIProviderDatasource`. HTTP providers route through `AIRepository` to
/// stay one rung above the datasource layer per the dependency rule.
/// Returns `null` when the API-keys prefs haven't loaded yet — the input
/// bar treats that as "transport unknown" and disables the strip.
@riverpod
ProviderCapabilities? chatInputBarOptions(Ref ref) {
  final model = ref.watch(selectedModelProvider);
  final prefs = ref.watch(apiKeysProvider).value;
  if (prefs == null) return null;

  final cliProviderId = _resolveCliProviderId(model, prefs);
  if (cliProviderId != null) {
    final cliDs = ref.watch(aIProviderServiceProvider.notifier).getProvider(cliProviderId);
    return cliDs?.capabilitiesFor(model);
  }

  final repo = ref.watch(aiRepositoryProvider).value;
  return repo?.capabilitiesFor(model);
}

String? _resolveCliProviderId(AIModel model, ApiKeysNotifierState prefs) {
  return switch ((model.provider, prefs)) {
    (AIProvider.anthropic, ApiKeysNotifierState(anthropicTransport: 'cli')) => 'claude-cli',
    (AIProvider.openai, ApiKeysNotifierState(openaiTransport: 'cli')) => 'codex',
    _ => null,
  };
}
