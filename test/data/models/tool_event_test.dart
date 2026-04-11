import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/models/tool_event.dart';

void main() {
  test('ToolEvent serializes and deserializes', () {
    final event = ToolEvent(
      type: 'tool_use',
      toolName: 'read_file',
      input: {'path': '/foo/bar.dart'},
      output: 'content here',
      filePath: '/foo/bar.dart',
      durationMs: 123,
      tokensIn: 50,
      tokensOut: 10,
    );
    final json = event.toJson();
    final restored = ToolEvent.fromJson(json);
    expect(restored.toolName, 'read_file');
    expect(restored.durationMs, 123);
    expect(restored.input['path'], '/foo/bar.dart');
  });

  test('ToolEvent with null fields serializes cleanly', () {
    const event = ToolEvent(type: 'tool_result', toolName: 'write_file', input: {});
    final json = event.toJson();
    expect(json['output'], isNull);
  });
}
