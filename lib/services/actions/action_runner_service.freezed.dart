// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'action_runner_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActionOutputState {

 ActionStatus get status; List<String> get lines; String? get actionName; int? get exitCode;
/// Create a copy of ActionOutputState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionOutputStateCopyWith<ActionOutputState> get copyWith => _$ActionOutputStateCopyWithImpl<ActionOutputState>(this as ActionOutputState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionOutputState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.lines, lines)&&(identical(other.actionName, actionName) || other.actionName == actionName)&&(identical(other.exitCode, exitCode) || other.exitCode == exitCode));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(lines),actionName,exitCode);

@override
String toString() {
  return 'ActionOutputState(status: $status, lines: $lines, actionName: $actionName, exitCode: $exitCode)';
}


}

/// @nodoc
abstract mixin class $ActionOutputStateCopyWith<$Res>  {
  factory $ActionOutputStateCopyWith(ActionOutputState value, $Res Function(ActionOutputState) _then) = _$ActionOutputStateCopyWithImpl;
@useResult
$Res call({
 ActionStatus status, List<String> lines, String? actionName, int? exitCode
});




}
/// @nodoc
class _$ActionOutputStateCopyWithImpl<$Res>
    implements $ActionOutputStateCopyWith<$Res> {
  _$ActionOutputStateCopyWithImpl(this._self, this._then);

  final ActionOutputState _self;
  final $Res Function(ActionOutputState) _then;

/// Create a copy of ActionOutputState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? lines = null,Object? actionName = freezed,Object? exitCode = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ActionStatus,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<String>,actionName: freezed == actionName ? _self.actionName : actionName // ignore: cast_nullable_to_non_nullable
as String?,exitCode: freezed == exitCode ? _self.exitCode : exitCode // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionOutputState].
extension ActionOutputStatePatterns on ActionOutputState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionOutputState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionOutputState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionOutputState value)  $default,){
final _that = this;
switch (_that) {
case _ActionOutputState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionOutputState value)?  $default,){
final _that = this;
switch (_that) {
case _ActionOutputState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ActionStatus status,  List<String> lines,  String? actionName,  int? exitCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionOutputState() when $default != null:
return $default(_that.status,_that.lines,_that.actionName,_that.exitCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ActionStatus status,  List<String> lines,  String? actionName,  int? exitCode)  $default,) {final _that = this;
switch (_that) {
case _ActionOutputState():
return $default(_that.status,_that.lines,_that.actionName,_that.exitCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ActionStatus status,  List<String> lines,  String? actionName,  int? exitCode)?  $default,) {final _that = this;
switch (_that) {
case _ActionOutputState() when $default != null:
return $default(_that.status,_that.lines,_that.actionName,_that.exitCode);case _:
  return null;

}
}

}

/// @nodoc


class _ActionOutputState implements ActionOutputState {
  const _ActionOutputState({this.status = ActionStatus.idle, final  List<String> lines = const [], this.actionName, this.exitCode}): _lines = lines;
  

@override@JsonKey() final  ActionStatus status;
 final  List<String> _lines;
@override@JsonKey() List<String> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override final  String? actionName;
@override final  int? exitCode;

/// Create a copy of ActionOutputState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionOutputStateCopyWith<_ActionOutputState> get copyWith => __$ActionOutputStateCopyWithImpl<_ActionOutputState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionOutputState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.actionName, actionName) || other.actionName == actionName)&&(identical(other.exitCode, exitCode) || other.exitCode == exitCode));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_lines),actionName,exitCode);

@override
String toString() {
  return 'ActionOutputState(status: $status, lines: $lines, actionName: $actionName, exitCode: $exitCode)';
}


}

/// @nodoc
abstract mixin class _$ActionOutputStateCopyWith<$Res> implements $ActionOutputStateCopyWith<$Res> {
  factory _$ActionOutputStateCopyWith(_ActionOutputState value, $Res Function(_ActionOutputState) _then) = __$ActionOutputStateCopyWithImpl;
@override @useResult
$Res call({
 ActionStatus status, List<String> lines, String? actionName, int? exitCode
});




}
/// @nodoc
class __$ActionOutputStateCopyWithImpl<$Res>
    implements _$ActionOutputStateCopyWith<$Res> {
  __$ActionOutputStateCopyWithImpl(this._self, this._then);

  final _ActionOutputState _self;
  final $Res Function(_ActionOutputState) _then;

/// Create a copy of ActionOutputState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? lines = null,Object? actionName = freezed,Object? exitCode = freezed,}) {
  return _then(_ActionOutputState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ActionStatus,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<String>,actionName: freezed == actionName ? _self.actionName : actionName // ignore: cast_nullable_to_non_nullable
as String?,exitCode: freezed == exitCode ? _self.exitCode : exitCode // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
