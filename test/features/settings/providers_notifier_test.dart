import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/features/providers/notifiers/providers_notifier.dart';
import 'package:code_bench_app/services/providers/providers_service.dart';

class _FakeProvidersService extends Fake implements ProvidersService {
  final Map<String, String> _keys = {};
  String? ollamaUrl;
  String? customEndpoint;
  String? customApiKey;

  @override
  Future<String?> readApiKey(String provider) async => _keys[provider];
  @override
  Future<String?> readOllamaUrl() async => ollamaUrl;
  @override
  Future<String?> readCustomEndpoint() async => customEndpoint;
  @override
  Future<String?> readCustomApiKey() async => customApiKey;
}

class _ThrowingProvidersService extends Fake implements ProvidersService {
  @override
  Future<String?> readApiKey(String provider) => Future.error(Exception('keychain unavailable'));
  @override
  Future<String?> readOllamaUrl() => Future.error(Exception('keychain unavailable'));
  @override
  Future<String?> readCustomEndpoint() => Future.error(Exception('keychain unavailable'));
  @override
  Future<String?> readCustomApiKey() => Future.error(Exception('keychain unavailable'));
}

void main() {
  group('ApiKeysNotifier.build()', () {
    test('loads stored keys into state', () async {
      final fakeSvc = _FakeProvidersService()
        .._keys['openai'] = 'sk-open'
        .._keys['anthropic'] = 'sk-anth'
        ..ollamaUrl = 'http://localhost:11434'
        ..customEndpoint = 'http://custom/v1'
        ..customApiKey = 'custom-key';

      final c = ProviderContainer(overrides: [providersServiceProvider.overrideWithValue(fakeSvc)]);
      addTearDown(c.dispose);

      final state = await c.read(apiKeysProvider.future);
      expect(state.openai, 'sk-open');
      expect(state.anthropic, 'sk-anth');
      expect(state.gemini, '');
      expect(state.ollamaUrl, 'http://localhost:11434');
      expect(state.customEndpoint, 'http://custom/v1');
      expect(state.customApiKey, 'custom-key');
    });

    test('defaults to empty strings for missing keys', () async {
      final fakeSvc = _FakeProvidersService();
      final c = ProviderContainer(overrides: [providersServiceProvider.overrideWithValue(fakeSvc)]);
      addTearDown(c.dispose);

      final state = await c.read(apiKeysProvider.future);
      expect(state.openai, '');
      expect(state.ollamaUrl, '');
    });

    test('build() failure propagates as an error-carrying AsyncValue', () async {
      final c = ProviderContainer(overrides: [providersServiceProvider.overrideWithValue(_ThrowingProvidersService())]);
      addTearDown(c.dispose);

      // Attach a subscription to keep the provider alive through the async build.
      final sub = c.listen<AsyncValue<ApiKeysNotifierState>>(apiKeysProvider, (prev, next) {});
      addTearDown(sub.close);

      // Pump the event loop so the async build can fail.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = c.read(apiKeysProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<Exception>());
    });
  });
}
