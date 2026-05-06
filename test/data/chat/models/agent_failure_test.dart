import 'package:code_bench_app/data/chat/models/agent_failure.dart';
import 'package:code_bench_app/data/chat/models/transport_readiness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('networkExhausted carries the attempt count', () {
    const f = AgentFailure.networkExhausted(3);
    expect(f, isA<AgentNetworkExhausted>());
    expect((f as AgentNetworkExhausted).attempts, 3);
  });

  test('switch over AgentFailure is exhaustive across all variants', () {
    String name(AgentFailure f) => switch (f) {
      AgentIterationCapReached() => 'cap',
      AgentProviderDoesNotSupportTools() => 'nosupp',
      AgentStreamAbortedUnexpectedly() => 'aborted',
      AgentToolDispatchFailed() => 'tool',
      AgentNetworkExhausted() => 'net',
      AgentTransportNotReady() => 'transport',
      AgentUnknownError() => 'unknown',
    };
    expect(name(const AgentFailure.networkExhausted(3)), 'net');
    expect(
      name(
        AgentFailure.transportNotReady(
          const TransportReadiness.signedOut(provider: 'codex', signInCommand: 'codex login'),
        ),
      ),
      'transport',
    );
  });

  test('transportNotReady carries readiness', () {
    const readiness = TransportReadiness.signedOut(provider: 'codex', signInCommand: 'codex login');
    final f = AgentFailure.transportNotReady(readiness);
    expect((f as AgentTransportNotReady).readiness, readiness);
  });
}
