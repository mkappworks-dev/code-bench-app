import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/project/models/project.dart';
import 'package:code_bench_app/data/project/models/project_action.dart';
import 'package:code_bench_app/services/project/project_service.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_actions.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_failure.dart';

// ── Fake ProjectService ───────────────────────────────────────────────────────

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

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer(_FakeProjectService fakeService) {
  final c = ProviderContainer(overrides: [projectServiceProvider.overrideWithValue(fakeService)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  late _FakeProjectService fakeService;

  setUp(() {
    fakeService = _FakeProjectService();
  });

  // ── addExistingFolder ────────────────────────────────────────────────────────

  group('addExistingFolder', () {
    test('happy path — state becomes AsyncData', () async {
      final c = _makeContainer(fakeService);
      await c.read(projectSidebarActionsProvider.notifier).addExistingFolder('/some/path');
      expect(c.read(projectSidebarActionsProvider), isA<AsyncData<void>>());
    });

    test('DuplicateProjectPathException → ProjectSidebarDuplicatePath', () async {
      fakeService.throwOnAdd(DuplicateProjectPathException('/some/path'));

      final c = _makeContainer(fakeService);
      await c.read(projectSidebarActionsProvider.notifier).addExistingFolder('/some/path');

      expect(c.read(projectSidebarActionsProvider).error, isA<ProjectSidebarDuplicatePath>());
    });

    test('ArgumentError → ProjectSidebarInvalidPath', () async {
      fakeService.throwOnAdd(ArgumentError('Directory does not exist: /bad/path'));

      final c = _makeContainer(fakeService);
      await c.read(projectSidebarActionsProvider.notifier).addExistingFolder('/bad/path');

      expect(c.read(projectSidebarActionsProvider).error, isA<ProjectSidebarInvalidPath>());
    });
  });

  // ── removeProject ────────────────────────────────────────────────────────────

  group('removeProject', () {
    test('happy path — state becomes AsyncData', () async {
      final c = _makeContainer(fakeService);
      await c.read(projectSidebarActionsProvider.notifier).removeProject('id-1');
      expect(c.read(projectSidebarActionsProvider), isA<AsyncData<void>>());
    });

    test('exception → ProjectSidebarUnknownError', () async {
      fakeService.throwOnRemove(Exception('storage boom'));

      final c = _makeContainer(fakeService);
      await c.read(projectSidebarActionsProvider.notifier).removeProject('id-1');

      expect(c.read(projectSidebarActionsProvider).error, isA<ProjectSidebarUnknownError>());
    });
  });
}
