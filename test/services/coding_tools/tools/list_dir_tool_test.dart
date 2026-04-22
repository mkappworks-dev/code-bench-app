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

  test('recursive listing skips denied subtrees without walking into them', () async {
    // Create .git with 600 objects — more than _kMaxListEntries (500).
    // If the walk enters .git, the cap fires and real.txt is lost from output.
    final gitDir = Directory(p.join(projectDir.path, '.git'));
    await gitDir.create();
    for (var i = 0; i < 600; i++) {
      File(p.join(gitDir.path, 'obj$i')).writeAsStringSync('');
    }
    File(p.join(projectDir.path, 'real.txt')).writeAsStringSync('hello');

    final denylist = (
      segments: const <String>{'.git'},
      filenames: const <String>{},
      extensions: const <String>{},
      prefixes: const <String>{},
    );
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'path': '.', 'recursive': true}, denylist: denylist),
    );
    expect(r, isA<CodingToolResultSuccess>());
    final out = (r as CodingToolResultSuccess).output;
    expect(out, contains('real.txt'));
    expect(out, isNot(contains('obj0')));
    expect(out, isNot(contains('(truncated')));
  });
}
