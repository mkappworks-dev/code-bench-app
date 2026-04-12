import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/utils/debug_logger.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/ai_model.dart';
import '../../services/ai/ai_service_factory.dart';
import '../../services/project/project_service.dart';
import '../../services/session/session_service.dart';
import '../../services/settings/settings_service.dart';

part 'settings_notifier.g.dart';

// ── API keys ──────────────────────────────────────────────────────────────────

class ApiKeysState {
  const ApiKeysState({
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

  ApiKeysState copyWith({
    String? openai,
    String? anthropic,
    String? gemini,
    String? ollamaUrl,
    String? customEndpoint,
    String? customApiKey,
  }) => ApiKeysState(
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
class ApiKeys extends _$ApiKeys {
  @override
  Future<ApiKeysState> build() async {
    final svc = ref.read(settingsServiceProvider);
    return ApiKeysState(
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
    ref.invalidate(aiServiceProvider);
  }

  Future<void> deleteKey(AIProvider provider) async {
    await ref.read(settingsServiceProvider).deleteApiKey(provider.name);
    ref.invalidate(aiServiceProvider);
  }
}

// ── General preferences ───────────────────────────────────────────────────────

class GeneralPrefsState {
  const GeneralPrefsState({required this.autoCommit, required this.deleteConfirmation, required this.terminalApp});

  final bool autoCommit;
  final bool deleteConfirmation;
  final String terminalApp;

  GeneralPrefsState copyWith({bool? autoCommit, bool? deleteConfirmation, String? terminalApp}) => GeneralPrefsState(
    autoCommit: autoCommit ?? this.autoCommit,
    deleteConfirmation: deleteConfirmation ?? this.deleteConfirmation,
    terminalApp: terminalApp ?? this.terminalApp,
  );
}

/// Loads general preferences on first watch and exposes setters.
/// Auto-disposes when the settings screen is not in view.
@riverpod
class GeneralPrefs extends _$GeneralPrefs {
  @override
  Future<GeneralPrefsState> build() async {
    final svc = ref.read(settingsServiceProvider);
    return GeneralPrefsState(
      autoCommit: await svc.getAutoCommit(),
      deleteConfirmation: await svc.getDeleteConfirmation(),
      terminalApp: await svc.getTerminalApp(),
    );
  }

  Future<void> setAutoCommit(bool value) async {
    await ref.read(settingsServiceProvider).setAutoCommit(value);
    _update((s) => s.copyWith(autoCommit: value));
  }

  Future<void> setDeleteConfirmation(bool value) async {
    await ref.read(settingsServiceProvider).setDeleteConfirmation(value);
    _update((s) => s.copyWith(deleteConfirmation: value));
  }

  Future<void> setTerminalApp(String value) async {
    await ref.read(settingsServiceProvider).setTerminalApp(value);
    _update((s) => s.copyWith(terminalApp: value));
  }

  /// Resets all general settings to their defaults and invalidates this
  /// provider so the settings UI rebuilds with fresh values.
  Future<void> restoreDefaults() async {
    final svc = ref.read(settingsServiceProvider);
    await svc.setAutoCommit(false);
    await svc.setTerminalApp('Terminal');
    await svc.setDeleteConfirmation(true);
    ref.invalidateSelf();
  }

  void _update(GeneralPrefsState Function(GeneralPrefsState) fn) {
    final current = state.value;
    if (current != null) state = AsyncData(fn(current));
  }
}

// ── Settings actions ──────────────────────────────────────────────────────────

/// Imperative actions that don't own observable state: wipe all data,
/// unarchive sessions, save a single API key, mark onboarding complete.
@Riverpod(keepAlive: true)
class SettingsActions extends _$SettingsActions {
  @override
  void build() {}

  Future<void> saveApiKey(String provider, String key) => ref.read(settingsServiceProvider).writeApiKey(provider, key);

  Future<void> unarchiveSession(String id) => ref.read(sessionServiceProvider).unarchiveSession(id);

  Future<void> markOnboardingCompleted() => ref.read(settingsServiceProvider).markOnboardingCompleted();

  Future<void> replayOnboarding() => ref.read(settingsServiceProvider).resetOnboarding();

  /// Wipes all user data in sequence. Returns a list of step names that
  /// failed (empty means full success). Each step is isolated so a keychain
  /// failure doesn't block the DB wipe.
  Future<List<String>> wipeAllData() async {
    final failures = <String>[];

    try {
      await ref.read(settingsServiceProvider).deleteAllSecureStorage();
    } catch (e, st) {
      _logWipeFailure('secure storage', e, st);
      failures.add('secure storage');
    }

    try {
      await ref.read(sessionServiceProvider).deleteAllSessionsAndMessages();
    } catch (e, st) {
      _logWipeFailure('chat history', e, st);
      failures.add('chat history');
    }

    try {
      await ref.read(projectServiceProvider).deleteAllProjects();
    } catch (e, st) {
      _logWipeFailure('projects', e, st);
      failures.add('projects');
    }

    try {
      await ref.read(settingsServiceProvider).resetOnboarding();
    } catch (e, st) {
      _logWipeFailure('onboarding flag', e, st);
      failures.add('onboarding flag');
    }

    ref.invalidate(aiServiceProvider);
    return failures;
  }

  void _logWipeFailure(String step, Object e, StackTrace st) {
    if (e is AppException && e.originalError != null) {
      dLog('[SettingsActions] wipe $step failed: ${e.message} (cause: ${e.originalError})\n$st');
    } else {
      dLog('[SettingsActions] wipe $step failed: $e\n$st');
    }
  }
}
