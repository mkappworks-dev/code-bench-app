// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ask_question_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuestionAnswer {

 String? get selectedOption; String? get freeText;
/// Create a copy of QuestionAnswer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionAnswerCopyWith<QuestionAnswer> get copyWith => _$QuestionAnswerCopyWithImpl<QuestionAnswer>(this as QuestionAnswer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionAnswer&&(identical(other.selectedOption, selectedOption) || other.selectedOption == selectedOption)&&(identical(other.freeText, freeText) || other.freeText == freeText));
}


@override
int get hashCode => Object.hash(runtimeType,selectedOption,freeText);

@override
String toString() {
  return 'QuestionAnswer(selectedOption: $selectedOption, freeText: $freeText)';
}


}

/// @nodoc
abstract mixin class $QuestionAnswerCopyWith<$Res>  {
  factory $QuestionAnswerCopyWith(QuestionAnswer value, $Res Function(QuestionAnswer) _then) = _$QuestionAnswerCopyWithImpl;
@useResult
$Res call({
 String? selectedOption, String? freeText
});




}
/// @nodoc
class _$QuestionAnswerCopyWithImpl<$Res>
    implements $QuestionAnswerCopyWith<$Res> {
  _$QuestionAnswerCopyWithImpl(this._self, this._then);

  final QuestionAnswer _self;
  final $Res Function(QuestionAnswer) _then;

/// Create a copy of QuestionAnswer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedOption = freezed,Object? freeText = freezed,}) {
  return _then(_self.copyWith(
selectedOption: freezed == selectedOption ? _self.selectedOption : selectedOption // ignore: cast_nullable_to_non_nullable
as String?,freeText: freezed == freeText ? _self.freeText : freeText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuestionAnswer].
extension QuestionAnswerPatterns on QuestionAnswer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionAnswer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionAnswer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionAnswer value)  $default,){
final _that = this;
switch (_that) {
case _QuestionAnswer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionAnswer value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionAnswer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? selectedOption,  String? freeText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionAnswer() when $default != null:
return $default(_that.selectedOption,_that.freeText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? selectedOption,  String? freeText)  $default,) {final _that = this;
switch (_that) {
case _QuestionAnswer():
return $default(_that.selectedOption,_that.freeText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? selectedOption,  String? freeText)?  $default,) {final _that = this;
switch (_that) {
case _QuestionAnswer() when $default != null:
return $default(_that.selectedOption,_that.freeText);case _:
  return null;

}
}

}

/// @nodoc


class _QuestionAnswer implements QuestionAnswer {
  const _QuestionAnswer({required this.selectedOption, required this.freeText});
  

@override final  String? selectedOption;
@override final  String? freeText;

/// Create a copy of QuestionAnswer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionAnswerCopyWith<_QuestionAnswer> get copyWith => __$QuestionAnswerCopyWithImpl<_QuestionAnswer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionAnswer&&(identical(other.selectedOption, selectedOption) || other.selectedOption == selectedOption)&&(identical(other.freeText, freeText) || other.freeText == freeText));
}


@override
int get hashCode => Object.hash(runtimeType,selectedOption,freeText);

@override
String toString() {
  return 'QuestionAnswer(selectedOption: $selectedOption, freeText: $freeText)';
}


}

