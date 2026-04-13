import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';

void main() {
  late Directory tmpDir;
  late ApplyRepositoryImpl repo;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('apply_repo_test_');
    repo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()));
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
  });

  group('ApplyRepositoryImpl.readFile', () {
    test('returns file content for existing file', () async {
      final filePath = '${tmpDir.path}/read_test.dart';
      File(filePath).writeAsStringSync('hello world');

      final content = await repo.readFile(filePath);
      expect(content, 'hello world');
    });

    test('throws PathNotFoundException for missing file', () async {
      await expectLater(() => repo.readFile('${tmpDir.path}/nonexistent.dart'), throwsA(isA<PathNotFoundException>()));
    });
  });

  group('ApplyRepositoryImpl.writeFile', () {
    test('creates file and writes content', () async {
      final filePath = '${tmpDir.path}/new_dir/new_file.dart';

      await repo.writeFile(filePath, 'content here');

      expect(File(filePath).existsSync(), isTrue);
      expect(File(filePath).readAsStringSync(), 'content here');
    });

    test('overwrites existing file', () async {
      final filePath = '${tmpDir.path}/overwrite.dart';
      File(filePath).writeAsStringSync('original');

      await repo.writeFile(filePath, 'updated');

      expect(File(filePath).readAsStringSync(), 'updated');
    });
  });

  group('ApplyRepositoryImpl.deleteFile', () {
    test('deletes an existing file', () async {
      final filePath = '${tmpDir.path}/to_delete.dart';
      File(filePath).writeAsStringSync('content');

      await repo.deleteFile(filePath);

      expect(File(filePath).existsSync(), isFalse);
    });
  });

  group('ApplyRepositoryImpl.gitCheckout', () {
    test('throws StateError when not inside a git repo', () async {
      final filePath = '${tmpDir.path}/file.dart';
      File(filePath).writeAsStringSync('content');

      await expectLater(() => repo.gitCheckout(filePath, tmpDir.path), throwsA(isA<StateError>()));
    });
  });
}
