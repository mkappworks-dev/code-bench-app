import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/settings/settings_service.dart';

part 'providers_notifier.g.dart';

class ApiKeysNotifierState {
  const ApiKeysNotifierState({
    required this.openai,
    required this.anthropic,
    required this.gemini,
    required this.ollamaUrl,
    required this.customEndpoint,
    required this.customApiKey,
  });

  final String openai;
  final String anthropic;
  final String gemini;
  final String ollamaUrl;
  final String customEndpoint;
  final String customApiKey;

  ApiKeysNotifierState copyWith({
    String? openai,
    String? anthropic,
    String? gemini,
    String? ollamaUrl,
    String? customEndpoint,
    String? customApiKey,
  }) => ApiKeysNotifierState(
    openai: openai ?? this.openai,
    anthropic: anthropic ?? this.anthropic,
    gemini: gemini ?? this.gemini,
    ollamaUrl: ollamaUrl ?? this.ollamaUrl,
    customEndpoint: customEndpoint ?? this.customEndpoint,
    customApiKey: customApiKey ?? this.customApiKey,
  );
}

/// Loads API keys on first watch and exposes save/delete actions.
/// Auto-disposes when the settings screen is not in view.
@riverpod
class ApiKeysNotifier extends _$ApiKeysNotifier {
  @override
  Future<ApiKeysNotifierState> build() async {
    final svc = ref.read(settingsServiceProvider);
    return ApiKeysNotifierState(
      openai: await svc.readApiKey('openai') ?? '',
      anthropic: await svc.readApiKey('anthropic') ?? '',
      gemini: await svc.readApiKey('gemini') ?? '',
      ollamaUrl: await svc.readOllamaUrl() ?? ApiConstants.ollamaDefaultBaseUrl,
      customEndpoint: await svc.readCustomEndpoint() ?? '',
      customApiKey: await svc.readCustomApiKey() ?? '',
    );
  }

  Future<void> saveAll({
    required Map<AIProvider, String> providerKeys,
    required String ollamaUrl,
    required String customEndpoint,
    required String customApiKey,
  }) async {
    try {
      final svc = ref.read(settingsServiceProvider);
      for (final entry in providerKeys.entries) {
        final key = entry.value.trim();
        if (key.isNotEmpty) {
          await svc.writeApiKey(entry.key.name, key);
        } else {
          await svc.deleteApiKey(entry.key.name);
        }
      }
      if (ollamaUrl.trim().isNotEmpty) await svc.writeOllamaUrl(ollamaUrl.trim());
      await svc.writeCustomEndpoint(customEndpoint.trim());
      await svc.writeCustomApiKey(customApiKey.trim());
      ref.invalidate(aiRepositoryProvider);
    } catch (e, st) {
      dLog('[ApiKeysNotifier] saveAll failed: $e');
      if (ref.mounted) state = AsyncError(e, st);
    }
  }

  Future<void> deleteKey(AIProvider provider) async {
    try {
      await ref.read(settingsServiceProvider).deleteApiKey(provider.name);
      ref.invalidate(aiRepositoryProvider);
    } catch (e, st) {
      dLog('[ApiKeysNotifier] deleteKey failed: $e');
      if (ref.mounted) state = AsyncError(e, st);
    }
  }
}
