import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_call.dart';

void main() {
  test('CodingToolCall holds id, name, and parsed args', () {
    const call = CodingToolCall(id: 'call_abc', name: 'read_file', args: {'path': 'lib/main.dart'});
    expect(call.id, 'call_abc');
    expect(call.name, 'read_file');
    expect(call.args['path'], 'lib/main.dart');
  });
}
