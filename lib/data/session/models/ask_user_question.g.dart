// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ask_user_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AskUserQuestion _$AskUserQuestionFromJson(Map<String, dynamic> json) =>
    _AskUserQuestion(
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      allowFreeText: json['allowFreeText'] as bool? ?? true,
      stepIndex: (json['stepIndex'] as num).toInt(),
      totalSteps: (json['totalSteps'] as num).toInt(),
      sectionLabel: json['sectionLabel'] as String?,
    );

Map<String, dynamic> _$AskUserQuestionToJson(_AskUserQuestion instance) =>
    <String, dynamic>{
      'question': instance.question,
      'options': instance.options,
      'allowFreeText': instance.allowFreeText,
      'stepIndex': instance.stepIndex,
      'totalSteps': instance.totalSteps,
      'sectionLabel': instance.sectionLabel,
    };
