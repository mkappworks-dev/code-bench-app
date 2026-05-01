import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/core/errors/app_exception.dart';
import 'package:code_bench_app/data/ai/repository/api_key_test_repository.dart';
import 'package:code_bench_app/data/ai/repository/api_key_test_repository_impl.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/features/providers/notifiers/providers_actions.dart';
import 'package:code_bench_app/features/providers/notifiers/providers_failure.dart';
import 'package:code_bench_app/services/providers/providers_service.dart';

// ── Fake ApiKeyTestRepository ─────────────────────────────────────────────────

class _FakeApiKeyTestRepository extends Fake implements ApiKeyTestRepository {
  Object? _testError;
  bool _testResult = true;
  bool _customEndpointResult = true;

  void throwOnTest(Object error) => _testError = error;
  void setTestResult(bool result) => _testResult = result;
  void setCustomEndpointResult(bool result) => _customEndpointResult = result;

  @override
  Future<bool> testApiKey(AIProvider provider, String key) async {
    if (_testError != null) throw _testError!;
    return _testResult;
  }

  @override
  Future<bool> testOllamaUrl(String url) async {
    if (_testError != null) throw _testError!;
    return _testResult;
  }

  @override
  Future<bool> testCustomEndpoint(String url, String apiKey) async {
    if (_testError != null) throw _testError!;
    return _customEndpointResult;
  }
}

// ── Fake ProvidersService ─────────────────────────────────────────────────────

class _FakeProvidersService extends Fake implements ProvidersService {
  Object? _writeError;
  final Map<String, String> _keys = {};
  String? ollamaUrl;
  String? customEndpoint;
  String? customApiKey;

  void throwOnWrite(Object error) => _writeError = error;

  @override
  Future<void> writeApiKey(String provider, String key) async {
    if (_writeError != null) throw _writeError!;
    _keys[provider] = key;
  }

  @override
  Future<void> deleteApiKey(String provider) async {
    if (_writeError != null) throw _writeError!;
    _keys.remove(provider);
  }

  @override
  Future<void> writeOllamaUrl(String url) async {
    if (_writeError != null) throw _writeError!;
    ollamaUrl = url;
  }

  @override
  Future<void> deleteOllamaUrl() async {
    if (_writeError != null) throw _writeError!;
    ollamaUrl = null;
  }

  @override
  Future<void> writeCustomEndpoint(String url) async {
    if (_writeError != null) throw _writeError!;
    customEndpoint = url;
  }

  @override
  Future<void> deleteCustomEndpoint() async {
    if (_writeError != null) throw _writeError!;
    customEndpoint = null;
  }

  @override
  Future<void> writeCustomApiKey(String key) async {
    if (_writeError != null) throw _writeError!;
    customApiKey = key;
  }

