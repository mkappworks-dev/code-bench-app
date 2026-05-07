import 'package:code_bench_app/data/ai/datasource/codex_cli_datasource_process.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildCodexThreadStartParams', () {
    test('cwd + resumeThreadId only when no developerInstructions', () {
      final params = buildCodexThreadStartParams(workingDirectory: '/tmp/proj', sessionId: 'sess');
      expect(params['cwd'], '/tmp/proj');
      expect(params['resumeThreadId'], 'sess');
      expect(params.containsKey('developerInstructions'), isFalse);
    });

    test('includes developerInstructions when non-empty', () {
      final params = buildCodexThreadStartParams(
        workingDirectory: '/tmp/proj',
        sessionId: 'sess',
        developerInstructions: 'be concise',
      );
      expect(params['developerInstructions'], 'be concise');
    });

    test('drops empty developerInstructions', () {
      final params = buildCodexThreadStartParams(
        workingDirectory: '/tmp/proj',
        sessionId: 'sess',
        developerInstructions: '',
      );
      expect(params.containsKey('developerInstructions'), isFalse);
    });

    test('omits resumeThreadId when sessionId empty', () {
      final params = buildCodexThreadStartParams(workingDirectory: '/tmp/proj', sessionId: '');
      expect(params.containsKey('resumeThreadId'), isFalse);
    });
  });
}
