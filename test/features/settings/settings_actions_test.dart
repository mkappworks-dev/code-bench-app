import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/core/errors/app_exception.dart';
import 'package:code_bench_app/data/models/ai_model.dart';
import 'package:code_bench_app/features/settings/notifiers/settings_actions_failure.dart';
import 'package:code_bench_app/features/settings/notifiers/settings_actions.dart';
import 'package:code_bench_app/services/ai/api_key_test_service.dart';
import 'package:code_bench_app/services/settings/settings_service.dart';

// ── Fake ApiKeyTestService ────────────────────────────────────────────────────

class _FakeApiKeyTestService extends Fake implements ApiKeyTestService {
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
}

// ── Fake SettingsService ──────────────────────────────────────────────────────

class _FakeSettingsService extends Fake implements SettingsService {
  Object? _writeError;

  void throwOnWrite(Object error) => _writeError = error;

  @override
  Future<void> writeApiKey(String provider, String key) async {
    if (_writeError != null) throw _writeError!;
  }

  // Stubs for methods SettingsActions may call during teardown / other paths.
  @override
  Future<void> markOnboardingCompleted() async {}

  @override
  Future<void> resetOnboarding() async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void main() {
  late _FakeApiKeyTestService fakeTestSvc;
  late _FakeSettingsService fakeSettingsSvc;

  setUp(() {
    fakeTestSvc = _FakeApiKeyTestService();
    fakeSettingsSvc = _FakeSettingsService();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        apiKeyTestServiceProvider.overrideWithValue(fakeTestSvc),
        settingsServiceProvider.overrideWithValue(fakeSettingsSvc),
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
      final result = await c.read(settingsActionsProvider.notifier).testApiKey(AIProvider.openai, 'valid-key');

      expect(result, isTrue);
    });

    test('returns false on exception (never throws)', () async {
      fakeTestSvc.throwOnTest(Exception('network error'));

      final c = makeContainer();
      final result = await c.read(settingsActionsProvider.notifier).testApiKey(AIProvider.anthropic, 'bad-key');

      expect(result, isFalse);
    });
  });

  // ── saveApiKey ──────────────────────────────────────────────────────────────

  group('saveApiKey', () {
    test('happy path — state becomes AsyncData', () async {
      final c = makeContainer();
      await c.read(settingsActionsProvider.notifier).saveApiKey('openai', 'sk-valid');

      expect(c.read(settingsActionsProvider), isA<AsyncData<void>>());
    });

    test('StorageException → SettingsStorageFailed error', () async {
      fakeSettingsSvc.throwOnWrite(const StorageException('keychain denied'));

      final c = makeContainer();
      await c.read(settingsActionsProvider.notifier).saveApiKey('openai', 'sk-bad');

      expect(c.read(settingsActionsProvider).error, isA<SettingsStorageFailed>());
    });

    test('generic exception → SettingsUnknownError', () async {
      fakeSettingsSvc.throwOnWrite(Exception('unexpected'));

      final c = makeContainer();
      await c.read(settingsActionsProvider.notifier).saveApiKey('anthropic', 'key');

      expect(c.read(settingsActionsProvider).error, isA<SettingsUnknownError>());
    });

    test('failure carries provider name in SettingsStorageFailed', () async {
      fakeSettingsSvc.throwOnWrite(const StorageException('keychain denied'));

      final c = makeContainer();
      await c.read(settingsActionsProvider.notifier).saveApiKey('gemini', 'bad-key');

      final error = c.read(settingsActionsProvider).error;
      expect(error, isA<SettingsStorageFailed>());
      expect((error as SettingsStorageFailed).providerName, equals('gemini'));
    });
  });
}
