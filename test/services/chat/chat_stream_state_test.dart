import 'package:code_bench_app/features/chat/notifiers/agent_failure.dart';
import 'package:code_bench_app/services/chat/chat_stream_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exhaustive switch covers every variant', () {
    String label(ChatStreamState s) => switch (s) {
      ChatStreamIdle() => 'idle',
      ChatStreamConnecting() => 'connecting',
      ChatStreamStreaming() => 'streaming',
      ChatStreamRetrying() => 'retrying',
      ChatStreamFailed() => 'failed',
      ChatStreamDone() => 'done',
    };

    expect(label(const ChatStreamState.idle()), 'idle');
    expect(label(const ChatStreamState.connecting(attempt: 1)), 'connecting');
    expect(label(const ChatStreamState.streaming()), 'streaming');
    expect(label(ChatStreamState.retrying(attempt: 2, nextDelay: const Duration(seconds: 1))), 'retrying');
    expect(label(ChatStreamState.failed(const AgentFailure.unknown('e'))), 'failed');
    expect(label(const ChatStreamState.done()), 'done');
  });
}
