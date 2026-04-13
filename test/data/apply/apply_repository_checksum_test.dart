import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sha256OfString returns non-empty hex string', () {
    final hash = ApplyService.sha256OfString('hello world');
    expect(hash, isNotEmpty);
    expect(hash.length, 64);
  });

  test('same content produces same checksum', () {
    expect(ApplyService.sha256OfString('content'), equals(ApplyService.sha256OfString('content')));
  });

  test('different content produces different checksum', () {
    expect(ApplyService.sha256OfString('content a'), isNot(equals(ApplyService.sha256OfString('content b'))));
  });
}
