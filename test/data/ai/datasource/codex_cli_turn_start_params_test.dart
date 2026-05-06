import 'package:code_bench_app/data/ai/datasource/codex_cli_datasource_process.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildCodexTurnStartParams', () {
    // Shape is dictated by Codex's TurnStartParams JSON schema (verify via
    // `codex app-server generate-json-schema --out <dir>`): `input` must be a
    // sequence of UserInput items, and `threadId` is required. A bare string
    // gives `invalid type: string "...", expected a sequence`.
    test('wraps prompt as a single text UserInput', () {
      final params = buildCodexTurnStartParams('thread-123', 'hello');
      expect(params['threadId'], 'thread-123');
      expect(params['input'], isA<List<dynamic>>());
      final input = params['input'] as List<dynamic>;
      expect(input, hasLength(1));
      expect(input.first, {'type': 'text', 'text': 'hello'});
    });

    test('includes threadId at the top level', () {
      final params = buildCodexTurnStartParams('abc', 'msg');
      expect(params.containsKey('threadId'), isTrue);
      expect(params['threadId'], 'abc');
    });

    test('preserves multiline and unicode prompt text verbatim', () {
      const prompt = 'line1\nline2\n你好 🚀';
      final params = buildCodexTurnStartParams('t', prompt);
      final first = (params['input'] as List<dynamic>).first as Map<String, dynamic>;
      expect(first['text'], prompt);
    });

    test('empty prompt still produces a single text item (not omitted)', () {
      final params = buildCodexTurnStartParams('t', '');
      final input = params['input'] as List<dynamic>;
      expect(input, hasLength(1));
      expect((input.first as Map<String, dynamic>)['text'], '');
    });
  });
}
