import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ask_question_notifier.freezed.dart';
part 'ask_question_notifier.g.dart';

@freezed
abstract class QuestionAnswer with _$QuestionAnswer {
  const factory QuestionAnswer({required String? selectedOption, required String? freeText}) = _QuestionAnswer;
}

@freezed
abstract class AskQuestionState with _$AskQuestionState {
  const factory AskQuestionState({@Default({}) Map<(String, int), QuestionAnswer> answers}) = _AskQuestionState;
}

@Riverpod(keepAlive: true)
class AskQuestionNotifier extends _$AskQuestionNotifier {
  @override
  AskQuestionState build() => const AskQuestionState();

  void setAnswer({
    required String sessionId,
    required int stepIndex,
    required String? selectedOption,
    required String? freeText,
  }) {
    final key = (sessionId, stepIndex);
    state = state.copyWith(
      answers: {
        ...state.answers,
        key: QuestionAnswer(selectedOption: selectedOption, freeText: freeText),
      },
    );
  }

  QuestionAnswer? getAnswer(String sessionId, int stepIndex) => state.answers[(sessionId, stepIndex)];

  void clearSession(String sessionId) {
    state = state.copyWith(answers: Map.fromEntries(state.answers.entries.where((e) => e.key.$1 != sessionId)));
  }
}
