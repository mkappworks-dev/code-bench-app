import 'package:code_bench_app/data/ai/datasource/claude_cli_datasource_process.dart';
import 'package:code_bench_app/data/ai/models/provider_turn_settings.dart';
import 'package:code_bench_app/data/shared/session_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildClaudeCliArgs', () {
    test('no settings → minimal args with default permission-mode', () {
      final args = buildClaudeCliArgs(sessionId: 'session-1', prompt: 'hello', isFirstTurn: true);
      expect(args, contains('--permission-mode'));
      final permIdx = args.indexOf('--permission-mode');
      expect(args[permIdx + 1], 'bypassPermissions');
      expect(args, isNot(contains('--model')));
      expect(args, isNot(contains('--effort')));
      expect(args, isNot(contains('--append-system-prompt')));
      expect(args.last, 'hello');
    });

    test('full settings → every flag present', () {
      final args = buildClaudeCliArgs(
        sessionId: 'session-2',
        prompt: 'world',
        isFirstTurn: true,
        settings: const ProviderTurnSettings(
          modelId: 'sonnet',
          systemPrompt: 'be concise',
          mode: ChatMode.chat,
          effort: ChatEffort.high,
          permission: ChatPermission.askBefore,
        ),
      );
      expect(args, containsAllInOrder(['--model', 'sonnet']));
      // `--effort` is intentionally not forwarded to Claude CLI today; the
      // flag isn't reliably accepted across versions in the wild.
      expect(args, isNot(contains('--effort')));
      expect(args, containsAllInOrder(['--append-system-prompt', 'be concise']));
      expect(args, containsAllInOrder(['--permission-mode', 'default']));
    });

    test('effort is never forwarded as --effort even when set', () {
      final args = buildClaudeCliArgs(
        sessionId: 's',
        prompt: 'p',
        isFirstTurn: true,
        settings: const ProviderTurnSettings(effort: ChatEffort.max),
      );
      expect(args, isNot(contains('--effort')));
    });

    test('mode=plan overrides permission to plan', () {
      final args = buildClaudeCliArgs(
        sessionId: 's',
        prompt: 'p',
        isFirstTurn: true,
        settings: const ProviderTurnSettings(mode: ChatMode.plan, permission: ChatPermission.fullAccess),
      );
      expect(args, containsAllInOrder(['--permission-mode', 'plan']));
    });

    test('readOnly permission maps to plan', () {
      final args = buildClaudeCliArgs(
        sessionId: 's',
        prompt: 'p',
        isFirstTurn: true,
        settings: const ProviderTurnSettings(mode: ChatMode.chat, permission: ChatPermission.readOnly),
      );
      expect(args, containsAllInOrder(['--permission-mode', 'plan']));
    });

    test('isFirstTurn=false uses --resume', () {
      final args = buildClaudeCliArgs(sessionId: 'sess', prompt: 'hi', isFirstTurn: false);
      expect(args, containsAllInOrder(['--resume', 'sess']));
      expect(args, isNot(contains('--session-id')));
    });

    test('empty system prompt is dropped', () {
      final args = buildClaudeCliArgs(
        sessionId: 's',
        prompt: 'p',
        isFirstTurn: true,
        settings: const ProviderTurnSettings(systemPrompt: ''),
      );
      expect(args, isNot(contains('--append-system-prompt')));
    });

    test('flag-shaped modelId is rejected at the argv boundary', () {
      final args = buildClaudeCliArgs(
        sessionId: 's',
        prompt: 'p',
        isFirstTurn: true,
        settings: const ProviderTurnSettings(modelId: '--dangerously-skip-permissions'),
      );
      expect(args, isNot(contains('--model')));
      expect(args, isNot(contains('--dangerously-skip-permissions')));
    });
  });
}
