import 'package:code_bench_app/data/session/models/permission_request.dart';
import 'package:code_bench_app/features/chat/utils/permission_request_preview.dart';
import 'package:flutter_test/flutter_test.dart';

PermissionRequest _req(String toolName, Map<String, dynamic> input) =>
    PermissionRequest(toolEventId: 'te', toolName: toolName, summary: '', input: input);

void main() {
  group('PermissionRequestPreview.buildLines', () {
    group('write_file', () {
      test('returns up to 5 lines', () {
        final lines = PermissionRequestPreview.buildLines(_req('write_file', {'content': 'a\nb\nc'}));
        expect(lines, ['a', 'b', 'c']);
      });

      test('appends ellipsis when content exceeds 5 lines', () {
        final content = List.generate(7, (i) => 'line$i').join('\n');
        final lines = PermissionRequestPreview.buildLines(_req('write_file', {'content': content}))!;
        expect(lines.length, 6);
        expect(lines.last, '…');
      });

      test('returns null for empty content', () {
        expect(PermissionRequestPreview.buildLines(_req('write_file', {'content': ''})), isNull);
      });
    });

    group('str_replace', () {
      test('returns old lines prefixed - and new lines prefixed +', () {
        final lines = PermissionRequestPreview.buildLines(
          _req('str_replace', {'old_str': 'foo\nbar', 'new_str': 'baz'}),
        );
        expect(lines, ['- foo', '- bar', '+ baz']);
      });

      test('returns null for empty old_str', () {
        expect(PermissionRequestPreview.buildLines(_req('str_replace', {'old_str': '', 'new_str': 'x'})), isNull);
      });
    });

    group('bash', () {
      test('returns sanitized command as single-element list', () {
        final lines = PermissionRequestPreview.buildLines(_req('bash', {'command': 'echo hello'}));
        expect(lines, ['echo hello']);
      });

      test('returns null for empty command', () {
        expect(PermissionRequestPreview.buildLines(_req('bash', {'command': ''})), isNull);
      });
    });

    test('returns null for unknown tool', () {
      expect(PermissionRequestPreview.buildLines(_req('read_file', {'path': 'foo.dart'})), isNull);
    });
  });

  group('PermissionRequestPreview.sanitizeCommand', () {
    test('passes through normal commands unchanged', () {
      expect(PermissionRequestPreview.sanitizeCommand('echo hello'), 'echo hello');
    });

    test('strips ANSI escape sequences', () {
      expect(PermissionRequestPreview.sanitizeCommand('\x1b[31mred\x1b[0m'), 'red');
    });

    test('strips bidi override characters', () {
      // U+202E RIGHT-TO-LEFT OVERRIDE — constructed at runtime to avoid lint
      final rtlo = String.fromCharCode(0x202e);
      expect(PermissionRequestPreview.sanitizeCommand('safe${rtlo}dangerous'), 'safedangerous');
    });

    test('strips non-printable controls but preserves \\n and \\t', () {
      expect(PermissionRequestPreview.sanitizeCommand('a\x07b\nc\td'), 'ab\nc\td');
    });
  });
}
