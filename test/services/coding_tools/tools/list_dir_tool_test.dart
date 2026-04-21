// test/services/coding_tools/tools/list_dir_tool_test.dart

import 'dart:io';

import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/services/coding_tools/tools/list_dir_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../_helpers/tool_test_helpers.dart';

void main() {
  late Directory projectDir;
  late ListDirTool tool;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('list_tool_');
    tool = ListDirTool(repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()));
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  test('non-recursive lists immediate children', () async {
    File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('x');
    Directory(p.join(projectDir.path, 'sub')).createSync();
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': '.', 'recursive': false}));
    expect(r, isA<CodingToolResultSuccess>());
    final out = (r as CodingToolResultSuccess).output;
    expect(out, contains('a.txt'));
    expect(out, contains('sub'));
  });

  test('missing path returns error', () async {
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': 'does_not_exist'}));
    expect(r, isA<CodingToolResultError>());
  });

  test('surfaces ctx.safePath errors (path escape sanity)', () async {
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': '../../..'}));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('outside'));
  });
}
