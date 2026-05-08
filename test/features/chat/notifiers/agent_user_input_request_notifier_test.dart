import 'package:code_bench_app/data/ai/models/provider_runtime_event.dart';
import 'package:code_bench_app/features/chat/notifiers/agent_user_input_request_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial state is null', () {
    final container = ProviderContainer();
    expect(container.read(agentUserInputRequestProvider), isNull);
    container.dispose();
  });

  test('request stores the active request and emits it', () {
    final container = ProviderContainer();
    final n = container.read(agentUserInputRequestProvider.notifier);
    final req = const ProviderUserInputRequest(requestId: 'r1', prompt: 'q?');
    n.requestAndAwait(req);
    expect(container.read(agentUserInputRequestProvider), req);
    container.dispose();
  });

  test('submit completes the future with the answer and clears state', () async {
    final container = ProviderContainer();
    final n = container.read(agentUserInputRequestProvider.notifier);
    final fut = n.requestAndAwait(const ProviderUserInputRequest(requestId: 'r1', prompt: 'q?'));
    n.submit('hello');
    final answer = await fut;
    expect(answer, 'hello');
    expect(container.read(agentUserInputRequestProvider), isNull);
    container.dispose();
  });

  test('cancel completes the future with null and clears state', () async {
    final container = ProviderContainer();
    final n = container.read(agentUserInputRequestProvider.notifier);
    final fut = n.requestAndAwait(const ProviderUserInputRequest(requestId: 'r1', prompt: 'q?'));
    n.cancel();
    final answer = await fut;
    expect(answer, isNull);
    expect(container.read(agentUserInputRequestProvider), isNull);
    container.dispose();
  });
}
