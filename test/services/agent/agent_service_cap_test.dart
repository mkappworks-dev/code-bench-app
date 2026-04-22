import 'package:code_bench_app/services/agent/agent_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cap = 50 * 1024;

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
  });
}
