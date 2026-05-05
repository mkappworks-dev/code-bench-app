// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ide_launch_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IdeLaunchFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IdeLaunchFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'IdeLaunchFailure()';
}


}

/// @nodoc
class $IdeLaunchFailureCopyWith<$Res>  {
$IdeLaunchFailureCopyWith(IdeLaunchFailure _, $Res Function(IdeLaunchFailure) __);
}


/// Adds pattern-matching-related methods to [IdeLaunchFailure].
extension IdeLaunchFailurePatterns on IdeLaunchFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( IdeLaunchFailed value)?  launchFailed,TResult Function( IdeLaunchUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case IdeLaunchFailed() when launchFailed != null:
return launchFailed(_that);case IdeLaunchUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( IdeLaunchFailed value)  launchFailed,required TResult Function( IdeLaunchUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case IdeLaunchFailed():
return launchFailed(_that);case IdeLaunchUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( IdeLaunchFailed value)?  launchFailed,TResult? Function( IdeLaunchUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case IdeLaunchFailed() when launchFailed != null:
return launchFailed(_that);case IdeLaunchUnknownError() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  launchFailed,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case IdeLaunchFailed() when launchFailed != null:
return launchFailed(_that.message);case IdeLaunchUnknownError() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  launchFailed,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case IdeLaunchFailed():
return launchFailed(_that.message);case IdeLaunchUnknownError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  launchFailed,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case IdeLaunchFailed() when launchFailed != null:
return launchFailed(_that.message);case IdeLaunchUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class IdeLaunchFailed implements IdeLaunchFailure {
  const IdeLaunchFailed(this.message);
  

 final  String message;

/// Create a copy of IdeLaunchFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IdeLaunchFailedCopyWith<IdeLaunchFailed> get copyWith => _$IdeLaunchFailedCopyWithImpl<IdeLaunchFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IdeLaunchFailed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'IdeLaunchFailure.launchFailed(message: $message)';
}


}

/// @nodoc
abstract mixin class $IdeLaunchFailedCopyWith<$Res> implements $IdeLaunchFailureCopyWith<$Res> {
  factory $IdeLaunchFailedCopyWith(IdeLaunchFailed value, $Res Function(IdeLaunchFailed) _then) = _$IdeLaunchFailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$IdeLaunchFailedCopyWithImpl<$Res>
    implements $IdeLaunchFailedCopyWith<$Res> {
  _$IdeLaunchFailedCopyWithImpl(this._self, this._then);

  final IdeLaunchFailed _self;
  final $Res Function(IdeLaunchFailed) _then;

/// Create a copy of IdeLaunchFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(IdeLaunchFailed(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class IdeLaunchUnknownError implements IdeLaunchFailure {
  const IdeLaunchUnknownError(this.error);
  

 final  Object error;

/// Create a copy of IdeLaunchFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IdeLaunchUnknownErrorCopyWith<IdeLaunchUnknownError> get copyWith => _$IdeLaunchUnknownErrorCopyWithImpl<IdeLaunchUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IdeLaunchUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'IdeLaunchFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $IdeLaunchUnknownErrorCopyWith<$Res> implements $IdeLaunchFailureCopyWith<$Res> {
  factory $IdeLaunchUnknownErrorCopyWith(IdeLaunchUnknownError value, $Res Function(IdeLaunchUnknownError) _then) = _$IdeLaunchUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$IdeLaunchUnknownErrorCopyWithImpl<$Res>
    implements $IdeLaunchUnknownErrorCopyWith<$Res> {
  _$IdeLaunchUnknownErrorCopyWithImpl(this._self, this._then);

  final IdeLaunchUnknownError _self;
  final $Res Function(IdeLaunchUnknownError) _then;

/// Create a copy of IdeLaunchFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(IdeLaunchUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
