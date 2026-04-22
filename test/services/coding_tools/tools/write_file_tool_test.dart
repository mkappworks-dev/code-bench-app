// test/services/coding_tools/tools/write_file_tool_test.dart

import 'dart:io';

import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:code_bench_app/services/coding_tools/tools/write_file_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../_helpers/tool_test_helpers.dart';

void main() {
  late Directory projectDir;
  late WriteFileTool tool;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('write_tool_');
    final applyRepo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()));
    tool = WriteFileTool(applyService: ApplyService(repo: applyRepo));
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  test('creates new file and returns byte count', () async {
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'path': 'new.txt', 'content': 'hello world'}),
    );
    expect(r, isA<CodingToolResultSuccess>());
    expect(File(p.join(projectDir.path, 'new.txt')).readAsStringSync(), 'hello world');
  });

  test('overwrites existing file', () async {
    File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('old');
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': 'x.txt', 'content': 'new'}));
    expect(r, isA<CodingToolResultSuccess>());
    expect(File(p.join(projectDir.path, 'x.txt')).readAsStringSync(), 'new');
  });

  test('surfaces ctx.safePath errors (path escape sanity)', () async {
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'path': '../etc/passwd', 'content': 'x'}),
    );
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('outside'));
  });

  test('requires string content', () async {
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': 'x.txt', 'content': 42}));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('"content"'));
  });
}
