// lib/features/providers/notifiers/providers_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
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
    required this.openaiTransport,
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

  /// OpenAI inference transport: `'api-key'` (Dio HTTP) or `'cli'`
  /// (Codex CLI via Process.start). Defaults to `'api-key'`.
  final String openaiTransport;

  ApiKeysNotifierState copyWith({
    String? openai,
    String? anthropic,
    String? gemini,
    String? ollamaUrl,
    String? customEndpoint,
    String? customApiKey,
    String? anthropicTransport,
    String? openaiTransport,
  }) => ApiKeysNotifierState(
    openai: openai ?? this.openai,
    anthropic: anthropic ?? this.anthropic,
    gemini: gemini ?? this.gemini,
    ollamaUrl: ollamaUrl ?? this.ollamaUrl,
    customEndpoint: customEndpoint ?? this.customEndpoint,
    customApiKey: customApiKey ?? this.customApiKey,
    anthropicTransport: anthropicTransport ?? this.anthropicTransport,
    openaiTransport: openaiTransport ?? this.openaiTransport,
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
        openaiTransport: await svc.readOpenaiTransport() ?? 'api-key',
      );
    } catch (e, st) {
      dLog('[ApiKeysNotifier] build failed: $e\n$st');
      rethrow;
    }
  }
}
