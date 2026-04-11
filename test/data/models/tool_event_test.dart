import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/models/tool_event.dart';

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

  group('ToolEvent legacy fromJson tolerance', () {
    test('legacy JSON with output → status success, minted id', () {
      final legacy = {
        'type': 'tool_use',
        'toolName': 'read_file',
        'input': {'path': 'x'},
        'output': 'ok',
        'durationMs': 50,
      };
      final restored = ToolEvent.fromJson(legacy);
      expect(restored.status, ToolStatus.success);
      expect(restored.id, startsWith('legacy-'));
    });

    test('legacy JSON with durationMs but no output → status success', () {
      // The earlier draft treated this as `error` — that mis-flagged
      // legitimately empty-output tools like write_file / silent shell
      // commands. The charitable inference is success (see
      // _normalizeLegacyToolEventJson for rationale).
      final legacy = <String, dynamic>{
        'type': 'tool_use',
        'toolName': 'run_command',
        'input': <String, dynamic>{},
        'durationMs': 200,
      };
      final restored = ToolEvent.fromJson(legacy);
      expect(restored.status, ToolStatus.success);
    });

    test('legacy JSON with neither → status running', () {
      final legacy = <String, dynamic>{'type': 'tool_use', 'toolName': 'bash', 'input': <String, dynamic>{}};
      final restored = ToolEvent.fromJson(legacy);
      expect(restored.status, ToolStatus.running);
    });

    test('legacy ids are unique across a tight decode loop', () {
      // Regression: a time-only `_legacyId()` collided when a batch of
      // legacy rows were decoded inside one microsecond during
      // loadHistory. Flutter widget keys depend on uniqueness, so this
      // invariant is load-bearing — if you break it, `ToolCallRow`
      // expansion state starts swapping between sibling rows.
      final ids = <String>{};
      for (var i = 0; i < 50; i++) {
        final restored = ToolEvent.fromJson(<String, dynamic>{
          'type': 'tool_use',
          'toolName': 'read_file',
          'input': <String, dynamic>{},
        });
        ids.add(restored.id);
      }
      expect(ids.length, 50, reason: 'legacy ids must be unique per decode');
    });
  });
}
