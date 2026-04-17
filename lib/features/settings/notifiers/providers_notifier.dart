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

  /// Returns `true` on success, `false` if any write fails.
  Future<bool> saveAll({
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
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] saveAll failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` on success, `false` if the delete fails.
  Future<bool> deleteKey(AIProvider provider) async {
    try {
      await ref.read(settingsServiceProvider).deleteApiKey(provider.name);
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] deleteKey failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` on success, `false` if the write fails.
  Future<bool> saveKey(AIProvider provider, String key) async {
    try {
      final svc = ref.read(settingsServiceProvider);
      if (key.trim().isNotEmpty) {
        await svc.writeApiKey(provider.name, key.trim());
      } else {
        await svc.deleteApiKey(provider.name);
      }
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] saveKey failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` on success, `false` if the write fails.
  Future<bool> saveOllamaUrl(String url) async {
    try {
      await ref.read(settingsServiceProvider).writeOllamaUrl(url.trim());
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] saveOllamaUrl failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` on success, `false` if the delete fails.
  Future<bool> clearOllamaUrl() async {
    try {
      await ref.read(settingsServiceProvider).deleteOllamaUrl();
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] clearOllamaUrl failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` on success, `false` if any write fails.
  Future<bool> saveCustomEndpoint(String url, String apiKey) async {
    try {
      final svc = ref.read(settingsServiceProvider);
      await svc.writeCustomEndpoint(url.trim());
      await svc.writeCustomApiKey(apiKey.trim());
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] saveCustomEndpoint failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` on success, `false` if the delete fails.
  Future<bool> clearCustomEndpoint() async {
    try {
      await ref.read(settingsServiceProvider).deleteCustomEndpoint();
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] clearCustomEndpoint failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` on success, `false` if the delete fails.
  Future<bool> clearCustomApiKey() async {
    try {
      await ref.read(settingsServiceProvider).deleteCustomApiKey();
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] clearCustomApiKey failed: $e\n$st');
      return false;
    }
  }
}
