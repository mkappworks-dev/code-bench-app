import 'dart:io';

import 'package:code_bench_app/data/coding_tools/datasource/grep_datasource_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late GrepDatasourceIo sut;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('grep_io_');
    sut = GrepDatasourceIo();
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  Future<void> writeFile(String name, String content) => File(p.join(tmp.path, name)).writeAsString(content);

  test('returns match with 2 lines of context', () async {
    await writeFile('a.dart', 'line1\nline2\nTARGET\nline4\nline5\n');
    final result = await sut.grep(pattern: 'TARGET', rootPath: tmp.path);
    expect(result.matches, hasLength(1));
    final m = result.matches.first;
    expect(m.lineNumber, 3);
    expect(m.lineContent, 'TARGET');
    expect(m.contextBefore, ['line1', 'line2']);
    expect(m.contextAfter, ['line4', 'line5']);
    expect(result.wasCapped, isFalse);
  });

  test('returns empty result when no match', () async {
    await writeFile('b.dart', 'no match here\n');
    final result = await sut.grep(pattern: 'NOPE', rootPath: tmp.path);
    expect(result.matches, isEmpty);
    expect(result.wasCapped, isFalse);
  });

  test('caps at maxMatches and sets wasCapped', () async {
    final content = List.generate(10, (i) => 'MATCH $i').join('\n');
    await writeFile('c.dart', content);
    final result = await sut.grep(pattern: 'MATCH', rootPath: tmp.path, maxMatches: 3);
    expect(result.matches, hasLength(3));
    expect(result.wasCapped, isTrue);
  });

  test('skips binary files (null byte)', () async {
    File(p.join(tmp.path, 'bin.bin')).writeAsBytesSync([0x00, 0x01, 0x02]);
    await writeFile('txt.dart', 'TARGET\n');
    final result = await sut.grep(pattern: 'TARGET', rootPath: tmp.path);
    expect(result.matches, hasLength(1));
    expect(result.matches.first.file, contains('txt.dart'));
  });

  test('skips non-UTF-8 files', () async {
    File(p.join(tmp.path, 'bad.dart')).writeAsBytesSync([0xC3, 0x28]); // invalid UTF-8
    await writeFile('good.dart', 'TARGET\n');
    final result = await sut.grep(pattern: 'TARGET', rootPath: tmp.path);
    expect(result.matches, hasLength(1));
  });

  test('filters by file extension', () async {
    await writeFile('match.dart', 'TARGET\n');
    await writeFile('match.yaml', 'TARGET\n');
    final result = await sut.grep(pattern: 'TARGET', rootPath: tmp.path, fileExtensions: ['yaml']);
    expect(result.matches, hasLength(1));
    expect(result.matches.first.file, contains('.yaml'));
  });

  test('returns project-relative file paths', () async {
    final sub = Directory(p.join(tmp.path, 'sub'))..createSync();
    File(p.join(sub.path, 'nested.dart')).writeAsStringSync('TARGET\n');
    final result = await sut.grep(pattern: 'TARGET', rootPath: tmp.path);
    expect(result.matches.first.file, 'sub/nested.dart');
  });

  test('throws FormatException on invalid regex', () async {
    await writeFile('d.dart', 'anything\n');
    expect(() => sut.grep(pattern: r'[invalid', rootPath: tmp.path), throwsA(isA<FormatException>()));
  });
}