  @override
  Future<void> deleteCustomApiKey() async {
    if (_writeError != null) throw _writeError!;
    customApiKey = null;
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _FakeApiKeyTestRepository fakeTestRepo;
  late _FakeProvidersService fakeSvc;

  setUp(() {
    fakeTestRepo = _FakeApiKeyTestRepository();
    fakeSvc = _FakeProvidersService();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        apiKeyTestRepositoryProvider.overrideWithValue(fakeTestRepo),
        providersServiceProvider.overrideWithValue(fakeSvc),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  // ── testApiKey ──────────────────────────────────────────────────────────────

  group('testApiKey', () {
    test('returns true on success', () async {
      fakeTestRepo.setTestResult(true);
      final c = makeContainer();
      final result = await c.read(providersActionsProvider.notifier).testApiKey(AIProvider.openai, 'valid-key');
      expect(result, isTrue);
    });

    test('returns false on exception (never throws)', () async {
      fakeTestRepo.throwOnTest(Exception('network error'));
      final c = makeContainer();
      final result = await c.read(providersActionsProvider.notifier).testApiKey(AIProvider.anthropic, 'bad-key');
      expect(result, isFalse);
    });
  });

  // ── testOllamaUrl ───────────────────────────────────────────────────────────

  group('testOllamaUrl', () {
    test('returns true when Ollama is reachable', () async {
      fakeTestRepo.setTestResult(true);
      final c = makeContainer();
      final result = await c.read(providersActionsProvider.notifier).testOllamaUrl('http://localhost:11434');
      expect(result, isTrue);
    });

    test('returns false on exception (never throws)', () async {
      fakeTestRepo.throwOnTest(Exception('connection refused'));
      final c = makeContainer();
      final result = await c.read(providersActionsProvider.notifier).testOllamaUrl('http://bad-host');
      expect(result, isFalse);
    });
  });

  // ── testCustomEndpoint ──────────────────────────────────────────────────────

  group('testCustomEndpoint', () {
    test('returns true when endpoint reachable', () async {
      fakeTestRepo.setCustomEndpointResult(true);
      final c = makeContainer();
      final result = await c.read(providersActionsProvider.notifier).testCustomEndpoint('http://localhost:1234/v1', '');
      expect(result, isTrue);
    });

    test('returns false when endpoint unreachable', () async {
      fakeTestRepo.setCustomEndpointResult(false);
      final c = makeContainer();
      final result = await c.read(providersActionsProvider.notifier).testCustomEndpoint('http://bad-host', 'key');
      expect(result, isFalse);
    });

    test('returns false on exception (never throws)', () async {
      fakeTestRepo.throwOnTest(Exception('timeout'));
      final c = makeContainer();
      final result = await c.read(providersActionsProvider.notifier).testCustomEndpoint('http://host', 'key');
      expect(result, isFalse);
    });
  });

  // ── saveApiKey ──────────────────────────────────────────────────────────────

  group('saveApiKey', () {
    test('happy path — state becomes AsyncData', () async {
      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).saveApiKey('openai', 'sk-valid');
      expect(c.read(providersActionsProvider), isA<AsyncData<void>>());
    });

    test('StorageException → ProvidersStorageFailed error', () async {
      fakeSvc.throwOnWrite(const StorageException('keychain denied'));
      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).saveApiKey('openai', 'sk-bad');
      expect(c.read(providersActionsProvider).error, isA<ProvidersStorageFailed>());
    });

    test('generic exception → ProvidersUnknownError', () async {
      fakeSvc.throwOnWrite(Exception('unexpected'));
      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).saveApiKey('anthropic', 'key');
      expect(c.read(providersActionsProvider).error, isA<ProvidersUnknownError>());
    });

    test('failure carries provider name in ProvidersStorageFailed', () async {
      fakeSvc.throwOnWrite(const StorageException('keychain denied'));
      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).saveApiKey('gemini', 'bad-key');
      final error = c.read(providersActionsProvider).error;
      expect(error, isA<ProvidersStorageFailed>());
      expect((error as ProvidersStorageFailed).providerName, equals('gemini'));
    });
  });

  // ── saveKey ─────────────────────────────────────────────────────────────────

  group('saveKey', () {
    test('writes non-empty key via writeApiKey', () async {
      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).saveKey(AIProvider.openai, 'sk-test');
      expect(fakeSvc._keys['openai'], 'sk-test');
      expect(c.read(providersActionsProvider), isA<AsyncData<void>>());
    });

    test('empty string calls deleteApiKey', () async {
      fakeSvc._keys['openai'] = 'existing';
      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).saveKey(AIProvider.openai, '');
      expect(fakeSvc._keys.containsKey('openai'), isFalse);
    });

    test('whitespace-only string calls deleteApiKey', () async {
      fakeSvc._keys['gemini'] = 'existing';
      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).saveKey(AIProvider.gemini, '   ');
      expect(fakeSvc._keys.containsKey('gemini'), isFalse);
    });

    test('StorageException → ProvidersStorageFailed', () async {
      fakeSvc.throwOnWrite(const StorageException('disk full'));
      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).saveKey(AIProvider.anthropic, 'key');
      expect(c.read(providersActionsProvider).error, isA<ProvidersStorageFailed>());
    });
  });

  // ── deleteKey ───────────────────────────────────────────────────────────────

  group('deleteKey', () {
    test('removes key from storage', () async {
      fakeSvc._keys['openai'] = 'sk-old';
      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).deleteKey(AIProvider.openai);
      expect(fakeSvc._keys.containsKey('openai'), isFalse);
      expect(c.read(providersActionsProvider), isA<AsyncData<void>>());
    });

    test('StorageException → ProvidersStorageFailed', () async {
      fakeSvc.throwOnWrite(const StorageException('keychain locked'));
      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).deleteKey(AIProvider.gemini);
      expect(c.read(providersActionsProvider).error, isA<ProvidersStorageFailed>());
    });
  });

  // ── saveAll ─────────────────────────────────────────────────────────────────

  group('saveAll', () {
    test('writes non-empty keys and deletes empty ones', () async {
      fakeSvc._keys['anthropic'] = 'old-key';
      final c = makeContainer();
      await c
          .read(providersActionsProvider.notifier)
          .saveAll(
            providerKeys: {AIProvider.openai: 'sk-new', AIProvider.anthropic: '', AIProvider.gemini: 'gm-key'},
            ollamaUrl: 'http://localhost:11434',
            customEndpoint: 'http://lm/v1',
            customApiKey: 'secret',
          );
      expect(fakeSvc._keys['openai'], 'sk-new');
      expect(fakeSvc._keys.containsKey('anthropic'), isFalse);
      expect(fakeSvc._keys['gemini'], 'gm-key');
      expect(fakeSvc.ollamaUrl, 'http://localhost:11434');
      expect(fakeSvc.customEndpoint, 'http://lm/v1');
      expect(fakeSvc.customApiKey, 'secret');
      expect(c.read(providersActionsProvider), isA<AsyncData<void>>());
    });

    test('StorageException → ProvidersStorageFailed', () async {
      fakeSvc.throwOnWrite(const StorageException('disk full'));
      final c = makeContainer();
      await c
          .read(providersActionsProvider.notifier)
          .saveAll(providerKeys: {AIProvider.openai: 'key'}, ollamaUrl: '', customEndpoint: '', customApiKey: '');
      expect(c.read(providersActionsProvider).error, isA<ProvidersStorageFailed>());
    });
  });
}
