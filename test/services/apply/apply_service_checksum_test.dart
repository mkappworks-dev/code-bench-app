import 'dart:io';

import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sha256OfString returns non-empty hex string', () {
    final hash = ApplyService.sha256OfString('hello world');
    expect(hash, isNotEmpty);
    expect(hash.length, 64); // SHA-256 = 32 bytes = 64 hex chars
  });

  test('same content produces same checksum', () {
    expect(ApplyService.sha256OfString('content'), equals(ApplyService.sha256OfString('content')));
  });

  test('different content produces different checksum', () {
    expect(ApplyService.sha256OfString('content a'), isNot(equals(ApplyService.sha256OfString('content b'))));
  });

  test('isExternallyModified returns false when checksums match', () async {
    final dir = await Directory.systemTemp.createTemp();
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/test.txt')..writeAsStringSync('same');
    final checksum = ApplyService.sha256OfString('same');
    expect(await ApplyService.isExternallyModified(file.path, checksum), isFalse);
  });

  test('isExternallyModified returns true when file changed', () async {
    final dir = await Directory.systemTemp.createTemp();
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/test.txt')..writeAsStringSync('changed');
    final checksum = ApplyService.sha256OfString('original');
    expect(await ApplyService.isExternallyModified(file.path, checksum), isTrue);
  });
}
