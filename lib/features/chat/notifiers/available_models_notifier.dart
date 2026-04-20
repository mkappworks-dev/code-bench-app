import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/shared/ai_model.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/providers/providers_service.dart';
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
    final String ollamaUrl;
    final String customEndpoint;
    final String customApiKey;
    try {
      repo = await ref.watch(aiServiceProvider.future);
      final svc = ref.read(providersServiceProvider);
      ollamaUrl = await svc.readOllamaUrl() ?? '';
      customEndpoint = await svc.readCustomEndpoint() ?? '';
      customApiKey = await svc.readCustomApiKey() ?? '';
    } catch (e, st) {
      dLog('[AvailableModelsNotifier] storage read failed: $e');
      Error.throwWithStackTrace(AvailableModelsFailure.storageError(e), st);
    }

    final models = List<AIModel>.from(AIModels.defaults);
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

    final futures = <Future<List<AIModel>>>[
      if (ollamaUrl.isNotEmpty) fetchFor(AIProvider.ollama, ''),
      if (customEndpoint.isNotEmpty) fetchFor(AIProvider.custom, customApiKey),
    ];

    if (futures.isNotEmpty) {
      final fetched = await Future.wait(futures);
      models.addAll(fetched.expand((list) => list));
    }

    return AvailableModelsResult(models: models, failures: failures);
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
