import 'package:code_bench_app/data/apply/repository/apply_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sha256OfString returns non-empty hex string', () {
    final hash = ApplyRepository.sha256OfString('hello world');
    expect(hash, isNotEmpty);
    expect(hash.length, 64);
  });

  test('same content produces same checksum', () {
    expect(ApplyRepository.sha256OfString('content'), equals(ApplyRepository.sha256OfString('content')));
  });

  test('different content produces different checksum', () {
    expect(ApplyRepository.sha256OfString('content a'), isNot(equals(ApplyRepository.sha256OfString('content b'))));
  });
}
