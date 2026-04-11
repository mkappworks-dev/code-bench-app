import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/features/chat/notifiers/ask_question_notifier.dart';

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('starts with no answers', () {
    final c = makeContainer();
    final state = c.read(askQuestionProvider);
    expect(state.answers, isEmpty);
  });

  test('setAnswer stores keyed by sessionId + stepIndex', () {
    final c = makeContainer();
    c
        .read(askQuestionProvider.notifier)
        .setAnswer(sessionId: 'sess1', stepIndex: 0, selectedOption: 'Option A', freeText: null);
    final state = c.read(askQuestionProvider);
    expect(state.answers[('sess1', 0)]?.selectedOption, 'Option A');
  });

  test('getAnswer returns null when no answer stored', () {
    final c = makeContainer();
    final notifier = c.read(askQuestionProvider.notifier);
    expect(notifier.getAnswer('sess1', 0), isNull);
  });

  test('clearSession removes all answers for a session', () {
    final c = makeContainer();
    final notifier = c.read(askQuestionProvider.notifier);
    notifier.setAnswer(sessionId: 'sess1', stepIndex: 0, selectedOption: 'A', freeText: null);
    notifier.setAnswer(sessionId: 'sess1', stepIndex: 1, selectedOption: 'B', freeText: null);
    notifier.clearSession('sess1');
    expect(notifier.getAnswer('sess1', 0), isNull);
    expect(notifier.getAnswer('sess1', 1), isNull);
  });
}
