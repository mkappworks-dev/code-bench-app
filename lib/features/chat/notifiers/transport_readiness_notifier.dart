import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/ai/models/auth_status.dart';
import '../../../data/chat/models/transport_readiness.dart';
import '../../../data/shared/ai_model.dart';
import '../../providers/notifiers/ai_provider_status_notifier.dart';
import '../../providers/notifiers/providers_notifier.dart';
import 'chat_notifier.dart';

part 'transport_readiness_notifier.g.dart';

/// CLI auth `unknown` maps to [TransportReadiness.ready] — never block send on
/// a probe we couldn't run; the fresh pre-send probe in [ChatMessagesNotifier]
/// catches real signed-out cases.
@riverpod
TransportReadiness transportReadiness(Ref ref) {
  final model = ref.watch(selectedModelProvider);
  final prefsAsync = ref.watch(apiKeysProvider);
  final entriesAsync = ref.watch(aiProviderStatusProvider);

  final prefs = prefsAsync.value;
  if (prefs == null) return const TransportReadiness.unknown();

  final providerId = _resolveCliProviderId(model, prefs);
  if (providerId == null) {
    return _httpReadiness(model.provider, prefs);
  }

  final entries = entriesAsync.value;
  if (entries == null) return const TransportReadiness.unknown();
  final entry = entries.where((e) => e.id == providerId).firstOrNull;
  if (entry == null || entry.status is! ProviderAvailable) {
    return TransportReadiness.notInstalled(provider: providerId);
  }
  return switch (entry.authStatus) {
    AuthAuthenticated() => const TransportReadiness.ready(),
    AuthUnauthenticated(:final signInCommand) => TransportReadiness.signedOut(
      provider: providerId,
      signInCommand: signInCommand,
    ),
    AuthUnknown() => const TransportReadiness.ready(),
  };
}

String? _resolveCliProviderId(AIModel model, ApiKeysNotifierState prefs) {
  return switch ((model.provider, prefs)) {
    (AIProvider.anthropic, ApiKeysNotifierState(anthropicTransport: 'cli')) => 'claude-cli',
    (AIProvider.openai, ApiKeysNotifierState(openaiTransport: 'cli')) => 'codex',
    _ => null,
  };
}

TransportReadiness _httpReadiness(AIProvider provider, ApiKeysNotifierState prefs) {
  final keyConfigured = switch (provider) {
    AIProvider.anthropic => prefs.anthropic.isNotEmpty,
    AIProvider.openai => prefs.openai.isNotEmpty,
    AIProvider.gemini => prefs.gemini.isNotEmpty,
    AIProvider.ollama => prefs.ollamaUrl.isNotEmpty,
    AIProvider.custom => prefs.customApiKey.isNotEmpty && prefs.customEndpoint.isNotEmpty,
  };
  return keyConfigured
      ? const TransportReadiness.ready()
      : TransportReadiness.httpKeyMissing(provider: _providerLabel(provider));
}

String _providerLabel(AIProvider p) => switch (p) {
  AIProvider.anthropic => 'anthropic',
  AIProvider.openai => 'openai',
  AIProvider.gemini => 'gemini',
  AIProvider.ollama => 'ollama',
  AIProvider.custom => 'custom',
};
