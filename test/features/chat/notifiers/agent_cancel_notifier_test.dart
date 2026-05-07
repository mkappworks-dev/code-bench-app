import 'package:code_bench_app/features/chat/notifiers/agent_cancel_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentCancelNotifier', () {
    test('starts empty; isCancelled is false for any session', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(agentCancelProvider), isEmpty);
      expect(container.read(agentCancelProvider.notifier).isCancelled('a'), isFalse);
    });

    test('request and clear toggle a single session in isolation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(agentCancelProvider.notifier);
      notifier.request('a');
      expect(notifier.isCancelled('a'), isTrue);
      notifier.clear('a');
      expect(notifier.isCancelled('a'), isFalse);
    });

    test('request on session A does not cancel session B', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(agentCancelProvider.notifier);
      notifier.request('a');

      expect(notifier.isCancelled('a'), isTrue);
      expect(notifier.isCancelled('b'), isFalse);
    });

    test('clear on session A leaves session B cancelled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(agentCancelProvider.notifier);
      notifier.request('a');
      notifier.request('b');
      notifier.clear('a');

      expect(notifier.isCancelled('a'), isFalse);
      expect(notifier.isCancelled('b'), isTrue);
    });

    test('repeated request and repeated clear are idempotent', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(agentCancelProvider.notifier);
      notifier.request('a');
      notifier.request('a');
      expect(notifier.isCancelled('a'), isTrue);

      notifier.clear('a');
      notifier.clear('a');
      expect(notifier.isCancelled('a'), isFalse);
    });
  });
}
