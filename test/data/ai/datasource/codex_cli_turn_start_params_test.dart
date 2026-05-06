import 'package:code_bench_app/data/ai/datasource/codex_cli_datasource_process.dart';
import 'package:code_bench_app/data/shared/session_settings.dart';
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

    test('includes model when it is Codex-compatible', () {
      final params = buildCodexTurnStartParams('thread-1', 'hi', modelId: 'gpt-5-codex');
      expect(params['model'], 'gpt-5-codex');
    });

    test('omits model when it is not Codex-compatible (e.g. gpt-4o)', () {
      // Codex with a ChatGPT account 400s on non-allowlisted models. Dropping
      // the field lets Codex pick its own default rather than failing the turn.
      final params = buildCodexTurnStartParams('thread-1', 'hi', modelId: 'gpt-4o');
      expect(params.containsKey('model'), isFalse);
    });

    test('isCodexCompatibleModel allowlist', () {
      expect(isCodexCompatibleModel('gpt-5-codex'), isTrue);
      expect(isCodexCompatibleModel('gpt-5'), isTrue);
      expect(isCodexCompatibleModel('o1'), isTrue);
      expect(isCodexCompatibleModel('o3-mini'), isTrue);
      expect(isCodexCompatibleModel('o4-mini'), isTrue);
      expect(isCodexCompatibleModel('codex-mini'), isTrue);
      expect(isCodexCompatibleModel('gpt-4o'), isFalse);
      expect(isCodexCompatibleModel('gpt-4o-mini'), isFalse);
      expect(isCodexCompatibleModel('claude-3-5-sonnet'), isFalse);
    });

    test('includes effort when provided', () {
      final params = buildCodexTurnStartParams('t', 'p', effort: ChatEffort.max);
      expect(params['effort'], 'xhigh');
    });

    test('includes sandboxPolicy + approvalPolicy when permission provided', () {
      final params = buildCodexTurnStartParams('t', 'p', permission: ChatPermission.fullAccess);
      expect(params['sandboxPolicy'], {'type': 'dangerFullAccess'});
      expect(params['approvalPolicy'], 'never');
    });

    test('omits all optional fields when nothing is provided', () {
      final params = buildCodexTurnStartParams('t', 'p');
      expect(params.containsKey('model'), isFalse);
      expect(params.containsKey('effort'), isFalse);
      expect(params.containsKey('sandboxPolicy'), isFalse);
      expect(params.containsKey('approvalPolicy'), isFalse);
    });
  });
}
