import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';

void main() {
  test('success result carries output and no error', () {
    const r = CodingToolResult.success('hello');
    expect(r.isSuccess, isTrue);
    expect(r.output, 'hello');
    expect(r.error, isNull);
  });

  test('error result carries message and no output', () {
    const r = CodingToolResult.error('bad thing');
    expect(r.isSuccess, isFalse);
    expect(r.error, 'bad thing');
    expect(r.output, isNull);
  });
}
