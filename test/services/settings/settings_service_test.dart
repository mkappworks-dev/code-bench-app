import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/settings/repository/settings_repository.dart';
import 'package:code_bench_app/data/project/repository/project_repository.dart';
import 'package:code_bench_app/data/session/repository/session_repository.dart';
import 'package:code_bench_app/services/settings/settings_service.dart';

class _FakeSettingsRepo extends Fake implements SettingsRepository {
  bool deletedSecureStorage = false;
  bool resetOnboardingCalled = false;

  @override
  Future<void> deleteAllSecureStorage() async => deletedSecureStorage = true;

  @override
  Future<void> resetOnboarding() async => resetOnboardingCalled = true;

  @override
  Future<void> markOnboardingCompleted() async {}

  @override
  Future<String?> readApiKey(String provider) async => null;

  @override
  Future<void> writeApiKey(String provider, String key) async {}
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

class _ThrowingSettingsRepo extends Fake implements SettingsRepository {
  @override
  Future<void> deleteAllSecureStorage() => Future.error(Exception('disk full'));
  @override
  Future<void> resetOnboarding() async {}
}

class _ThrowingSessionRepo extends Fake implements SessionRepository {
  bool deleted = false;
  @override
  Future<void> deleteAllSessionsAndMessages() => Future.error(Exception('db error'));
}

class _ThrowingProjectRepo extends Fake implements ProjectRepository {
  @override
  Future<void> deleteAllProjects() => Future.error(Exception('db error'));
}

class _ThrowingOnboardingSettingsRepo extends Fake implements SettingsRepository {
  bool deletedSecureStorage = false;
  @override
  Future<void> deleteAllSecureStorage() async => deletedSecureStorage = true;
  @override
  Future<void> resetOnboarding() => Future.error(Exception('storage error'));
}

void main() {
  late _FakeSettingsRepo settings;
  late _FakeSessionRepo session;
  late _FakeProjectRepo project;
  late SettingsService svc;

  setUp(() {
    settings = _FakeSettingsRepo();
    session = _FakeSessionRepo();
    project = _FakeProjectRepo();
    svc = SettingsService(settings: settings, session: session, project: project);
  });

  test('wipeAllData calls all three repos and returns empty list on success', () async {
    final failures = await svc.wipeAllData();
    expect(failures, isEmpty);
    expect(settings.deletedSecureStorage, isTrue);
    expect(session.deleted, isTrue);
    expect(project.deleted, isTrue);
    expect(settings.resetOnboardingCalled, isTrue);
  });

  test('wipeAllData returns failed step names when step 1 (secure storage) throws', () async {
    final svcWithError = SettingsService(settings: _ThrowingSettingsRepo(), session: session, project: project);
    final failures = await svcWithError.wipeAllData();
    expect(failures, contains('secure storage'));
  });

  test('wipeAllData step 2 failure is isolated — steps 3 and 4 still run', () async {
    final throwingSession = _ThrowingSessionRepo();
    final svcWithError = SettingsService(settings: settings, session: throwingSession, project: project);
    final failures = await svcWithError.wipeAllData();
    expect(failures, contains('chat history'));
    // Steps 3 and 4 must still complete despite step 2 failing.
    expect(project.deleted, isTrue);
    expect(settings.resetOnboardingCalled, isTrue);
  });

  test('wipeAllData step 3 failure is isolated — step 4 still runs', () async {
    final throwingProject = _ThrowingProjectRepo();
    final svcWithError = SettingsService(settings: settings, session: session, project: throwingProject);
    final failures = await svcWithError.wipeAllData();
    expect(failures, contains('projects'));
    // Step 4 must still complete despite step 3 failing.
    expect(settings.resetOnboardingCalled, isTrue);
  });

  test('wipeAllData step 4 failure is isolated — earlier steps are not affected', () async {
    final throwingOnboarding = _ThrowingOnboardingSettingsRepo();
    final svcWithError = SettingsService(settings: throwingOnboarding, session: session, project: project);
    final failures = await svcWithError.wipeAllData();
    expect(failures, contains('onboarding flag'));
    // Step 1 and earlier steps must have completed.
    expect(throwingOnboarding.deletedSecureStorage, isTrue);
    expect(session.deleted, isTrue);
    expect(project.deleted, isTrue);
  });
}
