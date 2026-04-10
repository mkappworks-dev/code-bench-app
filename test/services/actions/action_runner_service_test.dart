import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/services/actions/action_runner_service.dart';

void main() {
  test('ActionOutputState starts idle', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(actionOutputNotifierProvider);
    expect(state.status, ActionStatus.idle);
    expect(state.lines, isEmpty);
    expect(state.actionName, isNull);
  });

  test('ActionOutputNotifier.clear resets state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(actionOutputNotifierProvider.notifier).appendLine('hello', ActionStatus.running, 'test');
    container.read(actionOutputNotifierProvider.notifier).clear();
    final state = container.read(actionOutputNotifierProvider);
    expect(state.status, ActionStatus.idle);
    expect(state.lines, isEmpty);
  });
}
