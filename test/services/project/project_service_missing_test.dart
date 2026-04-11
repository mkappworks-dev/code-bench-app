import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/datasources/local/app_database.dart';
import 'package:code_bench_app/data/models/project.dart';
import 'package:code_bench_app/services/project/project_service.dart';
import 'package:drift/native.dart';

void main() {
  late Directory tmpDir;
  late ProviderContainer container;
  late ProjectService service;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('project_missing_test_');
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWith((ref) => AppDatabase.forTesting(NativeDatabase.memory()))],
    );
    service = container.read(projectServiceProvider);
  });

  tearDown(() async {
    container.dispose();
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

  test('addExistingFolder throws DuplicateProjectPathException for the same path', () async {
    await service.addExistingFolder(tmpDir.path);
    await expectLater(service.addExistingFolder(tmpDir.path), throwsA(isA<DuplicateProjectPathException>()));
  });
}
