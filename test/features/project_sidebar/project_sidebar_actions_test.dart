import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/models/project.dart';
import 'package:code_bench_app/features/project_sidebar/project_sidebar_actions.dart';
import 'package:code_bench_app/features/project_sidebar/project_sidebar_failure.dart';
import 'package:code_bench_app/services/project/project_service.dart';

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
      // addExistingFolder rethrows the typed failure so existing callers using
      // try/catch still work while the widget migration is pending.
      await expectLater(
        () => c.read(projectSidebarActionsProvider.notifier).addExistingFolder('/some/path'),
        throwsA(isA<ProjectSidebarDuplicatePath>()),
      );

      expect(c.read(projectSidebarActionsProvider).error, isA<ProjectSidebarDuplicatePath>());
    });

    test('ArgumentError → ProjectSidebarInvalidPath', () async {
      fakeService.throwOnAdd(ArgumentError('Directory does not exist: /bad/path'));

      final c = _makeContainer(fakeService);
      await expectLater(
        () => c.read(projectSidebarActionsProvider.notifier).addExistingFolder('/bad/path'),
        throwsA(isA<ProjectSidebarInvalidPath>()),
      );

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
