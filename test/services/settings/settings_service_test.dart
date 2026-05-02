import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/mcp/repository/mcp_repository.dart';
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:code_bench_app/data/settings/repository/settings_repository.dart';
import 'package:code_bench_app/data/project/repository/project_repository.dart';
import 'package:code_bench_app/data/session/repository/session_repository.dart';
import 'package:code_bench_app/services/providers/providers_service.dart';
import 'package:code_bench_app/services/settings/settings_service.dart';
import 'package:code_bench_app/services/update/update_service.dart';

class _FakeSettingsRepo extends Fake implements SettingsRepository {
  bool resetOnboardingCalled = false;

  @override
  Future<void> resetOnboarding() async => resetOnboardingCalled = true;

  @override
  Future<void> markOnboardingCompleted() async {}
}

class _FakeProvidersService extends Fake implements ProvidersService {
  bool deletedAll = false;

  @override
  Future<void> deleteAll() async => deletedAll = true;
}

class _FakeSessionRepo extends Fake implements SessionRepository {
  bool deleted = false;
  @override
  Future<void> deleteAllSessionsAndMessages() async => deleted = true;
}

class _FakeProjectRepo extends Fake implements ProjectRepository {
  bool deleted = false;
  @override
  Future<void> deleteAllProjects() async => deleted = true;
}

class _FakeMcpRepo extends Fake implements McpRepository {
  bool deleted = false;
  @override
  Future<void> deleteAllServers() async => deleted = true;

  @override
  Future<List<McpServerConfig>> getAll() async => const [];
}

class _FakeUpdateService extends Fake implements UpdateService {
  bool sentinelCleared = false;
  @override
  Future<void> clearLastInstallStatus() async => sentinelCleared = true;
}

class _ThrowingProvidersService extends Fake implements ProvidersService {
  @override
  Future<void> deleteAll() => Future.error(Exception('disk full'));
}

class _ThrowingSessionRepo extends Fake implements SessionRepository {
  @override
  Future<void> deleteAllSessionsAndMessages() => Future.error(Exception('db error'));
}

class _ThrowingProjectRepo extends Fake implements ProjectRepository {
  @override
  Future<void> deleteAllProjects() => Future.error(Exception('db error'));
}

class _ThrowingMcpRepo extends Fake implements McpRepository {
  @override
  Future<void> deleteAllServers() => Future.error(Exception('db error'));
}

class _ThrowingOnboardingSettingsRepo extends Fake implements SettingsRepository {
  @override
  Future<void> resetOnboarding() => Future.error(Exception('storage error'));
}

class _ThrowingUpdateService extends Fake implements UpdateService {
  @override
  Future<void> clearLastInstallStatus() => Future.error(Exception('fs error'));
}

void main() {
  late _FakeSettingsRepo settings;
  late _FakeProvidersService providers;
  late _FakeSessionRepo session;
  late _FakeProjectRepo project;
  late _FakeMcpRepo mcp;
  late _FakeUpdateService update;
  late SettingsService svc;

  setUp(() {
    settings = _FakeSettingsRepo();
    providers = _FakeProvidersService();
    session = _FakeSessionRepo();
    project = _FakeProjectRepo();
    mcp = _FakeMcpRepo();
    update = _FakeUpdateService();
    svc = SettingsService(
      settings: settings,
      providers: providers,
      session: session,
      project: project,
      mcp: mcp,
      update: update,
    );
  });

  test('wipeAllData calls all repos and returns empty list on success', () async {
    final failures = await svc.wipeAllData();
    expect(failures, isEmpty);
    expect(providers.deletedAll, isTrue);
    expect(session.deleted, isTrue);
    expect(project.deleted, isTrue);
    expect(mcp.deleted, isTrue);
    expect(settings.resetOnboardingCalled, isTrue);
    expect(update.sentinelCleared, isTrue);
  });

  test('wipeAllData returns failed step names when secure storage throws', () async {
    final svcWithError = SettingsService(
      settings: settings,
      providers: _ThrowingProvidersService(),
      session: session,
      project: project,
      mcp: mcp,
      update: update,
    );
    final failures = await svcWithError.wipeAllData();
    expect(failures, contains('secure storage'));
    // All later steps must still run despite step 1 failing.
    expect(session.deleted, isTrue);
    expect(project.deleted, isTrue);
    expect(mcp.deleted, isTrue);
    expect(settings.resetOnboardingCalled, isTrue);
    expect(update.sentinelCleared, isTrue);
  });

  test('wipeAllData chat history failure is isolated — later steps still run', () async {
    final svcWithError = SettingsService(
      settings: settings,
      providers: providers,
      session: _ThrowingSessionRepo(),
      project: project,
      mcp: mcp,
      update: update,
    );
    final failures = await svcWithError.wipeAllData();
    expect(failures, contains('chat history'));
    expect(project.deleted, isTrue);
    expect(mcp.deleted, isTrue);
    expect(settings.resetOnboardingCalled, isTrue);
    expect(update.sentinelCleared, isTrue);
  });

  test('wipeAllData projects failure is isolated — later steps still run', () async {
    final svcWithError = SettingsService(
      settings: settings,
      providers: providers,
      session: session,
      project: _ThrowingProjectRepo(),
      mcp: mcp,
      update: update,
    );
    final failures = await svcWithError.wipeAllData();
    expect(failures, contains('projects'));
    expect(mcp.deleted, isTrue);
    expect(settings.resetOnboardingCalled, isTrue);
    expect(update.sentinelCleared, isTrue);
  });

  test('wipeAllData MCP failure is isolated — later steps still run', () async {
    final svcWithError = SettingsService(
      settings: settings,
      providers: providers,
      session: session,
      project: project,
      mcp: _ThrowingMcpRepo(),
      update: update,
    );
    final failures = await svcWithError.wipeAllData();
    expect(failures, contains('MCP servers'));
    expect(settings.resetOnboardingCalled, isTrue);
    expect(update.sentinelCleared, isTrue);
  });

  test('wipeAllData onboarding-flag failure is isolated — earlier steps complete and sentinel still clears', () async {
    final svcWithError = SettingsService(
      settings: _ThrowingOnboardingSettingsRepo(),
      providers: providers,
      session: session,
      project: project,
      mcp: mcp,
      update: update,
    );
    final failures = await svcWithError.wipeAllData();
    expect(failures, contains('onboarding flag'));
    expect(providers.deletedAll, isTrue);
    expect(session.deleted, isTrue);
    expect(project.deleted, isTrue);
    expect(mcp.deleted, isTrue);
    expect(update.sentinelCleared, isTrue);
  });

  test('wipeAllData previous-update-record failure is isolated — earlier steps complete', () async {
    final svcWithError = SettingsService(
      settings: settings,
      providers: providers,
      session: session,
      project: project,
      mcp: mcp,
      update: _ThrowingUpdateService(),
    );
    final failures = await svcWithError.wipeAllData();
    expect(failures, contains('previous-update record'));
    expect(providers.deletedAll, isTrue);
    expect(session.deleted, isTrue);
    expect(project.deleted, isTrue);
    expect(mcp.deleted, isTrue);
    expect(settings.resetOnboardingCalled, isTrue);
  });
}
