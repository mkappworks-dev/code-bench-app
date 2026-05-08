import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/project/models/project.dart';
import 'package:code_bench_app/data/project/models/project_action.dart';
import 'package:code_bench_app/data/session/models/chat_session.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/services/project/project_service.dart';
import 'package:code_bench_app/services/session/session_service.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_actions.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_failure.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_notifier.dart';

class _FakeSessionService extends Fake implements SessionService {
  final List<String> deleteSessionsByProjectCalls = [];
  final List<String> archiveBulkCalls = [];
  final List<String> deleteBulkCalls = [];
  final Map<String, List<ChatSession>> sessionsByProject = {};

  @override
  Future<String> createSession({required AIModel model, String? title, String? projectId}) async => 'fake-session';

  @override
  Future<List<ChatSession>> getSessionsByProject(String projectId) async => sessionsByProject[projectId] ?? const [];

  @override
  Future<void> deleteSessionsByProject(String projectId) async {
    deleteSessionsByProjectCalls.add(projectId);
  }

  @override
  Future<List<String>> archiveActiveSessionsByProject(String projectId) async {
    archiveBulkCalls.add(projectId);
    final ids = (sessionsByProject[projectId] ?? const <ChatSession>[]).map((s) => s.sessionId).toList();
    sessionsByProject[projectId] = const [];
    return ids;
  }

  @override
  Future<List<String>> deleteActiveSessionsByProject(String projectId) async {
    deleteBulkCalls.add(projectId);
    final ids = (sessionsByProject[projectId] ?? const <ChatSession>[]).map((s) => s.sessionId).toList();
    sessionsByProject[projectId] = const [];
    return ids;
  }
}

class _FakeProjectService extends Fake implements ProjectService {
  Object? _addError;
  Object? _removeError;

  void throwOnAdd(Object error) => _addError = error;
  void throwOnRemove(Object error) => _removeError = error;

  @override
  Future<Project> addExistingFolder(String directoryPath) async {
    if (_addError != null) throw _addError!;
    return Project(id: 'fake-id', name: 'test', path: directoryPath, createdAt: DateTime(2024));
  }

  @override
  Future<void> removeProject(String projectId) async {
    if (_removeError != null) throw _removeError!;
  }

  @override
  Stream<List<Project>> watchAllProjects() => const Stream.empty();

  @override
  Future<Project> createNewFolder(String parentPath, String folderName) => throw UnimplementedError();

  @override
  Future<void> updateProjectActions(String projectId, List<ProjectAction> actions) => throw UnimplementedError();

  @override
  Future<void> refreshProjectStatuses() => throw UnimplementedError();

  @override
  Future<void> refreshProjectStatus(String projectId) => throw UnimplementedError();

  @override
  Future<void> relocateProject(String projectId, String newPath) => throw UnimplementedError();

  @override
  Future<void> deleteAllProjects() => throw UnimplementedError();
}

({ProviderContainer container, _FakeSessionService sessions}) _makeContainer(_FakeProjectService fakeService) {
  final fakeSessions = _FakeSessionService();
  final c = ProviderContainer(
    overrides: [
      projectServiceProvider.overrideWithValue(fakeService),
      sessionServiceProvider.overrideWith((ref) async => fakeSessions),
    ],
  );
  addTearDown(c.dispose);
  return (container: c, sessions: fakeSessions);
}

