// lib/services/settings/settings_service.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/debug_logger.dart';
import '../../data/mcp/repository/mcp_repository.dart';
import '../../data/mcp/repository/mcp_repository_impl.dart';
import '../../data/project/repository/project_repository.dart';
import '../../data/project/repository/project_repository_impl.dart';
import '../../data/session/repository/session_repository.dart';
import '../../data/session/repository/session_repository_impl.dart';
import '../../data/settings/models/app_theme_preference.dart';
import '../../data/settings/repository/settings_repository.dart';
import '../../data/settings/repository/settings_repository_impl.dart';
import '../../services/providers/providers_service.dart';
import '../../services/update/update_service.dart';

part 'settings_service.g.dart';

@Riverpod(keepAlive: true)
SettingsService settingsService(Ref ref) {
  return SettingsService(
    settings: ref.watch(settingsRepositoryProvider),
    providers: ref.watch(providersServiceProvider),
    session: ref.watch(sessionRepositoryProvider),
    project: ref.watch(projectRepositoryProvider),
    mcp: ref.watch(mcpRepositoryProvider),
    update: ref.watch(updateServiceProvider),
  );
}

class SettingsService {
  SettingsService({
    required SettingsRepository settings,
    required ProvidersService providers,
    required SessionRepository session,
    required ProjectRepository project,
    required McpRepository mcp,
    required UpdateService update,
  }) : _settings = settings,
       _providers = providers,
       _session = session,
       _project = project,
       _mcp = mcp,
       _update = update;

  final SettingsRepository _settings;
  final ProvidersService _providers;
  final SessionRepository _session;
  final ProjectRepository _project;
  final McpRepository _mcp;
  final UpdateService _update;

  Future<bool> getAutoCommit() => _settings.getAutoCommit();
  Future<void> setAutoCommit(bool value) => _settings.setAutoCommit(value);
  Future<String> getTerminalApp() => _settings.getTerminalApp();
  Future<void> setTerminalApp(String value) => _settings.setTerminalApp(value);
  Future<bool> getDeleteConfirmation() => _settings.getDeleteConfirmation();
  Future<void> setDeleteConfirmation(bool value) => _settings.setDeleteConfirmation(value);
  Future<AppThemePreference> getThemeMode() => _settings.getThemeMode();
  Future<void> setThemeMode(AppThemePreference mode) => _settings.setThemeMode(mode);

  Future<void> markOnboardingCompleted() => _settings.markOnboardingCompleted();
  Future<void> resetOnboarding() => _settings.resetOnboarding();

  /// Wipes all user data in sequence. Returns step names that failed
  /// (empty = full success). Each step is isolated so a keychain failure
  /// does not block the DB wipe.
  Future<List<String>> wipeAllData() async {
    final failures = <String>[];

    try {
      await _providers.deleteAll();
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
      await _mcp.deleteAllServers();
    } catch (e, st) {
      _logWipeFailure('MCP servers', e, st);
      failures.add('MCP servers');
    }

    try {
      await _settings.resetOnboarding();
    } catch (e, st) {
      _logWipeFailure('onboarding flag', e, st);
      failures.add('onboarding flag');
    }

    try {
      await _update.clearLastInstallStatus();
    } catch (e, st) {
      _logWipeFailure('previous-update record', e, st);
      failures.add('previous-update record');
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
