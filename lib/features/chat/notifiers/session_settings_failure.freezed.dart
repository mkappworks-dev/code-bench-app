// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_settings_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionSettingsFailure {

 Object get error;
/// Create a copy of SessionSettingsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionSettingsFailureCopyWith<SessionSettingsFailure> get copyWith => _$SessionSettingsFailureCopyWithImpl<SessionSettingsFailure>(this as SessionSettingsFailure, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSettingsFailure&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'SessionSettingsFailure(error: $error)';
}


}

/// @nodoc
abstract mixin class $SessionSettingsFailureCopyWith<$Res>  {
  factory $SessionSettingsFailureCopyWith(SessionSettingsFailure value, $Res Function(SessionSettingsFailure) _then) = _$SessionSettingsFailureCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$SessionSettingsFailureCopyWithImpl<$Res>
    implements $SessionSettingsFailureCopyWith<$Res> {
  _$SessionSettingsFailureCopyWithImpl(this._self, this._then);

  final SessionSettingsFailure _self;
  final $Res Function(SessionSettingsFailure) _then;

/// Create a copy of SessionSettingsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? error = null,}) {
  return _then(_self.copyWith(
error: null == error ? _self.error : error ,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionSettingsFailure].
extension SessionSettingsFailurePatterns on SessionSettingsFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SessionSettingsUnknownFailure value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SessionSettingsUnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SessionSettingsUnknownFailure value)  unknown,}){
final _that = this;
switch (_that) {
case SessionSettingsUnknownFailure():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SessionSettingsUnknownFailure value)?  unknown,}){
final _that = this;
switch (_that) {
case SessionSettingsUnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SessionSettingsUnknownFailure() when unknown != null:
return unknown(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case SessionSettingsUnknownFailure():
return unknown(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case SessionSettingsUnknownFailure() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class SessionSettingsUnknownFailure implements SessionSettingsFailure {
  const SessionSettingsUnknownFailure(this.error);
  

@override final  Object error;

/// Create a copy of SessionSettingsFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionSettingsUnknownFailureCopyWith<SessionSettingsUnknownFailure> get copyWith => _$SessionSettingsUnknownFailureCopyWithImpl<SessionSettingsUnknownFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSettingsUnknownFailure&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'SessionSettingsFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $SessionSettingsUnknownFailureCopyWith<$Res> implements $SessionSettingsFailureCopyWith<$Res> {
  factory $SessionSettingsUnknownFailureCopyWith(SessionSettingsUnknownFailure value, $Res Function(SessionSettingsUnknownFailure) _then) = _$SessionSettingsUnknownFailureCopyWithImpl;
@override @useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$SessionSettingsUnknownFailureCopyWithImpl<$Res>
    implements $SessionSettingsUnknownFailureCopyWith<$Res> {
  _$SessionSettingsUnknownFailureCopyWithImpl(this._self, this._then);

  final SessionSettingsUnknownFailure _self;
  final $Res Function(SessionSettingsUnknownFailure) _then;

/// Create a copy of SessionSettingsFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(SessionSettingsUnknownFailure(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
