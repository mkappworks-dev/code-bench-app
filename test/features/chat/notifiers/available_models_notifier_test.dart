import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/core/errors/app_exception.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/services/ai/ai_service.dart';
import 'package:code_bench_app/services/providers/providers_service.dart';
import 'package:code_bench_app/features/chat/notifiers/available_models_failure.dart';
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

  _FakeProvidersService({this.ollamaUrl = '', this.customEndpoint = ''});

  @override
  Future<String?> readOllamaUrl() async => ollamaUrl.isEmpty ? null : ollamaUrl;

  @override
  Future<String?> readCustomEndpoint() async => customEndpoint.isEmpty ? null : customEndpoint;

  @override
  Future<String?> readCustomApiKey() async => null;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer({required AIService svc, required _FakeProvidersService providers}) {
  return ProviderContainer(
    overrides: [
      aiServiceProvider.overrideWith((ref) async => svc),
      providersServiceProvider.overrideWith((ref) => providers),
    ],
  );
}

AIModel _ollamaModel(String name) =>
    AIModel(id: 'ollama_$name', provider: AIProvider.ollama, name: name, modelId: name, supportsStreaming: true);

AIModel _customModel(String id) => AIModel(id: id, provider: AIProvider.custom, name: id, modelId: id);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AvailableModelsNotifier', () {
    test('returns only static defaults when no endpoints configured', () async {
      final container = _makeContainer(svc: _FakeAIService(), providers: _FakeProvidersService());
      addTearDown(container.dispose);

      final result = await container.read(availableModelsProvider.future);
      expect(result.models, equals(AIModels.defaults));
      expect(result.failures, isEmpty);
      expect(result.failedProviders, isEmpty);
      expect(result.models.any((m) => m.provider == AIProvider.ollama), isFalse);
      expect(result.models.any((m) => m.provider == AIProvider.custom), isFalse);
    });

    test('includes ollama models when ollama URL is configured', () async {
      final ollamaModels = [_ollamaModel('llama3.2'), _ollamaModel('mistral')];
      final container = _makeContainer(
        svc: _FakeAIService(models: {AIProvider.ollama: ollamaModels}),
        providers: _FakeProvidersService(ollamaUrl: 'http://localhost:11434'),
      );
      addTearDown(container.dispose);

      final result = await container.read(availableModelsProvider.future);
      expect(result.models, containsAll(AIModels.defaults));
      expect(result.models, containsAll(ollamaModels));
      expect(result.failures, isEmpty);
      expect(result.failedProviders, isEmpty);
    });

    test('includes custom models when custom endpoint is configured', () async {
      final customModels = [_customModel('mistral-7b-instruct'), _customModel('codestral-22b')];
      final container = _makeContainer(
        svc: _FakeAIService(models: {AIProvider.custom: customModels}),
        providers: _FakeProvidersService(customEndpoint: 'http://localhost:1234/v1'),
      );
      addTearDown(container.dispose);

      final result = await container.read(availableModelsProvider.future);
      expect(result.models, containsAll(AIModels.defaults));
      expect(result.models, containsAll(customModels));
      expect(result.failures, isEmpty);
      expect(result.failedProviders, isEmpty);
    });

    test('includes models from both dynamic providers when both configured', () async {
      final ollamaModels = [_ollamaModel('llama3.2')];
      final customModels = [_customModel('mistral-7b-instruct')];
      final container = _makeContainer(
        svc: _FakeAIService(models: {AIProvider.ollama: ollamaModels, AIProvider.custom: customModels}),
        providers: _FakeProvidersService(
          ollamaUrl: 'http://localhost:11434',
          customEndpoint: 'http://localhost:1234/v1',
        ),
      );
      addTearDown(container.dispose);

      final result = await container.read(availableModelsProvider.future);
      expect(result.models, containsAll(AIModels.defaults));
      expect(result.models, containsAll(ollamaModels));
      expect(result.models, containsAll(customModels));
      expect(result.failures, isEmpty);
      expect(result.failedProviders, isEmpty);
    });

    test('ollama fetch failure classifies as unreachable for NetworkException', () async {
      final customModels = [_customModel('mistral-7b-instruct')];
      final container = _makeContainer(
        svc: _FakeAIService(
          models: {AIProvider.custom: customModels},
          errors: {AIProvider.ollama: const NetworkException('Ollama request failed')},
        ),
        providers: _FakeProvidersService(
          ollamaUrl: 'http://localhost:11434',
          customEndpoint: 'http://localhost:1234/v1',
        ),
      );
      addTearDown(container.dispose);

      final result = await container.read(availableModelsProvider.future);
      expect(result.models, containsAll(AIModels.defaults));
      expect(result.models, containsAll(customModels));
      expect(result.models.any((m) => m.provider == AIProvider.ollama), isFalse);
      expect(result.failures[AIProvider.ollama], isA<ModelProviderUnreachable>());
      expect(result.failures.containsKey(AIProvider.custom), isFalse);
    });

    test('custom fetch failure classifies as auth for AuthException', () async {
      final container = _makeContainer(
        svc: _FakeAIService(errors: {AIProvider.custom: const AuthException('bad key')}),
        providers: _FakeProvidersService(customEndpoint: 'http://localhost:1234/v1'),
      );
      addTearDown(container.dispose);

      final result = await container.read(availableModelsProvider.future);
      expect(result.failures[AIProvider.custom], isA<ModelProviderAuth>());
    });

    test('custom fetch failure classifies as malformedResponse for ParseException', () async {
      final container = _makeContainer(
        svc: _FakeAIService(errors: {AIProvider.custom: const ParseException('missing data field')}),
        providers: _FakeProvidersService(customEndpoint: 'http://localhost:1234/v1'),
      );
      addTearDown(container.dispose);

      final result = await container.read(availableModelsProvider.future);
      final failure = result.failures[AIProvider.custom];
      expect(failure, isA<ModelProviderMalformedResponse>());
      expect((failure as ModelProviderMalformedResponse).detail, 'missing data field');
    });

    test('generic exception classifies as unknown', () async {
      final container = _makeContainer(
        svc: _FakeAIService(errors: {AIProvider.ollama: Exception('boom')}),
        providers: _FakeProvidersService(ollamaUrl: 'http://localhost:11434'),
      );
      addTearDown(container.dispose);

      final result = await container.read(availableModelsProvider.future);
      expect(result.failures[AIProvider.ollama], isA<ModelProviderUnknown>());
    });

    test('custom fetch failure excludes custom models and reports failed provider', () async {
      final ollamaModels = [_ollamaModel('llama3.2')];
      final container = _makeContainer(
        svc: _FakeAIService(
          models: {AIProvider.ollama: ollamaModels},
          errors: {AIProvider.custom: const NetworkException('offline')},
        ),
        providers: _FakeProvidersService(
          ollamaUrl: 'http://localhost:11434',
          customEndpoint: 'http://localhost:1234/v1',
        ),
      );
      addTearDown(container.dispose);

      final result = await container.read(availableModelsProvider.future);
      expect(result.models, containsAll(AIModels.defaults));
      expect(result.models, containsAll(ollamaModels));
      expect(result.models.any((m) => m.provider == AIProvider.custom), isFalse);
      expect(result.failures[AIProvider.custom], isA<ModelProviderUnreachable>());
      expect(result.failures.containsKey(AIProvider.ollama), isFalse);
    });

    test('resolves to AsyncData with both providers in failures when both fetches fail', () async {
      final container = _makeContainer(
        svc: _FakeAIService(
          errors: {
            AIProvider.ollama: const NetworkException('offline'),
            AIProvider.custom: const NetworkException('offline'),
          },
        ),
        providers: _FakeProvidersService(
          ollamaUrl: 'http://localhost:11434',
          customEndpoint: 'http://localhost:1234/v1',
        ),
      );
      addTearDown(container.dispose);

      final result = await container.read(availableModelsProvider.future);
      expect(result.models, equals(AIModels.defaults));
      expect(result.failedProviders, containsAll([AIProvider.ollama, AIProvider.custom]));
    });

    test('refresh resolves to AsyncData with failures when a provider goes down', () async {
      final ollamaModels = [_ollamaModel('llama3.2')];
      final svc = _MutableFakeAIService(models: {AIProvider.ollama: ollamaModels});
      final container = _makeContainer(
        svc: svc,
        providers: _FakeProvidersService(ollamaUrl: 'http://localhost:11434'),
      );
      addTearDown(container.dispose);

      final first = await container.read(availableModelsProvider.future);
      expect(first.models, containsAll(ollamaModels));

      // Flip the fake to throw on the next fetch — simulates Ollama going
      // down between the initial build and a manual refresh tap. Per-provider
      // failures land in `failures` inline; AsyncData stays green.
      svc.errors = {AIProvider.ollama: const NetworkException('offline')};
      await container.read(availableModelsProvider.notifier).refresh();

      final state = container.read(availableModelsProvider);
      expect(state, isA<AsyncData>());
      expect(state.value, isNotNull);
      expect(state.value!.failures[AIProvider.ollama], isA<ModelProviderUnreachable>());
      // Provider-level outage is visible in the picker (inline failure row);
      // the stale-pill reflects that the previously-selected model is gone.
      expect(state.value!.models.any((m) => m.provider == AIProvider.ollama), isFalse);
    });
  });
}

/// Like `_FakeAIService` but allows tests to mutate `errors` between fetches
/// (used to simulate refresh-after-outage).
class _MutableFakeAIService extends Fake implements AIService {
  _MutableFakeAIService({this.models = const {}});

  Map<AIProvider, List<AIModel>> models;
  Map<AIProvider, Exception> errors = const {};

  @override
  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey) async {
    final err = errors[provider];
    if (err != null) throw err;
    return models[provider] ?? [];
  }
}
