import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/debug_logger.dart';
import '../../data/project/repository/project_repository.dart';
import '../../data/project/repository/project_repository_impl.dart';
import '../../data/session/repository/session_repository.dart';
import '../../data/session/repository/session_repository_impl.dart';
import '../../data/settings/repository/settings_repository.dart';
import '../../data/settings/repository/settings_repository_impl.dart';

part 'settings_service.g.dart';

@Riverpod(keepAlive: true)
SettingsService settingsService(Ref ref) {
  return SettingsService(
    settings: ref.watch(settingsRepositoryProvider),
    session: ref.watch(sessionRepositoryProvider),
    project: ref.watch(projectRepositoryProvider),
  );
}

class SettingsService {
  SettingsService({
    required SettingsRepository settings,
    required SessionRepository session,
    required ProjectRepository project,
  }) : _settings = settings,
       _session = session,
       _project = project;

  final SettingsRepository _settings;
  final SessionRepository _session;
  final ProjectRepository _project;

  // ── API key delegation ────────────────────────────────────────────────────

  Future<String?> readApiKey(String provider) => _settings.readApiKey(provider);
  Future<void> writeApiKey(String provider, String key) => _settings.writeApiKey(provider, key);
  Future<void> deleteApiKey(String provider) => _settings.deleteApiKey(provider);
  Future<String?> readOllamaUrl() => _settings.readOllamaUrl();
  Future<void> writeOllamaUrl(String url) => _settings.writeOllamaUrl(url);
  Future<String?> readCustomEndpoint() => _settings.readCustomEndpoint();
  Future<void> writeCustomEndpoint(String url) => _settings.writeCustomEndpoint(url);
  Future<String?> readCustomApiKey() => _settings.readCustomApiKey();
  Future<void> writeCustomApiKey(String key) => _settings.writeCustomApiKey(key);
  Future<bool> getAutoCommit() => _settings.getAutoCommit();
  Future<void> setAutoCommit(bool value) => _settings.setAutoCommit(value);
  Future<String> getTerminalApp() => _settings.getTerminalApp();
  Future<void> setTerminalApp(String value) => _settings.setTerminalApp(value);
  Future<bool> getDeleteConfirmation() => _settings.getDeleteConfirmation();
  Future<void> setDeleteConfirmation(bool value) => _settings.setDeleteConfirmation(value);
  Future<void> markOnboardingCompleted() => _settings.markOnboardingCompleted();
  Future<void> resetOnboarding() => _settings.resetOnboarding();

  /// Wipes all user data in sequence. Returns step names that failed
  /// (empty = full success). Each step is isolated so a keychain failure
  /// does not block the DB wipe.
  Future<List<String>> wipeAllData() async {
    final failures = <String>[];

    try {
      await _settings.deleteAllSecureStorage();
    } catch (e, st) {
      _logWipeFailure('secure storage', e, st);
      failures.add('secure storage');
    }

    try {
      await _session.deleteAllSessionsAndMessages();
    } catch (e, st) {
      _logWipeFailure('chat history', e, st);
      failures.add('chat history');
    }

    try {
      await _project.deleteAllProjects();
    } catch (e, st) {
      _logWipeFailure('projects', e, st);
      failures.add('projects');
    }

    try {
      await _settings.resetOnboarding();
    } catch (e, st) {
      _logWipeFailure('onboarding flag', e, st);
      failures.add('onboarding flag');
    }

    return failures;
  }

  void _logWipeFailure(String step, Object e, StackTrace st) {
    if (e is AppException && e.originalError != null) {
      dLog('[SettingsService] wipe $step failed: ${e.message} (cause: ${e.originalError})\n$st');
    } else {
      dLog('[SettingsService] wipe $step failed: $e\n$st');
    }
  }
}
