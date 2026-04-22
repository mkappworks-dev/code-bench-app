import 'package:code_bench_app/services/agent/agent_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cap = AgentService.kToolOutputCapBytes;

  group('AgentService.capContent', () {
    test('returns string unchanged when under cap', () {
      final s = 'a' * (cap - 1);
      expect(AgentService.capContent(s), equals(s));
    });

    test('returns string unchanged when exactly at cap', () {
      final s = 'a' * cap;
      expect(AgentService.capContent(s), equals(s));
    });

    test('truncates and appends notice when over cap (output path)', () {
      final s = 'a' * (cap + 100);
      final result = AgentService.capContent(s);
      expect(result.substring(0, cap), equals('a' * cap));
      expect(result[cap], equals('\n'));
      expect(
        result,
        contains('[Output truncated at 50 KB. Use grep to search for specific content or read a narrower file range.]'),
      );
    });

    test('truncates and appends notice when over cap (error path)', () {
      final s = 'e' * (cap + 1);
      final result = AgentService.capContent(s);
      expect(result.substring(0, cap), equals('e' * cap));
      expect(result[cap], equals('\n'));
      expect(
        result,
        contains('[Output truncated at 50 KB. Use grep to search for specific content or read a narrower file range.]'),
      );
    });

    test('returns empty string unchanged', () {
      expect(AgentService.capContent(''), equals(''));
    });

    test('handles multi-byte unicode: slices on byte boundary without splitting a code point', () {
      // Each '🎉' is 4 UTF-8 bytes. cap ~/ 4 emojis = exactly cap bytes, so
      // cap ~/ 4 + 1 emojis pushes one emoji past the byte cap.
      const emoji = '🎉';
      final count = cap ~/ 4 + 1;
      final s = emoji * count;
      final result = AgentService.capContent(s);
      expect(result, contains('[Output truncated at 50 KB.'));
      final head = result.split('\n[Output truncated').first;
      expect(head, equals(emoji * (cap ~/ 4)));
    });
  });
}
