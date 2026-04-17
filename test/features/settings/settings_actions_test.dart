import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/core/errors/app_exception.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/services/providers/providers_service.dart';
import 'package:code_bench_app/features/providers/notifiers/providers_actions_failure.dart';
import 'package:code_bench_app/features/providers/notifiers/providers_actions.dart';
import 'package:code_bench_app/data/ai/repository/api_key_test_repository.dart';
import 'package:code_bench_app/data/ai/repository/api_key_test_repository_impl.dart';

// ── Fake ApiKeyTestRepository ─────────────────────────────────────────────────

class _FakeApiKeyTestRepository extends Fake implements ApiKeyTestRepository {
  Object? _testError;
  bool _testResult = true;

  void throwOnTest(Object error) => _testError = error;
  void setTestResult(bool result) => _testResult = result;

  @override
  Future<bool> testApiKey(AIProvider provider, String key) async {
    if (_testError != null) throw _testError!;
    return _testResult;
  }

  @override
  Future<bool> testOllamaUrl(String url) async => true;

  bool _customEndpointResult = true;

  void setCustomEndpointResult(bool result) => _customEndpointResult = result;

  @override
  Future<bool> testCustomEndpoint(String url, String apiKey) async {
    if (_testError != null) throw _testError!;
    return _customEndpointResult;
  }
}

// ── Fake ProvidersService ─────────────────────────────────────────────────────

class _FakeProvidersService extends Fake implements ProvidersService {
  Object? _writeError;

  void throwOnWrite(Object error) => _writeError = error;

  @override
  Future<void> writeApiKey(String provider, String key) async {
    if (_writeError != null) throw _writeError!;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void main() {
  late _FakeApiKeyTestRepository fakeTestSvc;
  late _FakeProvidersService fakeProvidersSvc;

  setUp(() {
    fakeTestSvc = _FakeApiKeyTestRepository();
    fakeProvidersSvc = _FakeProvidersService();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        apiKeyTestRepositoryProvider.overrideWithValue(fakeTestSvc),
        providersServiceProvider.overrideWithValue(fakeProvidersSvc),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  // ── testApiKey ──────────────────────────────────────────────────────────────

  group('testApiKey', () {
    test('returns true on success', () async {
      fakeTestSvc.setTestResult(true);

      final c = makeContainer();
      final result = await c.read(providersActionsProvider.notifier).testApiKey(AIProvider.openai, 'valid-key');

      expect(result, isTrue);
    });

    test('returns false on exception (never throws)', () async {
      fakeTestSvc.throwOnTest(Exception('network error'));

      final c = makeContainer();
      final result = await c.read(providersActionsProvider.notifier).testApiKey(AIProvider.anthropic, 'bad-key');

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
      fakeProvidersSvc.throwOnWrite(const StorageException('keychain denied'));

      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).saveApiKey('openai', 'sk-bad');

      expect(c.read(providersActionsProvider).error, isA<ProvidersStorageFailed>());
    });

    test('generic exception → ProvidersUnknownError', () async {
      fakeProvidersSvc.throwOnWrite(Exception('unexpected'));

      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).saveApiKey('anthropic', 'key');

      expect(c.read(providersActionsProvider).error, isA<ProvidersUnknownError>());
    });

    test('failure carries provider name in ProvidersStorageFailed', () async {
      fakeProvidersSvc.throwOnWrite(const StorageException('keychain denied'));

      final c = makeContainer();
      await c.read(providersActionsProvider.notifier).saveApiKey('gemini', 'bad-key');

      final error = c.read(providersActionsProvider).error;
      expect(error, isA<ProvidersStorageFailed>());
      expect((error as ProvidersStorageFailed).providerName, equals('gemini'));
    });
  });

  // ── testCustomEndpoint ──────────────────────────────────────────────────────

  group('testCustomEndpoint', () {
    test('returns true when endpoint reachable', () async {
      fakeTestSvc.setCustomEndpointResult(true);

      final c = makeContainer();
      final result = await c.read(providersActionsProvider.notifier).testCustomEndpoint('http://localhost:1234/v1', '');

      expect(result, isTrue);
    });

    test('returns false when endpoint unreachable', () async {
      fakeTestSvc.setCustomEndpointResult(false);

      final c = makeContainer();
      final result = await c.read(providersActionsProvider.notifier).testCustomEndpoint('http://bad-host', 'key');

      expect(result, isFalse);
    });

    test('returns false on exception (never throws)', () async {
      fakeTestSvc.throwOnTest(Exception('timeout'));

      final c = makeContainer();
      final result = await c.read(providersActionsProvider.notifier).testCustomEndpoint('http://host', 'key');

      expect(result, isFalse);
    });
  });
}