/// @nodoc
abstract mixin class _$QuestionAnswerCopyWith<$Res> implements $QuestionAnswerCopyWith<$Res> {
  factory _$QuestionAnswerCopyWith(_QuestionAnswer value, $Res Function(_QuestionAnswer) _then) = __$QuestionAnswerCopyWithImpl;
@override @useResult
$Res call({
 String? selectedOption, String? freeText
});




}
/// @nodoc
class __$QuestionAnswerCopyWithImpl<$Res>
    implements _$QuestionAnswerCopyWith<$Res> {
  __$QuestionAnswerCopyWithImpl(this._self, this._then);

  final _QuestionAnswer _self;
  final $Res Function(_QuestionAnswer) _then;

/// Create a copy of QuestionAnswer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedOption = freezed,Object? freeText = freezed,}) {
  return _then(_QuestionAnswer(
selectedOption: freezed == selectedOption ? _self.selectedOption : selectedOption // ignore: cast_nullable_to_non_nullable
as String?,freeText: freezed == freeText ? _self.freeText : freeText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AskQuestionState {

 Map<(String, int), QuestionAnswer> get answers;
/// Create a copy of AskQuestionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AskQuestionStateCopyWith<AskQuestionState> get copyWith => _$AskQuestionStateCopyWithImpl<AskQuestionState>(this as AskQuestionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AskQuestionState&&const DeepCollectionEquality().equals(other.answers, answers));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(answers));

@override
String toString() {
  return 'AskQuestionState(answers: $answers)';
}


}

/// @nodoc
abstract mixin class $AskQuestionStateCopyWith<$Res>  {
  factory $AskQuestionStateCopyWith(AskQuestionState value, $Res Function(AskQuestionState) _then) = _$AskQuestionStateCopyWithImpl;
@useResult
$Res call({
 Map<(String, int), QuestionAnswer> answers
});




}
/// @nodoc
class _$AskQuestionStateCopyWithImpl<$Res>
    implements $AskQuestionStateCopyWith<$Res> {
  _$AskQuestionStateCopyWithImpl(this._self, this._then);

  final AskQuestionState _self;
  final $Res Function(AskQuestionState) _then;

/// Create a copy of AskQuestionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? answers = null,}) {
  return _then(_self.copyWith(
answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as Map<(String, int), QuestionAnswer>,
  ));
}

}


/// Adds pattern-matching-related methods to [AskQuestionState].
extension AskQuestionStatePatterns on AskQuestionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AskQuestionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AskQuestionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AskQuestionState value)  $default,){
final _that = this;
switch (_that) {
case _AskQuestionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AskQuestionState value)?  $default,){
final _that = this;
switch (_that) {
case _AskQuestionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<(String, int), QuestionAnswer> answers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AskQuestionState() when $default != null:
return $default(_that.answers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<(String, int), QuestionAnswer> answers)  $default,) {final _that = this;
switch (_that) {
case _AskQuestionState():
return $default(_that.answers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<(String, int), QuestionAnswer> answers)?  $default,) {final _that = this;
switch (_that) {
case _AskQuestionState() when $default != null:
return $default(_that.answers);case _:
  return null;

}
}

}

/// @nodoc


class _AskQuestionState implements AskQuestionState {
  const _AskQuestionState({final  Map<(String, int), QuestionAnswer> answers = const {}}): _answers = answers;
  

 final  Map<(String, int), QuestionAnswer> _answers;
@override@JsonKey() Map<(String, int), QuestionAnswer> get answers {
  if (_answers is EqualUnmodifiableMapView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_answers);
}


/// Create a copy of AskQuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AskQuestionStateCopyWith<_AskQuestionState> get copyWith => __$AskQuestionStateCopyWithImpl<_AskQuestionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AskQuestionState&&const DeepCollectionEquality().equals(other._answers, _answers));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_answers));

@override
String toString() {
  return 'AskQuestionState(answers: $answers)';
}


}

/// @nodoc
abstract mixin class _$AskQuestionStateCopyWith<$Res> implements $AskQuestionStateCopyWith<$Res> {
  factory _$AskQuestionStateCopyWith(_AskQuestionState value, $Res Function(_AskQuestionState) _then) = __$AskQuestionStateCopyWithImpl;
@override @useResult
$Res call({
 Map<(String, int), QuestionAnswer> answers
});




}
/// @nodoc
class __$AskQuestionStateCopyWithImpl<$Res>
    implements _$AskQuestionStateCopyWith<$Res> {
  __$AskQuestionStateCopyWithImpl(this._self, this._then);

  final _AskQuestionState _self;
  final $Res Function(_AskQuestionState) _then;

/// Create a copy of AskQuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? answers = null,}) {
  return _then(_AskQuestionState(
answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as Map<(String, int), QuestionAnswer>,
  ));
}


}

// dart format on
