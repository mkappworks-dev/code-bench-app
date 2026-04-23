// lib/features/providers/notifiers/providers_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/ai/repository/ai_repository_impl.dart';
import '../../../services/providers/providers_service.dart';

part 'providers_notifier.g.dart';

class ApiKeysNotifierState {
  const ApiKeysNotifierState({
    required this.openai,
    required this.anthropic,
    required this.gemini,
    required this.ollamaUrl,
    required this.customEndpoint,
    required this.customApiKey,
    required this.anthropicTransport,
  });

  final String openai;
  final String anthropic;
  final String gemini;
  final String ollamaUrl;
  final String customEndpoint;
  final String customApiKey;

  /// Anthropic inference transport: `'api-key'` (Dio HTTP) or `'cli'`
  /// (Claude Code CLI via Process.start). Defaults to `'api-key'`.
  final String anthropicTransport;

  ApiKeysNotifierState copyWith({
    String? openai,
    String? anthropic,
    String? gemini,
    String? ollamaUrl,
    String? customEndpoint,
    String? customApiKey,
    String? anthropicTransport,
  }) => ApiKeysNotifierState(
    openai: openai ?? this.openai,
    anthropic: anthropic ?? this.anthropic,
    gemini: gemini ?? this.gemini,
    ollamaUrl: ollamaUrl ?? this.ollamaUrl,
    customEndpoint: customEndpoint ?? this.customEndpoint,
    customApiKey: customApiKey ?? this.customApiKey,
    anthropicTransport: anthropicTransport ?? this.anthropicTransport,
  );
}

@riverpod
class ApiKeysNotifier extends _$ApiKeysNotifier {
  @override
  Future<ApiKeysNotifierState> build() async {
    try {
      final svc = ref.watch(providersServiceProvider);
      return ApiKeysNotifierState(
        openai: await svc.readApiKey('openai') ?? '',
        anthropic: await svc.readApiKey('anthropic') ?? '',
        gemini: await svc.readApiKey('gemini') ?? '',
        ollamaUrl: await svc.readOllamaUrl() ?? '',
        customEndpoint: await svc.readCustomEndpoint() ?? '',
        customApiKey: await svc.readCustomApiKey() ?? '',
        anthropicTransport: await svc.readAnthropicTransport() ?? 'api-key',
      );
    } catch (e, st) {
      dLog('[ApiKeysNotifier] build failed: $e\n$st');
      rethrow;
    }
  }

  /// Persists the Anthropic inference transport choice and invalidates the
  /// AI repository so the new datasource wiring is picked up.
  Future<void> setAnthropicTransport(String value) async {
    assert(value == 'api-key' || value == 'cli', 'invalid transport: $value');
    final svc = ref.read(providersServiceProvider);
    await svc.writeAnthropicTransport(value);
    final current = await future;
    state = AsyncData(current.copyWith(anthropicTransport: value));
    ref.invalidate(aiRepositoryProvider);
  }
}
