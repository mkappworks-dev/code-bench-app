import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/session/models/tool_event.dart';

void main() {
  group('ToolEvent round-trip', () {
    test('serializes and deserializes with all fields', () {
      final event = ToolEvent(
        id: 'tool_01ABC',
        type: 'tool_use',
        toolName: 'read_file',
        status: ToolStatus.success,
        input: {'path': '/foo/bar.dart'},
        output: 'content here',
        filePath: '/foo/bar.dart',
        durationMs: 123,
        tokensIn: 50,
        tokensOut: 10,
      );
      final json = event.toJson();
      final restored = ToolEvent.fromJson(json);
      expect(restored.id, 'tool_01ABC');
      expect(restored.toolName, 'read_file');
      expect(restored.status, ToolStatus.success);
      expect(restored.durationMs, 123);
      expect(restored.input['path'], '/foo/bar.dart');
    });

    test('defaults status to running and serializes cleanly with nulls', () {
      const event = ToolEvent(id: 'tool_02', type: 'tool_use', toolName: 'write_file', input: {});
      expect(event.status, ToolStatus.running);
      final json = event.toJson();
      expect(json['output'], isNull);
      expect(json['error'], isNull);
    });

    test('error status carries an error message', () {
      const event = ToolEvent(
        id: 'tool_03',
        type: 'tool_result',
        toolName: 'run_command',
        status: ToolStatus.error,
        error: 'exit code 1',
      );
      final json = event.toJson();
      final restored = ToolEvent.fromJson(json);
      expect(restored.status, ToolStatus.error);
      expect(restored.error, 'exit code 1');
    });

    test('cancelled status round-trips', () {
      const event = ToolEvent(id: 'tool_04', type: 'tool_use', toolName: 'search', status: ToolStatus.cancelled);
      final restored = ToolEvent.fromJson(event.toJson());
      expect(restored.status, ToolStatus.cancelled);
    });
  });
}
