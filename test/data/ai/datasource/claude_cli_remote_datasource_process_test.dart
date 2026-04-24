import 'package:code_bench_app/data/ai/datasource/claude_cli_remote_datasource_process.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/features/providers/notifiers/claude_cli_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const anthropicModel = AIModel(
    id: 'claude-sonnet-4-6',
    provider: AIProvider.anthropic,
    name: 'Claude Sonnet 4.6',
    modelId: 'claude-sonnet-4-6',
  );

  group('ClaudeCliRemoteDatasourceProcess.streamEvents — argv guards', () {
    test('non-UUID sessionId is rejected before Process.start', () async {
      final ds = ClaudeCliRemoteDatasourceProcess();
      final events = await ds
          .streamEvents(
            history: const [],
            prompt: 'hello',
            workingDirectory: '/tmp',
            sessionId: '--dangerously-skip-perms',
            isFirstTurn: true,
          )
          .toList();

      expect(events.length, 1);
      final ev = events.single;
      expect(ev, isA<StreamError>());
      final failure = (ev as StreamError).failure;
      expect(failure, isA<ClaudeCliUnknown>());
    });

    test('non-existent workingDirectory is rejected before Process.start', () async {
      final ds = ClaudeCliRemoteDatasourceProcess();
      final events = await ds
          .streamEvents(
            history: const [],
            prompt: 'hello',
            workingDirectory: '/this/path/does/not/exist/i/promise',
            sessionId: '11111111-1111-4111-8111-111111111111',
            isFirstTurn: true,
          )
          .toList();

      expect(events.length, 1);
      expect(events.single, isA<StreamError>());
    });

    test('relative workingDirectory is rejected', () async {
      final ds = ClaudeCliRemoteDatasourceProcess();
      final events = await ds
          .streamEvents(
            history: const [],
            prompt: 'hello',
            workingDirectory: 'relative/path',
            sessionId: '11111111-1111-4111-8111-111111111111',
            isFirstTurn: true,
          )
          .toList();

      expect(events.length, 1);
      expect(events.single, isA<StreamError>());
    });
  });

  group('ClaudeCliRemoteDatasourceProcess.testConnection', () {
    test('returns false when no detector is wired (defaults to not installed)', () async {
      final ds = ClaudeCliRemoteDatasourceProcess();
      final ok = await ds.testConnection(anthropicModel, '');
      expect(ok, isFalse);
    });
  });
}
