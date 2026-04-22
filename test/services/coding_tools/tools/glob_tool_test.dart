import 'dart:io';

import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/services/coding_tools/tools/glob_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../_helpers/tool_test_helpers.dart';

void main() {
  late Directory tmp;
  late GlobTool tool;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('glob_tool_');
    tool = GlobTool(repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()));
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  Future<File> makeFile(String rel) async {
    final f = File(p.join(tmp.path, rel));
    await f.parent.create(recursive: true);
    await f.writeAsString('');
    return f;
  }

  test('returns matching paths, project-relative', () async {
    await makeFile('lib/a.dart');
    await makeFile('lib/b.dart');
    await makeFile('lib/c.yaml');

    final r = await tool.execute(fakeCtx(projectPath: tmp.path, args: {'pattern': 'lib/**/*.dart'}));
    expect(r, isA<CodingToolResultSuccess>());
    final out = (r as CodingToolResultSuccess).output;
    expect(out, contains('lib/a.dart'));
    expect(out, contains('lib/b.dart'));
    expect(out, isNot(contains('lib/c.yaml')));
    expect(out, contains('2 paths matched.'));
  });

  test('returns message when no paths match', () async {
    final r = await tool.execute(fakeCtx(projectPath: tmp.path, args: {'pattern': '**/*.nonexistent'}));
    expect(r, isA<CodingToolResultSuccess>());
    expect((r as CodingToolResultSuccess).output, contains('No paths matched.'));
  });

  test('rejects pattern containing ".."', () async {
    final r = await tool.execute(fakeCtx(projectPath: tmp.path, args: {'pattern': '../**/*.dart'}));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('".."'));
  });

  test('returns error when pattern arg is missing', () async {
    final r = await tool.execute(fakeCtx(projectPath: tmp.path, args: {}));
    expect(r, isA<CodingToolResultError>());
  });

  test('denylist filtering removes denied paths from results', () async {
    await makeFile('lib/a.dart');
    await makeFile('.env');
    await makeFile('node_modules/package.json');

    final denylist = (segments: {'node_modules'}, filenames: {'.env'}, extensions: <String>{}, prefixes: <String>{});

    final r = await tool.execute(fakeCtx(projectPath: tmp.path, args: {'pattern': '**/*'}, denylist: denylist));
    expect(r, isA<CodingToolResultSuccess>());
    final out = (r as CodingToolResultSuccess).output;
    expect(out, contains('lib/a.dart'));
    expect(out, isNot(contains('.env')));
    expect(out, isNot(contains('node_modules/package.json')));
  });
}
