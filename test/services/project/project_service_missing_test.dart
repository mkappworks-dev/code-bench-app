import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/_core/app_database.dart';
import 'package:code_bench_app/data/project/models/project.dart';
import 'package:code_bench_app/data/project/repository/project_repository.dart';
import 'package:code_bench_app/data/project/repository/project_repository_impl.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late ProjectRepository service;
  late Directory tmpDir;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [appDatabaseProvider.overrideWith((ref) => db)]);
    service = container.read(projectRepositoryProvider);
  });

  tearDownAll(() async {
    container.dispose();
    await db.close();
  });

  setUp(() async {
    await db.projectDao.deleteAllProjects();
    tmpDir = await Directory.systemTemp.createTemp('project_missing_test_');
  });

  tearDown(() async {
    if (tmpDir.existsSync()) await tmpDir.delete(recursive: true);
  });

  test('addExistingFolder returns status=available for an existing folder', () async {
    final project = await service.addExistingFolder(tmpDir.path);
    expect(project.status, ProjectStatus.available);
  });

  test('watchAllProjects reports status=missing after the folder is deleted', () async {
    final added = await service.addExistingFolder(tmpDir.path);
    await tmpDir.delete(recursive: true);

    // Force a re-emission by touching the row.
    await service.refreshProjectStatuses();

    final list = await service.watchAllProjects().first;
    final reloaded = list.firstWhere((p) => p.id == added.id);
    expect(reloaded.status, ProjectStatus.missing);
  });

  test('relocateProject updates path and flips status back to available', () async {
    final added = await service.addExistingFolder(tmpDir.path);
    await tmpDir.delete(recursive: true);
    await service.refreshProjectStatuses();

    final newDir = await Directory.systemTemp.createTemp('project_relocate_test_');
    addTearDown(() async {
      if (newDir.existsSync()) await newDir.delete(recursive: true);
    });

    await service.relocateProject(added.id, newDir.path);

    final list = await service.watchAllProjects().first;
    final reloaded = list.firstWhere((p) => p.id == added.id);
    expect(reloaded.path, newDir.path);
    expect(reloaded.status, ProjectStatus.available);
  });

  test('refreshProjectStatus flips a single project to missing when its folder disappears', () async {
    final added = await service.addExistingFolder(tmpDir.path);
    await tmpDir.delete(recursive: true);

    await service.refreshProjectStatus(added.id);

    final list = await service.watchAllProjects().first;
    final reloaded = list.firstWhere((p) => p.id == added.id);
    expect(reloaded.status, ProjectStatus.missing);
  });

  test('refreshProjectStatus silently no-ops for an unknown project id', () async {
    // Should not throw even when the id is not in the DB.
    await service.refreshProjectStatus('does-not-exist');
  });
}
