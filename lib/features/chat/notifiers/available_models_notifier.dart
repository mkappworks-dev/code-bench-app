import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/ai/datasource/codex_cli_datasource_process.dart';
import '../../../data/shared/ai_model.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/providers/providers_service.dart';
import '../../providers/notifiers/providers_notifier.dart';
import 'available_models_failure.dart';

part 'available_models_notifier.g.dart';

/// Union of the static `AIModels.defaults` and the dynamically-discovered
/// Ollama + Custom models. Per-provider fetch failures are kept in [failures]
/// so a partial success still produces `AsyncData` — the picker renders them
/// inline rather than collapsing to `AsyncError`.
class AvailableModelsResult {
  const AvailableModelsResult({required this.models, this.failures = const {}});
  final List<AIModel> models;
  final Map<AIProvider, ModelProviderFailure> failures;

  /// Backwards-compatible view used by widgets that only care *which*
  /// providers failed, not how.
  Set<AIProvider> get failedProviders => failures.keys.toSet();
}

@Riverpod(keepAlive: true)
class AvailableModelsNotifier extends _$AvailableModelsNotifier {
  @override
  Future<AvailableModelsResult> build() async {
    final AIService repo;
    final ApiKeysNotifierState apiKeys;
    final String ollamaUrl;
    final String customEndpoint;
    final String customApiKey;
    try {
      repo = await ref.watch(aiServiceProvider.future);
      apiKeys = await ref.watch(apiKeysProvider.future);
      final svc = ref.read(providersServiceProvider);
      ollamaUrl = await svc.readOllamaUrl() ?? '';
      customEndpoint = await svc.readCustomEndpoint() ?? '';
      customApiKey = await svc.readCustomApiKey() ?? '';
    } catch (e, st) {
      dLog('[AvailableModelsNotifier] storage read failed: $e');
      Error.throwWithStackTrace(AvailableModelsFailure.storageError(e), st);
    }

    // Seed the picker with the hardcoded defaults so users with no keys
    // configured still see something to pick. Live fetches below ADD models
    // the hardcoded list doesn't know about (e.g. brand-new releases) but
    // never replace a hardcoded entry's friendly display name.
    //
    // OpenAI defaults are skipped when `openaiTransport == 'cli'` — Codex
    // accepts a different (and account-tier-specific) set of model ids, so
    // showing `gpt-5` / `gpt-4o` in a Codex picker would mean every send
    // 400s. The Codex `model/list` RPC below feeds the OpenAI section with
    // ids the connected ChatGPT account actually accepts.
    final isCodexTransport = apiKeys.openaiTransport == 'cli';
    final modelsById = <String, AIModel>{
      for (final m in AIModels.defaults)
        if (!(isCodexTransport && m.provider == AIProvider.openai)) m.modelId: m,
    };
    final failures = <AIProvider, ModelProviderFailure>{};

    Future<List<AIModel>> fetchFor(AIProvider provider, String apiKey) async {
      try {
        return await repo.fetchAvailableModels(provider, apiKey);
      } catch (e) {
        dLog('[AvailableModelsNotifier] ${provider.name} fetch failed: ${e.runtimeType}');
        failures[provider] = _classify(provider, e);
        return const [];
      }
    }

    Future<List<AIModel>> fetchCodex() async {
      try {
        return await fetchCodexAvailableModels();
      } catch (e) {
        dLog('[AvailableModelsNotifier] codex model/list failed: ${e.runtimeType}');
        failures[AIProvider.openai] = _classify(AIProvider.openai, e);
        return const [];
      }
    }

    // Cloud providers are gated on a configured API key. With CLI transport
    // the key may be empty (auth lives in the CLI's own login state); we
    // skip the live fetch in that case rather than firing a guaranteed 401.
    final futures = <Future<List<AIModel>>>[
      if (isCodexTransport)
        fetchCodex()
      else if (apiKeys.openai.isNotEmpty)
        fetchFor(AIProvider.openai, apiKeys.openai),
      if (apiKeys.anthropic.isNotEmpty) fetchFor(AIProvider.anthropic, apiKeys.anthropic),
      if (apiKeys.gemini.isNotEmpty) fetchFor(AIProvider.gemini, apiKeys.gemini),
      if (ollamaUrl.isNotEmpty) fetchFor(AIProvider.ollama, ''),
      if (customEndpoint.isNotEmpty) fetchFor(AIProvider.custom, customApiKey),
    ];

    if (futures.isNotEmpty) {
      final fetched = await Future.wait(futures);
      for (final list in fetched) {
        for (final m in list) {
          // Hardcoded entry wins for display name; live fetch only contributes
          // models the defaults don't already know about.
          modelsById.putIfAbsent(m.modelId, () => m);
        }
      }
    }

    return AvailableModelsResult(models: modelsById.values.toList(), failures: failures);
  }

  /// Manual user-triggered refresh (e.g. the ↺ Refresh row in the picker).
  ///
  /// The automatic re-fetch path — endpoint saves in Settings — is handled by
  /// `ProvidersActions` invalidating `aiRepositoryProvider`, which cascades
  /// to `aiServiceProvider` (watched in [build]). So this method only exists
  /// to force a re-run in response to an explicit user gesture.
  ///
  /// Per-provider fetch failures during refresh land in
  /// `AvailableModelsResult.failures` (AsyncData stays green); only a storage
  /// failure produces `AsyncError`, and Riverpod preserves the prior models
  /// on that path via its built-in `copyWithPrevious`. Callers should not
  /// wrap this in their own try/catch (widget-layer rule).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // Swallowed: storage errors are already reported via `AsyncError` on
      // the provider. We only catch here so an unhandled rejection doesn't
      // crash the Zone.
    }
  }

  ModelProviderFailure _classify(AIProvider provider, Object e) => switch (e) {
    AuthException() => ModelProviderFailure.auth(provider),
    NetworkException() => ModelProviderFailure.unreachable(provider),
    ParseException(:final message) => ModelProviderFailure.malformedResponse(provider, message),
    _ => ModelProviderFailure.unknown(provider, e),
  };
}
