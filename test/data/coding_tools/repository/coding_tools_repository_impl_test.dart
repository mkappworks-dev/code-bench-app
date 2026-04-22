import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/coding_tools_exceptions.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late CodingToolsRepositoryImpl repo;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('ct_repo_');
    repo = CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo());
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  test('readTextFile returns decoded UTF-8 content', () async {
    File(p.join(tmp.path, 'a.txt')).writeAsStringSync('héllo');
    expect(await repo.readTextFile(p.join(tmp.path, 'a.txt')), 'héllo');
  });

  test('readTextFile throws CodingToolNotTextEncodedException on invalid UTF-8 bytes', () async {
    File(p.join(tmp.path, 'bad.bin')).writeAsBytesSync([0xC3, 0x28]);
    await expectLater(
      () => repo.readTextFile(p.join(tmp.path, 'bad.bin')),
      throwsA(isA<CodingToolNotTextEncodedException>()),
    );
  });
}
