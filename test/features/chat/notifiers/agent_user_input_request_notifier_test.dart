import 'package:code_bench_app/data/ai/models/provider_runtime_event.dart';
import 'package:code_bench_app/features/chat/notifiers/agent_user_input_request_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderUserInputRequest _req(String requestId, {String sessionId = 's1', String providerId = 'claude-cli'}) =>
    ProviderUserInputRequest(requestId: requestId, prompt: 'q?', providerId: providerId, sessionId: sessionId);

void main() {
  test('initial state is null per session', () {
    final container = ProviderContainer();
    expect(container.read(agentUserInputRequestProvider('s1')), isNull);
    expect(container.read(agentUserInputRequestProvider('s2')), isNull);
    container.dispose();
  });

  test('request stores the active request and emits it', () {
    final container = ProviderContainer();
    final n = container.read(agentUserInputRequestProvider('s1').notifier);
    final req = _req('r1');
    n.requestAndAwait(req);
    expect(container.read(agentUserInputRequestProvider('s1')), req);
    container.dispose();
  });

  test('submit completes the future with the answer and clears state', () async {
    final container = ProviderContainer();
    final n = container.read(agentUserInputRequestProvider('s1').notifier);
    final fut = n.requestAndAwait(_req('r1'));
    n.submit('hello');
    final result = await fut;
    expect(result, isA<AgentUserInputAnswer>());
    expect((result as AgentUserInputAnswer).text, 'hello');
    expect(container.read(agentUserInputRequestProvider('s1')), isNull);
    container.dispose();
  });

  test('cancel completes the future as cancelled and clears state', () async {
    final container = ProviderContainer();
    final n = container.read(agentUserInputRequestProvider('s1').notifier);
    final fut = n.requestAndAwait(_req('r1'));
    n.cancel();
    final result = await fut;
    expect(result, isA<AgentUserInputCancelled>());
    expect(container.read(agentUserInputRequestProvider('s1')), isNull);
    container.dispose();
  });

  test('a second requestAndAwait preempts the prior pending future', () async {
    final container = ProviderContainer();
    final n = container.read(agentUserInputRequestProvider('s1').notifier);
    final first = n.requestAndAwait(_req('r1'));
    final second = n.requestAndAwait(_req('r2'));
    final firstResult = await first;
    expect(firstResult, isA<AgentUserInputPreempted>());
    n.submit('answer');
    final secondResult = await second;
    expect(secondResult, isA<AgentUserInputAnswer>());
    expect((secondResult as AgentUserInputAnswer).text, 'answer');
    container.dispose();
  });

  test('two sessions are independent', () async {
    final container = ProviderContainer();
    final a = container.read(agentUserInputRequestProvider('sA').notifier);
    final b = container.read(agentUserInputRequestProvider('sB').notifier);
    final futA = a.requestAndAwait(_req('rA', sessionId: 'sA'));
    final futB = b.requestAndAwait(_req('rB', sessionId: 'sB'));
    a.submit('answer-A');
    b.cancel();
    expect((await futA as AgentUserInputAnswer).text, 'answer-A');
    expect(await futB, isA<AgentUserInputCancelled>());
    container.dispose();
  });
}
