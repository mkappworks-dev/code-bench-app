// test/services/coding_tools/tools/read_file_tool_test.dart

import 'dart:io';

import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/services/coding_tools/tools/read_file_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../_helpers/tool_test_helpers.dart';

void main() {
  late Directory projectDir;
  late ReadFileTool tool;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('read_tool_');
    tool = ReadFileTool(repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()));
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  test('returns success with content', () async {
    File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('hello');
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': 'a.txt'}));
    expect(r, isA<CodingToolResultSuccess>());
    expect((r as CodingToolResultSuccess).output, 'hello');
  });

  test('rejects files larger than 2MB', () async {
    final big = File(p.join(projectDir.path, 'big.bin'));
    big.writeAsBytesSync(List.filled(2 * 1024 * 1024 + 1, 0x41));
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': 'big.bin'}));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('File too large'));
  });

  test('rejects non-text files with a clear error', () async {
    File(p.join(projectDir.path, 'bad.bin')).writeAsBytesSync([0xC3, 0x28]);
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': 'bad.bin'}));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('not text-encoded'));
  });

  test('returns error for non-existent file', () async {
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': 'missing.txt'}));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('does not exist'));
  });

  test('surfaces ctx.safePath errors (path escape sanity)', () async {
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': '../../../etc/passwd'}));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('outside'));
  });
}
