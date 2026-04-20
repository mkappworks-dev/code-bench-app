import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';

void main() {
  test('success result carries output', () {
    const r = CodingToolResult.success('hello');
    expect(r, isA<CodingToolResultSuccess>());
    expect((r as CodingToolResultSuccess).output, 'hello');
  });

  test('error result carries message', () {
    const r = CodingToolResult.error('bad thing');
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, 'bad thing');
  });
}
