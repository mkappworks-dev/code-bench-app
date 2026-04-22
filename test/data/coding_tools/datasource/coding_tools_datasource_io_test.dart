import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/coding_tools_exceptions.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late CodingToolsDatasourceIo ds;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('ct_ds_');
    ds = CodingToolsDatasourceIo();
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  test('readFileBytes returns the file bytes', () async {
    final f = File(p.join(tmp.path, 'a.txt'))..writeAsStringSync('hello');
    final bytes = await ds.readFileBytes(f.path);
    expect(bytes.length, 5);
  });

  test('fileSizeBytes returns size without reading contents', () async {
    final f = File(p.join(tmp.path, 'a.txt'))..writeAsStringSync('hello');
    expect(await ds.fileSizeBytes(f.path), 5);
  });

  test('listDirectoryEntries returns children for non-recursive', () async {
    File(p.join(tmp.path, 'a.txt')).writeAsStringSync('x');
    Directory(p.join(tmp.path, 'sub')).createSync();
    final entries = await ds.listDirectoryEntries(tmp.path, recursive: false);
    final names = entries.map((e) => p.basename(e.path)).toSet();
    expect(names, {'a.txt', 'sub'});
  });

  test('listDirectoryEntries recursive walks subdirs (depth-capped inside service, not here)', () async {
    Directory(p.join(tmp.path, 'sub')).createSync();
    File(p.join(tmp.path, 'sub', 'b.txt')).writeAsStringSync('y');
    final entries = await ds.listDirectoryEntries(tmp.path, recursive: true);
    final names = entries.map((e) => p.basename(e.path)).toSet();
    expect(names.contains('sub'), isTrue);
    expect(names.contains('b.txt'), isTrue);
  });

  test('fileSizeBytes on missing path throws CodingToolsNotFoundException', () async {
    await expectLater(
      () => ds.fileSizeBytes(p.join(tmp.path, 'missing.txt')),
      throwsA(isA<CodingToolsNotFoundException>()),
    );
  });
}
