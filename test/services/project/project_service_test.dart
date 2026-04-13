import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/models/project.dart';
import 'package:code_bench_app/data/models/project_action.dart';
import 'package:code_bench_app/data/project/repository/project_repository.dart';
import 'package:code_bench_app/services/project/project_service.dart';

class _FakeProjectRepo extends Fake implements ProjectRepository {
  final List<Project> _projects = [];

  @override
  Stream<List<Project>> watchAllProjects() => Stream.value(List.unmodifiable(_projects));

  @override
  Future<Project> addExistingFolder(String directoryPath) async {
    final p = Project(
      id: 'id-${_projects.length}',
      name: directoryPath.split('/').last,
      path: directoryPath,
      createdAt: DateTime(2026),
    );
    _projects.add(p);
    return p;
  }

  @override
  Future<Project> createNewFolder(String parentPath, String folderName) => addExistingFolder('$parentPath/$folderName');

  @override
  Future<void> relocateProject(String projectId, String newPath) async {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx >= 0) {
      final old = _projects[idx];
      _projects[idx] = Project(id: old.id, name: newPath.split('/').last, path: newPath, createdAt: old.createdAt);
    }
  }

  @override
  Future<void> removeProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
  }

  @override
  Future<void> updateProjectActions(String projectId, List<ProjectAction> actions) async {}

  @override
  Future<void> refreshProjectStatuses() async {}

  @override
  Future<void> refreshProjectStatus(String projectId) async {}

  @override
  Future<void> deleteAllProjects() async => _projects.clear();
}

void main() {
  late _FakeProjectRepo repo;
  late ProjectService svc;

  setUp(() {
    repo = _FakeProjectRepo();
    svc = ProjectService(repo: repo);
  });

  test('addExistingFolder returns project with correct path', () async {
    final p = await svc.addExistingFolder('/projects/myapp');
    expect(p.path, '/projects/myapp');
    expect(p.name, 'myapp');
  });

  test('addExistingFolder throws DuplicateProjectPathException on duplicate path', () async {
    await svc.addExistingFolder('/projects/myapp');
    expect(() => svc.addExistingFolder('/projects/myapp'), throwsA(isA<DuplicateProjectPathException>()));
  });

  test('createNewFolder throws DuplicateProjectPathException on duplicate path', () async {
    await svc.addExistingFolder('/projects/myapp');
    expect(() => svc.createNewFolder('/projects', 'myapp'), throwsA(isA<DuplicateProjectPathException>()));
  });

  test('relocateProject throws DuplicateProjectPathException when target path already taken', () async {
    await svc.addExistingFolder('/projects/alpha');
    await svc.addExistingFolder('/projects/beta');
    final alpha = repo._projects.first;

    expect(() => svc.relocateProject(alpha.id, '/projects/beta'), throwsA(isA<DuplicateProjectPathException>()));
  });

  test('relocateProject succeeds when target path is the same project', () async {
    await svc.addExistingFolder('/projects/alpha');
    final project = repo._projects.first;

    // Should not throw — relocating to its own path is a no-op
    await expectLater(svc.relocateProject(project.id, '/projects/alpha'), completes);
  });

  test('removeProject delegates to repository', () async {
    await svc.addExistingFolder('/projects/myapp');
    final id = repo._projects.first.id;
    await svc.removeProject(id);
    expect(repo._projects, isEmpty);
  });

  test('deleteAllProjects delegates to repository', () async {
    await svc.addExistingFolder('/projects/a');
    await svc.addExistingFolder('/projects/b');
    await svc.deleteAllProjects();
    expect(repo._projects, isEmpty);
  });
}
