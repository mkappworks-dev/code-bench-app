import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/features/chat/notifiers/agent_cancel_notifier.dart';

void main() {
  test('AgentCancelNotifier starts false and toggles via request/clear', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(agentCancelProvider), isFalse);
    container.read(agentCancelProvider.notifier).request();
    expect(container.read(agentCancelProvider), isTrue);
    container.read(agentCancelProvider.notifier).clear();
    expect(container.read(agentCancelProvider), isFalse);
  });
}
