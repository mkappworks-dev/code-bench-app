import 'dart:async';

import 'package:code_bench_app/data/ai/models/auth_status.dart';
import 'package:code_bench_app/data/chat/models/transport_readiness.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/features/chat/notifiers/transport_readiness_notifier.dart';
import 'package:code_bench_app/features/providers/notifiers/ai_provider_status_notifier.dart';
import 'package:code_bench_app/features/providers/notifiers/providers_notifier.dart';
import 'package:code_bench_app/services/ai_provider/ai_provider_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _emptyPrefs = ApiKeysNotifierState(
  openai: '',
  anthropic: '',
  gemini: '',
  ollamaUrl: '',
  customEndpoint: '',
  customApiKey: '',
  anthropicTransport: 'api-key',
  openaiTransport: 'api-key',
);

const _httpPrefs = ApiKeysNotifierState(
  openai: 'sk-x',
  anthropic: 'sk-y',
  gemini: 'g-z',
  ollamaUrl: '',
  customEndpoint: '',
  customApiKey: '',
  anthropicTransport: 'api-key',
  openaiTransport: 'api-key',
);

const _claudeCliPrefs = ApiKeysNotifierState(
  openai: '',
  anthropic: '',
  gemini: '',
  ollamaUrl: '',
  customEndpoint: '',
  customApiKey: '',
  anthropicTransport: 'cli',
  openaiTransport: 'api-key',
);

class _FakeApiKeys extends ApiKeysNotifier {
  _FakeApiKeys(this._state);
  final ApiKeysNotifierState _state;
  @override
  Future<ApiKeysNotifierState> build() async => _state;
}

class _FakeStatus extends AiProviderStatusNotifier {
  _FakeStatus(this._entries);
  final List<ProviderEntry> _entries;
  @override
  Future<List<ProviderEntry>> build() async => _entries;
}

class _FakeStatusLoading extends AiProviderStatusNotifier {
  @override
  Future<List<ProviderEntry>> build() => Completer<List<ProviderEntry>>().future;
}

ProviderEntry _entry({required String id, ProviderStatus? status, AuthStatus? authStatus}) => ProviderEntry(
  id: id,
  displayName: id,
  status: status ?? ProviderStatus.available(version: '1', checkedAt: DateTime(2026)),
  authStatus: authStatus ?? const AuthStatus.authenticated(),
);

ProviderContainer _container({
  required AIModel model,
  required ApiKeysNotifierState prefs,
  List<ProviderEntry>? entries,
  bool entriesLoading = false,
}) {
  return ProviderContainer(
    overrides: [
      selectedModelProvider.overrideWithValue(model),
      apiKeysProvider.overrideWith(() => _FakeApiKeys(prefs)),
      if (entriesLoading)
        aiProviderStatusProvider.overrideWith(() => _FakeStatusLoading())
      else
        aiProviderStatusProvider.overrideWith(() => _FakeStatus(entries ?? const [])),
    ],
  );
}

void main() {
  test('CLI install ok + authenticated → ready', () async {
    final c = _container(
      model: AIModels.claude35Sonnet,
      prefs: _claudeCliPrefs,
      entries: [_entry(id: 'claude-cli')],
    );
    addTearDown(c.dispose);
    await c.read(apiKeysProvider.future);
    await c.read(aiProviderStatusProvider.future);
    expect(c.read(transportReadinessProvider), const TransportReadiness.ready());
  });

  test('CLI install ok + unauthenticated → signedOut(provider, signInCommand)', () async {
    final c = _container(
      model: AIModels.claude35Sonnet,
      prefs: _claudeCliPrefs,
      entries: [
        _entry(
          id: 'claude-cli',
          authStatus: const AuthStatus.unauthenticated(signInCommand: 'claude auth login'),
        ),
      ],
    );
    addTearDown(c.dispose);
    await c.read(apiKeysProvider.future);
    await c.read(aiProviderStatusProvider.future);

    final r = c.read(transportReadinessProvider);
    expect(r, isA<TransportSignedOut>());
    expect((r as TransportSignedOut).provider, 'claude-cli');
    expect(r.signInCommand, 'claude auth login');
  });

  test('CLI install missing → notInstalled(provider)', () async {
    final c = _container(
      model: AIModels.claude35Sonnet,
      prefs: _claudeCliPrefs,
      entries: [
        _entry(
          id: 'claude-cli',
          status: const ProviderStatus.unavailable(reason: 'gone', reasonKind: ProviderUnavailableReason.missing),
        ),
      ],
    );
    addTearDown(c.dispose);
    await c.read(apiKeysProvider.future);
    await c.read(aiProviderStatusProvider.future);

    final r = c.read(transportReadinessProvider);
    expect(r, isA<TransportNotInstalled>());
    expect((r as TransportNotInstalled).provider, 'claude-cli');
  });

  test('CLI auth unknown → ready (honest bias)', () async {
    final c = _container(
      model: AIModels.claude35Sonnet,
      prefs: _claudeCliPrefs,
      entries: [_entry(id: 'claude-cli', authStatus: const AuthStatus.unknown())],
    );
    addTearDown(c.dispose);
    await c.read(apiKeysProvider.future);
    await c.read(aiProviderStatusProvider.future);
    expect(c.read(transportReadinessProvider), const TransportReadiness.ready());
  });

  test('AsyncLoading providerEntries → unknown', () async {
    final c = _container(model: AIModels.claude35Sonnet, prefs: _claudeCliPrefs, entriesLoading: true);
    addTearDown(c.dispose);
    await c.read(apiKeysProvider.future);
    expect(c.read(transportReadinessProvider), const TransportReadiness.unknown());
  });

  test('HTTP transport, key configured → ready', () async {
    final c = _container(model: AIModels.claude35Sonnet, prefs: _httpPrefs, entries: const []);
    addTearDown(c.dispose);
    await c.read(apiKeysProvider.future);
    await c.read(aiProviderStatusProvider.future);
    expect(c.read(transportReadinessProvider), const TransportReadiness.ready());
  });

  test('HTTP transport, key empty → httpKeyMissing(provider)', () async {
    final c = _container(model: AIModels.claude35Sonnet, prefs: _emptyPrefs, entries: const []);
    addTearDown(c.dispose);
    await c.read(apiKeysProvider.future);
    await c.read(aiProviderStatusProvider.future);

    final r = c.read(transportReadinessProvider);
    expect(r, isA<TransportHttpKeyMissing>());
    expect((r as TransportHttpKeyMissing).provider, 'anthropic');
  });
}
