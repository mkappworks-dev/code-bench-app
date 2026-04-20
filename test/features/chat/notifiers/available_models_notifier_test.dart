import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/services/ai/ai_service.dart';
import 'package:code_bench_app/services/providers/providers_service.dart';
import 'package:code_bench_app/features/chat/notifiers/available_models_notifier.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeAIService extends Fake implements AIService {
  final Map<AIProvider, List<AIModel>> models;
  final Map<AIProvider, Exception> errors;

  _FakeAIService({this.models = const {}, this.errors = const {}});

  @override
  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey) async {
    final err = errors[provider];
    if (err != null) throw err;
    return models[provider] ?? [];
  }
}

class _FakeProvidersService extends Fake implements ProvidersService {
  final String ollamaUrl;
  final String customEndpoint;
  final String customApiKey;

  _FakeProvidersService({
    this.ollamaUrl = '',
    this.customEndpoint = '',
    this.customApiKey = '',
  });

  @override
  Future<String?> readOllamaUrl() async => ollamaUrl.isEmpty ? null : ollamaUrl;

  @override
  Future<String?> readCustomEndpoint() async => customEndpoint.isEmpty ? null : customEndpoint;

  @override
  Future<String?> readCustomApiKey() async => customApiKey.isEmpty ? null : customApiKey;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer({
  required _FakeAIService svc,
  required _FakeProvidersService providers,
}) {
  return ProviderContainer(
    overrides: [
      aiServiceProvider.overrideWith((ref) async => svc),
      providersServiceProvider.overrideWith((ref) => providers),
    ],
  );
}

AIModel _ollamaModel(String name) => AIModel(
      id: 'ollama_$name',
      provider: AIProvider.ollama,
      name: name,
      modelId: name,
      supportsStreaming: true,
    );

AIModel _customModel(String id) => AIModel(
      id: id,
      provider: AIProvider.custom,
      name: id,
      modelId: id,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AvailableModelsNotifier', () {
    test('returns only static defaults when no endpoints configured', () async {
      final container = _makeContainer(
        svc: _FakeAIService(),
        providers: _FakeProvidersService(),
      );
      addTearDown(container.dispose);

      final models = await container.read(availableModelsProvider.future);
      expect(models, equals(AIModels.defaults));
      expect(models.any((m) => m.provider == AIProvider.ollama), isFalse);
      expect(models.any((m) => m.provider == AIProvider.custom), isFalse);
    });

    test('includes ollama models when ollama URL is configured', () async {
      final ollamaModels = [_ollamaModel('llama3.2'), _ollamaModel('mistral')];
      final container = _makeContainer(
        svc: _FakeAIService(models: {AIProvider.ollama: ollamaModels}),
        providers: _FakeProvidersService(ollamaUrl: 'http://localhost:11434'),
      );
      addTearDown(container.dispose);

      final models = await container.read(availableModelsProvider.future);
      expect(models, containsAll(AIModels.defaults));
      expect(models, containsAll(ollamaModels));
    });

    test('includes custom models when custom endpoint is configured', () async {
      final customModels = [_customModel('mistral-7b-instruct'), _customModel('codestral-22b')];
      final container = _makeContainer(
        svc: _FakeAIService(models: {AIProvider.custom: customModels}),
        providers: _FakeProvidersService(customEndpoint: 'http://localhost:1234/v1'),
      );
      addTearDown(container.dispose);

      final models = await container.read(availableModelsProvider.future);
      expect(models, containsAll(AIModels.defaults));
      expect(models, containsAll(customModels));
    });

    test('includes models from both dynamic providers when both configured', () async {
      final ollamaModels = [_ollamaModel('llama3.2')];
      final customModels = [_customModel('mistral-7b-instruct')];
      final container = _makeContainer(
        svc: _FakeAIService(models: {
          AIProvider.ollama: ollamaModels,
          AIProvider.custom: customModels,
        }),
        providers: _FakeProvidersService(
          ollamaUrl: 'http://localhost:11434',
          customEndpoint: 'http://localhost:1234/v1',
        ),
      );
      addTearDown(container.dispose);

      final models = await container.read(availableModelsProvider.future);
      expect(models, containsAll(AIModels.defaults));
      expect(models, containsAll(ollamaModels));
      expect(models, containsAll(customModels));
    });

    test('ollama fetch failure does not affect static or custom models', () async {
      final customModels = [_customModel('mistral-7b-instruct')];
      final container = _makeContainer(
        svc: _FakeAIService(
          models: {AIProvider.custom: customModels},
          errors: {AIProvider.ollama: Exception('connection refused')},
        ),
        providers: _FakeProvidersService(
          ollamaUrl: 'http://localhost:11434',
          customEndpoint: 'http://localhost:1234/v1',
        ),
      );
      addTearDown(container.dispose);

      final models = await container.read(availableModelsProvider.future);
      expect(models, containsAll(AIModels.defaults));
      expect(models, containsAll(customModels));
      expect(models.any((m) => m.provider == AIProvider.ollama), isFalse);
    });

    test('custom fetch failure does not affect static or ollama models', () async {
      final ollamaModels = [_ollamaModel('llama3.2')];
      final container = _makeContainer(
        svc: _FakeAIService(
          models: {AIProvider.ollama: ollamaModels},
          errors: {AIProvider.custom: Exception('connection refused')},
        ),
        providers: _FakeProvidersService(
          ollamaUrl: 'http://localhost:11434',
          customEndpoint: 'http://localhost:1234/v1',
        ),
      );
      addTearDown(container.dispose);

      final models = await container.read(availableModelsProvider.future);
      expect(models, containsAll(AIModels.defaults));
      expect(models, containsAll(ollamaModels));
      expect(models.any((m) => m.provider == AIProvider.custom), isFalse);
    });

    test('notifier resolves to AsyncData even when both fetches fail', () async {
      final container = _makeContainer(
        svc: _FakeAIService(
          errors: {
            AIProvider.ollama: Exception('offline'),
            AIProvider.custom: Exception('offline'),
          },
        ),
        providers: _FakeProvidersService(
          ollamaUrl: 'http://localhost:11434',
          customEndpoint: 'http://localhost:1234/v1',
        ),
      );
      addTearDown(container.dispose);

      final result = await container.read(availableModelsProvider.future);
      expect(result, equals(AIModels.defaults));
    });
  });
}
