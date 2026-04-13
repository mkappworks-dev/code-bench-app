import 'package:freezed_annotation/freezed_annotation.dart';

part 'ask_user_question.freezed.dart';
part 'ask_user_question.g.dart';

@freezed
abstract class AskUserQuestion with _$AskUserQuestion {
  const factory AskUserQuestion({
    required String question,
    required List<String> options,
    @Default(true) bool allowFreeText,
    required int stepIndex,
    required int totalSteps,
    String? sectionLabel,
  }) = _AskUserQuestion;

  factory AskUserQuestion.fromJson(Map<String, dynamic> json) => _$AskUserQuestionFromJson(json);
}
