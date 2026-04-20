// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coding_tool_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CodingToolResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodingToolResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CodingToolResult()';
}


}

/// @nodoc
class $CodingToolResultCopyWith<$Res>  {
$CodingToolResultCopyWith(CodingToolResult _, $Res Function(CodingToolResult) __);
}


/// Adds pattern-matching-related methods to [CodingToolResult].
extension CodingToolResultPatterns on CodingToolResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CodingToolResultSuccess value)?  success,TResult Function( CodingToolResultError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CodingToolResultSuccess() when success != null:
return success(_that);case CodingToolResultError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CodingToolResultSuccess value)  success,required TResult Function( CodingToolResultError value)  error,}){
final _that = this;
switch (_that) {
case CodingToolResultSuccess():
return success(_that);case CodingToolResultError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CodingToolResultSuccess value)?  success,TResult? Function( CodingToolResultError value)?  error,}){
final _that = this;
switch (_that) {
case CodingToolResultSuccess() when success != null:
return success(_that);case CodingToolResultError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String output)?  success,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CodingToolResultSuccess() when success != null:
return success(_that.output);case CodingToolResultError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String output)  success,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case CodingToolResultSuccess():
return success(_that.output);case CodingToolResultError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String output)?  success,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case CodingToolResultSuccess() when success != null:
return success(_that.output);case CodingToolResultError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class CodingToolResultSuccess implements CodingToolResult {
  const CodingToolResultSuccess(this.output);
  

 final  String output;

/// Create a copy of CodingToolResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CodingToolResultSuccessCopyWith<CodingToolResultSuccess> get copyWith => _$CodingToolResultSuccessCopyWithImpl<CodingToolResultSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodingToolResultSuccess&&(identical(other.output, output) || other.output == output));
}


@override
int get hashCode => Object.hash(runtimeType,output);

@override
String toString() {
  return 'CodingToolResult.success(output: $output)';
}


}

/// @nodoc
abstract mixin class $CodingToolResultSuccessCopyWith<$Res> implements $CodingToolResultCopyWith<$Res> {
  factory $CodingToolResultSuccessCopyWith(CodingToolResultSuccess value, $Res Function(CodingToolResultSuccess) _then) = _$CodingToolResultSuccessCopyWithImpl;
@useResult
$Res call({
 String output
});




}
/// @nodoc
class _$CodingToolResultSuccessCopyWithImpl<$Res>
    implements $CodingToolResultSuccessCopyWith<$Res> {
  _$CodingToolResultSuccessCopyWithImpl(this._self, this._then);

  final CodingToolResultSuccess _self;
  final $Res Function(CodingToolResultSuccess) _then;

/// Create a copy of CodingToolResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? output = null,}) {
  return _then(CodingToolResultSuccess(
null == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CodingToolResultError implements CodingToolResult {
  const CodingToolResultError(this.message);
  

 final  String message;

/// Create a copy of CodingToolResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CodingToolResultErrorCopyWith<CodingToolResultError> get copyWith => _$CodingToolResultErrorCopyWithImpl<CodingToolResultError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodingToolResultError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'CodingToolResult.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $CodingToolResultErrorCopyWith<$Res> implements $CodingToolResultCopyWith<$Res> {
  factory $CodingToolResultErrorCopyWith(CodingToolResultError value, $Res Function(CodingToolResultError) _then) = _$CodingToolResultErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$CodingToolResultErrorCopyWithImpl<$Res>
    implements $CodingToolResultErrorCopyWith<$Res> {
  _$CodingToolResultErrorCopyWithImpl(this._self, this._then);

  final CodingToolResultError _self;
  final $Res Function(CodingToolResultError) _then;

/// Create a copy of CodingToolResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(CodingToolResultError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
