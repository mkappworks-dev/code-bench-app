import 'package:code_bench_app/data/chat/models/agent_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('networkExhausted carries the attempt count', () {
    const f = AgentFailure.networkExhausted(3);
    expect(f, isA<AgentNetworkExhausted>());
    expect((f as AgentNetworkExhausted).attempts, 3);
  });

  test('switch over AgentFailure handles networkExhausted exhaustively', () {
    String name(AgentFailure f) => switch (f) {
      AgentIterationCapReached() => 'cap',
      AgentProviderDoesNotSupportTools() => 'nosupp',
      AgentStreamAbortedUnexpectedly() => 'aborted',
      AgentToolDispatchFailed() => 'tool',
      AgentNetworkExhausted() => 'net',
      AgentUnknownError() => 'unknown',
    };
    expect(name(const AgentFailure.networkExhausted(3)), 'net');
  });
}
