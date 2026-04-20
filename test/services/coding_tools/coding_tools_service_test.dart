import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/services/coding_tools/coding_tools_service.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory projectDir;
  late CodingToolsService svc;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('ct_svc_');
    final repo = CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo());
    final applyRepo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()));
    final applySvc = ApplyService(repo: applyRepo);
    svc = CodingToolsService(repo: repo, applyService: applySvc);
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  group('read_file', () {
    test('returns success with content', () async {
      File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('hello');
      final r = await svc.execute(
        toolName: 'read_file',
        args: {'path': 'a.txt'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultSuccess>());
      expect((r as CodingToolResultSuccess).output, 'hello');
    });

    test('rejects path escape', () async {
      final r = await svc.execute(
        toolName: 'read_file',
        args: {'path': '../../../etc/passwd'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultError>());
      expect((r as CodingToolResultError).message, contains('outside'));
    });

    test('rejects files larger than 2MB', () async {
      final big = File(p.join(projectDir.path, 'big.bin'));
      big.writeAsBytesSync(List.filled(2 * 1024 * 1024 + 1, 0x41));
      final r = await svc.execute(
        toolName: 'read_file',
        args: {'path': 'big.bin'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultError>());
      expect((r as CodingToolResultError).message, contains('File too large'));
    });

    test('rejects non-text files with a clear error', () async {
      File(p.join(projectDir.path, 'bad.bin')).writeAsBytesSync([0xC3, 0x28]);
      final r = await svc.execute(
        toolName: 'read_file',
        args: {'path': 'bad.bin'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultError>());
      expect((r as CodingToolResultError).message, contains('not text-encoded'));
    });

    test('returns error for non-existent file', () async {
      final r = await svc.execute(
        toolName: 'read_file',
        args: {'path': 'missing.txt'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultError>());
      expect((r as CodingToolResultError).message, contains('does not exist'));
    });
  });

  group('list_dir', () {
    test('non-recursive lists immediate children', () async {
      File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('x');
      Directory(p.join(projectDir.path, 'sub')).createSync();
      final r = await svc.execute(
        toolName: 'list_dir',
        args: {'path': '.', 'recursive': false},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultSuccess>());
      final out = (r as CodingToolResultSuccess).output;
      expect(out, contains('a.txt'));
      expect(out, contains('sub'));
    });

    test('missing path returns error', () async {
      final r = await svc.execute(
        toolName: 'list_dir',
        args: {'path': 'does_not_exist'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultError>());
    });
  });

  group('write_file', () {
    test('creates new file and returns byte count', () async {
      final r = await svc.execute(
        toolName: 'write_file',
        args: {'path': 'new.txt', 'content': 'hello world'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultSuccess>());
      expect(File(p.join(projectDir.path, 'new.txt')).readAsStringSync(), 'hello world');
    });

    test('overwrites existing file', () async {
      File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('old');
      final r = await svc.execute(
        toolName: 'write_file',
        args: {'path': 'x.txt', 'content': 'new'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultSuccess>());
      expect(File(p.join(projectDir.path, 'x.txt')).readAsStringSync(), 'new');
    });
  });

  group('str_replace', () {
    test('replaces a unique occurrence', () async {
      File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('hello world');
      final r = await svc.execute(
        toolName: 'str_replace',
        args: {'path': 'x.txt', 'old_str': 'world', 'new_str': 'dart'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultSuccess>());
      expect(File(p.join(projectDir.path, 'x.txt')).readAsStringSync(), 'hello dart');
    });

    test('returns error when old_str not found', () async {
      File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('hello');
      final r = await svc.execute(
        toolName: 'str_replace',
        args: {'path': 'x.txt', 'old_str': 'missing', 'new_str': 'x'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultError>());
      expect((r as CodingToolResultError).message, contains('not found'));
    });

    test('returns error when old_str matches multiple times', () async {
      File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('ab ab ab');
      final r = await svc.execute(
        toolName: 'str_replace',
        args: {'path': 'x.txt', 'old_str': 'ab', 'new_str': 'cd'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultError>());
      expect((r as CodingToolResultError).message, contains('matches 3 times'));
    });
  });
}