void main() {
  late _FakeProjectService fakeService;

  setUp(() {
    fakeService = _FakeProjectService();
  });

  group('addExistingFolder', () {
    test('happy path — state becomes AsyncData', () async {
      final c = _makeContainer(fakeService).container;
      await c.read(projectSidebarActionsProvider.notifier).addExistingFolder('/some/path');
      expect(c.read(projectSidebarActionsProvider), isA<AsyncData<void>>());
    });

    test('DuplicateProjectPathException → ProjectSidebarDuplicatePath', () async {
      fakeService.throwOnAdd(DuplicateProjectPathException('/some/path'));

      final c = _makeContainer(fakeService).container;
      await c.read(projectSidebarActionsProvider.notifier).addExistingFolder('/some/path');

      expect(c.read(projectSidebarActionsProvider).error, isA<ProjectSidebarDuplicatePath>());
    });

    test('ArgumentError → ProjectSidebarInvalidPath', () async {
      fakeService.throwOnAdd(ArgumentError('Directory does not exist: /bad/path'));

      final c = _makeContainer(fakeService).container;
      await c.read(projectSidebarActionsProvider.notifier).addExistingFolder('/bad/path');

      expect(c.read(projectSidebarActionsProvider).error, isA<ProjectSidebarInvalidPath>());
    });
  });

  group('removeProject', () {
    test('happy path — state becomes AsyncData', () async {
      final c = _makeContainer(fakeService).container;
      await c.read(projectSidebarActionsProvider.notifier).removeProject('id-1');
      expect(c.read(projectSidebarActionsProvider), isA<AsyncData<void>>());
    });

    test('exception → ProjectSidebarUnknownError', () async {
      fakeService.throwOnRemove(Exception('storage boom'));

      final c = _makeContainer(fakeService).container;
      await c.read(projectSidebarActionsProvider.notifier).removeProject('id-1');

      expect(c.read(projectSidebarActionsProvider).error, isA<ProjectSidebarUnknownError>());
    });

    test('deleteSessions=true → calls deleteSessionsByProject', () async {
      final harness = _makeContainer(fakeService);
      await harness.container.read(projectSidebarActionsProvider.notifier).removeProject('id-1', deleteSessions: true);
      expect(harness.sessions.deleteSessionsByProjectCalls, ['id-1']);
    });

    test('removing active project clears active session and project', () async {
      final harness = _makeContainer(fakeService);
      harness.container.read(activeProjectIdProvider.notifier).set('id-1');
      harness.container.read(activeSessionIdProvider.notifier).set('s1');

      await harness.container.read(projectSidebarActionsProvider.notifier).removeProject('id-1');

      expect(harness.container.read(activeProjectIdProvider), isNull);
      expect(harness.container.read(activeSessionIdProvider), isNull);
    });

    test('removing active project clears active state even when project delete fails', () async {
      fakeService.throwOnRemove(Exception('storage boom'));
      final harness = _makeContainer(fakeService);
      harness.container.read(activeProjectIdProvider.notifier).set('id-1');
      harness.container.read(activeSessionIdProvider.notifier).set('s1');

      await harness.container.read(projectSidebarActionsProvider.notifier).removeProject('id-1');

      expect(harness.container.read(activeProjectIdProvider), isNull);
      expect(harness.container.read(activeSessionIdProvider), isNull);
      expect(harness.container.read(projectSidebarActionsProvider).error, isA<ProjectSidebarUnknownError>());
    });

    test('removing non-active project leaves active state intact', () async {
      final harness = _makeContainer(fakeService);
      harness.container.read(activeProjectIdProvider.notifier).set('id-active');
      harness.container.read(activeSessionIdProvider.notifier).set('s-active');

      await harness.container.read(projectSidebarActionsProvider.notifier).removeProject('id-other');

      expect(harness.container.read(activeProjectIdProvider), 'id-active');
      expect(harness.container.read(activeSessionIdProvider), 's-active');
    });
  });

  group('bulk session actions', () {
    ChatSession session(String id, {String project = 'p1'}) => ChatSession(
      sessionId: id,
      title: id,
      modelId: 'm',
      providerId: 'p',
      projectId: project,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    test(
      'archiveAllSessionsForProject — calls transactional bulk archive and clears active id when included',
      () async {
        final harness = _makeContainer(fakeService);
        harness.sessions.sessionsByProject['p1'] = [session('s1'), session('s2')];
        harness.container.read(activeSessionIdProvider.notifier).set('s2');

        await harness.container.read(projectSidebarActionsProvider.notifier).archiveAllSessionsForProject('p1');

        expect(harness.sessions.archiveBulkCalls, ['p1']);
        expect(harness.container.read(activeSessionIdProvider), isNull);
      },
    );

    test('archiveAllSessionsForProject — leaves unrelated active session intact', () async {
      final harness = _makeContainer(fakeService);
      harness.sessions.sessionsByProject['p1'] = [session('s1')];
      harness.container.read(activeSessionIdProvider.notifier).set('elsewhere');

      await harness.container.read(projectSidebarActionsProvider.notifier).archiveAllSessionsForProject('p1');

      expect(harness.sessions.archiveBulkCalls, ['p1']);
      expect(harness.container.read(activeSessionIdProvider), 'elsewhere');
    });

    test('deleteAllSessionsForProject — calls transactional bulk delete and clears active id when included', () async {
      final harness = _makeContainer(fakeService);
      harness.sessions.sessionsByProject['p1'] = [session('s1'), session('s2')];
      harness.container.read(activeSessionIdProvider.notifier).set('s1');

      await harness.container.read(projectSidebarActionsProvider.notifier).deleteAllSessionsForProject('p1');

      expect(harness.sessions.deleteBulkCalls, ['p1']);
      expect(harness.container.read(activeSessionIdProvider), isNull);
    });

    test('deleteAllSessionsForProject — empty session list still calls bulk method', () async {
      final harness = _makeContainer(fakeService);

      await harness.container.read(projectSidebarActionsProvider.notifier).deleteAllSessionsForProject('p1');

      expect(harness.sessions.deleteBulkCalls, ['p1']);
      expect(harness.container.read(projectSidebarActionsProvider), isA<AsyncData<void>>());
    });
  });
}
