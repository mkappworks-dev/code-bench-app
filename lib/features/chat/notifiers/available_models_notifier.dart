import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/shared/ai_model.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/providers/providers_service.dart';

part 'available_models_notifier.g.dart';

class AvailableModelsResult {
  const AvailableModelsResult({required this.models, this.failedProviders = const {}});
  final List<AIModel> models;
  final Set<AIProvider> failedProviders;
}

@Riverpod(keepAlive: true)
class AvailableModelsNotifier extends _$AvailableModelsNotifier {
  @override
  Future<AvailableModelsResult> build() async {
    final repo = await ref.watch(aiServiceProvider.future);
    final svc = ref.read(providersServiceProvider);
    final ollamaUrl = await svc.readOllamaUrl() ?? '';
    final customEndpoint = await svc.readCustomEndpoint() ?? '';
    final customApiKey = await svc.readCustomApiKey() ?? '';

    final models = List<AIModel>.from(AIModels.defaults);
    final failed = <AIProvider>{};

    final futures = <Future<List<AIModel>>>[];

    if (ollamaUrl.isNotEmpty) {
      futures.add(
        repo.fetchAvailableModels(AIProvider.ollama, '').catchError((Object e) {
          dLog('[AvailableModelsNotifier] Ollama fetch failed: $e');
          failed.add(AIProvider.ollama);
          return <AIModel>[];
        }),
      );
    }

    if (customEndpoint.isNotEmpty) {
      futures.add(
        repo.fetchAvailableModels(AIProvider.custom, customApiKey).catchError((Object e) {
          dLog('[AvailableModelsNotifier] Custom fetch failed: $e');
          failed.add(AIProvider.custom);
          return <AIModel>[];
        }),
      );
    }

    if (futures.isNotEmpty) {
      final fetched = await Future.wait(futures);
      models.addAll(fetched.expand((list) => list));
    }

    return AvailableModelsResult(models: models, failedProviders: failed);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
