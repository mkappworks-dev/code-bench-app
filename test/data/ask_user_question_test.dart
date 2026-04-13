import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/session/models/ask_user_question.dart';

void main() {
  group('AskUserQuestion', () {
    test('serializes and deserializes', () {
      const q = AskUserQuestion(
        question: 'Choose approach',
        options: ['Option A', 'Option B'],
        stepIndex: 0,
        totalSteps: 3,
        sectionLabel: 'Architecture',
      );
      final json = q.toJson();
      final restored = AskUserQuestion.fromJson(json);
      expect(restored.question, 'Choose approach');
      expect(restored.options, ['Option A', 'Option B']);
      expect(restored.totalSteps, 3);
      expect(restored.allowFreeText, isTrue); // default
    });

    test('allowFreeText defaults to true', () {
      const q = AskUserQuestion(question: 'Q?', options: [], stepIndex: 0, totalSteps: 1);
      expect(q.allowFreeText, isTrue);
    });
  });
}
