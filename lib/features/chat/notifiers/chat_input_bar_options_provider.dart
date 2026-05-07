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
/// Intentionally a derived `@riverpod` function, not a Notifier/Actions class
/// — it owns no mutable state, only computes the capability surface from
/// `selectedModelProvider` + `apiKeysProvider` + the relevant datasource.
/// The `_provider.dart` suffix (rather than `_notifier.dart`) is what keeps
/// the arch test from flagging the legitimate `aiRepositoryProvider` watch
/// below — the test forbids notifier files from reading repository providers
/// directly. Returns `null` when the API-keys prefs haven't loaded yet — the
/// input bar treats that as "transport unknown" and disables the strip.
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
