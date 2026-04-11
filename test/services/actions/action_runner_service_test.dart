import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/models/project_action.dart';
import 'package:code_bench_app/services/actions/action_runner_service.dart';

void main() {
  test('ActionOutputState starts idle', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(actionOutputProvider);
    expect(state.status, ActionStatus.idle);
    expect(state.lines, isEmpty);
    expect(state.actionName, isNull);
  });

  test('ActionOutputNotifier.clear resets state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(actionOutputProvider.notifier).appendLine('hello', ActionStatus.running, 'test');
    container.read(actionOutputProvider.notifier).clear();
    final state = container.read(actionOutputProvider);
    expect(state.status, ActionStatus.idle);
    expect(state.lines, isEmpty);
  });

  test(
    'run captures output and settles on done for a successful short-lived command',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final dir = await Directory.systemTemp.createTemp('action_runner_test_');
      addTearDown(() => dir.delete(recursive: true));

      await container
          .read(actionOutputProvider.notifier)
          .run(const ProjectAction(name: 'echo', command: 'echo hello-race'), dir.path);

      final state = container.read(actionOutputProvider);
      // Regression: late-arriving stream events previously flipped status
      // back to running via copyWith. After Future.wait on both streams, a
      // short-lived command must settle on `done`.
      expect(state.status, ActionStatus.done);
      expect(state.exitCode, 0);
      expect(state.lines, contains('hello-race'));
    },
    skip: !Platform.isMacOS && !Platform.isLinux,
  ); // echo is POSIX-only

  test('run surfaces a clear message when the command is not found', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final dir = await Directory.systemTemp.createTemp('action_runner_test_');
    addTearDown(() => dir.delete(recursive: true));

    await container
        .read(actionOutputProvider.notifier)
        .run(const ProjectAction(name: 'missing', command: '/definitely/not/a/real/binary/xyz123'), dir.path);

    final state = container.read(actionOutputProvider);
    expect(state.status, ActionStatus.failed);
    expect(state.exitCode, -1);
    expect(
      state.lines.any((l) => l.contains('Command not found')),
      isTrue,
      reason: 'expected a user-friendly not-found message, got ${state.lines}',
    );
  });
}
