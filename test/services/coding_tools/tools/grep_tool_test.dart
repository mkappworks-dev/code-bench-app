import 'dart:io';

import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/models/grep_match.dart';
import 'package:code_bench_app/services/coding_tools/tools/grep_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import '../_helpers/tool_test_helpers.dart';

class _FakeDatasource implements GrepDatasource {
  _FakeDatasource(this._result);
  final GrepResult _result;
  int callCount = 0;
  String? lastPattern;
  List<String> lastExtensions = [];

  @override
  Future<GrepResult> grep({
    required String pattern,
    required String rootPath,
    int contextLines = 2,
    int maxMatches = 100,
    List<String> fileExtensions = const [],
  }) async {
    callCount++;
    lastPattern = pattern;
    lastExtensions = fileExtensions;
    return _result;
  }
}

GrepResult _singleMatch({String file = 'lib/foo.dart'}) => GrepResult(
  matches: [
    GrepMatch(
      file: file,
      lineNumber: 10,
      lineContent: '  final tool = byName[name];',
      contextBefore: ['  // load denylist', '  Future<CodingToolResult> execute() async {'],
      contextAfter: ['  if (tool == null) return CodingToolResult.error(...);', '  }'],
    ),
  ],
  totalFound: 1,
  wasCapped: false,
);

GrepResult _cappedResult() => GrepResult(
  matches: List.generate(
    100,
    (i) => GrepMatch(
      file: 'lib/a.dart',
      lineNumber: i + 1,
      lineContent: 'MATCH $i',
      contextBefore: const [],
      contextAfter: const [],
    ),
  ),
  totalFound: 101,
  wasCapped: true,
);

void main() {
  late Directory projectDir;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('grep_tool_');
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  test('formats single match with context lines and summary', () async {
    final tool = GrepTool(datasource: _FakeDatasource(_singleMatch()));
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'pattern': 'byName', 'path': '.'}));
    expect(r, isA<CodingToolResultSuccess>());
    final out = (r as CodingToolResultSuccess).output;
    expect(out, contains('lib/foo.dart:10:  final tool = byName[name];'));
    expect(out, contains('lib/foo.dart:9-  Future<CodingToolResult> execute() async {'));
    expect(out, contains('lib/foo.dart:11-  if (tool == null)'));
    expect(out, contains('Found 1 match.'));
  });

  test('formats capped result with truncation message', () async {
    final tool = GrepTool(datasource: _FakeDatasource(_cappedResult()));
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'pattern': 'MATCH', 'path': '.'}));
    final out = (r as CodingToolResultSuccess).output;
    expect(out, contains('100+ matches'));
    expect(out, contains('showing 100'));
  });

  test('returns "No matches found." when result is empty', () async {
    final tool = GrepTool(datasource: _FakeDatasource(const GrepResult(matches: [], totalFound: 0, wasCapped: false)));
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'pattern': 'NOPE', 'path': '.'}));
    expect((r as CodingToolResultSuccess).output, 'No matches found.');
  });

  test('returns error for invalid regex', () async {
    final tool = GrepTool(datasource: _FakeDatasource(_singleMatch()));
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'pattern': r'[bad', 'path': '.'}));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('Invalid regex'));
  });

  test('returns error when pattern is missing', () async {
    final tool = GrepTool(datasource: _FakeDatasource(_singleMatch()));
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': '.'}));
    expect(r, isA<CodingToolResultError>());
  });

  test('safePath rejects path escapes', () async {
    final tool = GrepTool(datasource: _FakeDatasource(_singleMatch()));
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'pattern': 'foo', 'path': '../../../etc'}),
    );
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('outside'));
  });

  test('passes extensions arg to datasource', () async {
    final fake = _FakeDatasource(_singleMatch());
    final tool = GrepTool(datasource: fake);
    await tool.execute(
      fakeCtx(
        projectPath: projectDir.path,
        args: {
          'pattern': 'foo',
          'path': '.',
          'extensions': ['dart'],
        },
      ),
    );
    expect(fake.callCount, 1);
  });

  test('denylist filtering removes denied files from results', () async {
    final fake = _FakeDatasource(
      GrepResult(
        matches: [
          GrepMatch(
            file: '.env',
            lineNumber: 1,
            lineContent: 'API_KEY=secret',
            contextBefore: const [],
            contextAfter: const [],
          ),
          GrepMatch(
            file: 'lib/foo.dart',
            lineNumber: 1,
            lineContent: 'API_KEY',
            contextBefore: const [],
            contextAfter: const [],
          ),
        ],
        totalFound: 2,
        wasCapped: false,
      ),
    );
    final tool = GrepTool(datasource: fake);
    final denylist = (
      segments: const <String>{},
      filenames: const {'.env'},
      extensions: const <String>{},
      prefixes: const <String>{},
    );
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'pattern': 'API_KEY', 'path': '.'}, denylist: denylist),
    );
    expect(fake.callCount, 1);
    expect(r, isA<CodingToolResultSuccess>());
    final out = (r as CodingToolResultSuccess).output;
    expect(out, isNot(contains('.env')));
    expect(out, contains('lib/foo.dart'));
  });

  test('strips extensions with invalid characters before passing to datasource', () async {
    final fake = _FakeDatasource(_singleMatch());
    final tool = GrepTool(datasource: fake);
    await tool.execute(
      fakeCtx(
        projectPath: projectDir.path,
        args: {
          'pattern': 'foo',
          'path': '.',
          'extensions': ['{dart,yaml}', 'dart'],
        },
      ),
    );
    expect(fake.lastExtensions, ['dart']); // {dart,yaml} was stripped
  });
}
