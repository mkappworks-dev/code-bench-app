// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ask_user_question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AskUserQuestion {

 String get question; List<String> get options; bool get allowFreeText; int get stepIndex; int get totalSteps; String? get sectionLabel;
/// Create a copy of AskUserQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AskUserQuestionCopyWith<AskUserQuestion> get copyWith => _$AskUserQuestionCopyWithImpl<AskUserQuestion>(this as AskUserQuestion, _$identity);

  /// Serializes this AskUserQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AskUserQuestion&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other.options, options)&&(identical(other.allowFreeText, allowFreeText) || other.allowFreeText == allowFreeText)&&(identical(other.stepIndex, stepIndex) || other.stepIndex == stepIndex)&&(identical(other.totalSteps, totalSteps) || other.totalSteps == totalSteps)&&(identical(other.sectionLabel, sectionLabel) || other.sectionLabel == sectionLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,question,const DeepCollectionEquality().hash(options),allowFreeText,stepIndex,totalSteps,sectionLabel);

@override
String toString() {
  return 'AskUserQuestion(question: $question, options: $options, allowFreeText: $allowFreeText, stepIndex: $stepIndex, totalSteps: $totalSteps, sectionLabel: $sectionLabel)';
}


}

/// @nodoc
abstract mixin class $AskUserQuestionCopyWith<$Res>  {
  factory $AskUserQuestionCopyWith(AskUserQuestion value, $Res Function(AskUserQuestion) _then) = _$AskUserQuestionCopyWithImpl;
@useResult
$Res call({
 String question, List<String> options, bool allowFreeText, int stepIndex, int totalSteps, String? sectionLabel
});




}
/// @nodoc
class _$AskUserQuestionCopyWithImpl<$Res>
    implements $AskUserQuestionCopyWith<$Res> {
  _$AskUserQuestionCopyWithImpl(this._self, this._then);

  final AskUserQuestion _self;
  final $Res Function(AskUserQuestion) _then;

/// Create a copy of AskUserQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? question = null,Object? options = null,Object? allowFreeText = null,Object? stepIndex = null,Object? totalSteps = null,Object? sectionLabel = freezed,}) {
  return _then(_self.copyWith(
question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,allowFreeText: null == allowFreeText ? _self.allowFreeText : allowFreeText // ignore: cast_nullable_to_non_nullable
as bool,stepIndex: null == stepIndex ? _self.stepIndex : stepIndex // ignore: cast_nullable_to_non_nullable
as int,totalSteps: null == totalSteps ? _self.totalSteps : totalSteps // ignore: cast_nullable_to_non_nullable
as int,sectionLabel: freezed == sectionLabel ? _self.sectionLabel : sectionLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AskUserQuestion].
extension AskUserQuestionPatterns on AskUserQuestion {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AskUserQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AskUserQuestion() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AskUserQuestion value)  $default,){
final _that = this;
switch (_that) {
case _AskUserQuestion():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AskUserQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _AskUserQuestion() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String question,  List<String> options,  bool allowFreeText,  int stepIndex,  int totalSteps,  String? sectionLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AskUserQuestion() when $default != null:
return $default(_that.question,_that.options,_that.allowFreeText,_that.stepIndex,_that.totalSteps,_that.sectionLabel);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String question,  List<String> options,  bool allowFreeText,  int stepIndex,  int totalSteps,  String? sectionLabel)  $default,) {final _that = this;
switch (_that) {
case _AskUserQuestion():
return $default(_that.question,_that.options,_that.allowFreeText,_that.stepIndex,_that.totalSteps,_that.sectionLabel);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String question,  List<String> options,  bool allowFreeText,  int stepIndex,  int totalSteps,  String? sectionLabel)?  $default,) {final _that = this;
switch (_that) {
case _AskUserQuestion() when $default != null:
return $default(_that.question,_that.options,_that.allowFreeText,_that.stepIndex,_that.totalSteps,_that.sectionLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AskUserQuestion implements AskUserQuestion {
  const _AskUserQuestion({required this.question, required final  List<String> options, this.allowFreeText = true, required this.stepIndex, required this.totalSteps, this.sectionLabel}): _options = options;
  factory _AskUserQuestion.fromJson(Map<String, dynamic> json) => _$AskUserQuestionFromJson(json);

@override final  String question;
 final  List<String> _options;
@override List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override@JsonKey() final  bool allowFreeText;
@override final  int stepIndex;
@override final  int totalSteps;
@override final  String? sectionLabel;

/// Create a copy of AskUserQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AskUserQuestionCopyWith<_AskUserQuestion> get copyWith => __$AskUserQuestionCopyWithImpl<_AskUserQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AskUserQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AskUserQuestion&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.allowFreeText, allowFreeText) || other.allowFreeText == allowFreeText)&&(identical(other.stepIndex, stepIndex) || other.stepIndex == stepIndex)&&(identical(other.totalSteps, totalSteps) || other.totalSteps == totalSteps)&&(identical(other.sectionLabel, sectionLabel) || other.sectionLabel == sectionLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,question,const DeepCollectionEquality().hash(_options),allowFreeText,stepIndex,totalSteps,sectionLabel);

@override
String toString() {
  return 'AskUserQuestion(question: $question, options: $options, allowFreeText: $allowFreeText, stepIndex: $stepIndex, totalSteps: $totalSteps, sectionLabel: $sectionLabel)';
}


}

/// @nodoc
abstract mixin class _$AskUserQuestionCopyWith<$Res> implements $AskUserQuestionCopyWith<$Res> {
  factory _$AskUserQuestionCopyWith(_AskUserQuestion value, $Res Function(_AskUserQuestion) _then) = __$AskUserQuestionCopyWithImpl;
@override @useResult
$Res call({
 String question, List<String> options, bool allowFreeText, int stepIndex, int totalSteps, String? sectionLabel
});




}
/// @nodoc
class __$AskUserQuestionCopyWithImpl<$Res>
    implements _$AskUserQuestionCopyWith<$Res> {
  __$AskUserQuestionCopyWithImpl(this._self, this._then);

  final _AskUserQuestion _self;
  final $Res Function(_AskUserQuestion) _then;

/// Create a copy of AskUserQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? question = null,Object? options = null,Object? allowFreeText = null,Object? stepIndex = null,Object? totalSteps = null,Object? sectionLabel = freezed,}) {
  return _then(_AskUserQuestion(
question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,allowFreeText: null == allowFreeText ? _self.allowFreeText : allowFreeText // ignore: cast_nullable_to_non_nullable
as bool,stepIndex: null == stepIndex ? _self.stepIndex : stepIndex // ignore: cast_nullable_to_non_nullable
as int,totalSteps: null == totalSteps ? _self.totalSteps : totalSteps // ignore: cast_nullable_to_non_nullable
as int,sectionLabel: freezed == sectionLabel ? _self.sectionLabel : sectionLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
