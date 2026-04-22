// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mcp_servers_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$McpServersFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServersFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'McpServersFailure()';
}


}

/// @nodoc
class $McpServersFailureCopyWith<$Res>  {
$McpServersFailureCopyWith(McpServersFailure _, $Res Function(McpServersFailure) __);
}


/// Adds pattern-matching-related methods to [McpServersFailure].
extension McpServersFailurePatterns on McpServersFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( McpServersSaveError value)?  saveError,TResult Function( McpServersRemoveError value)?  removeError,TResult Function( McpServersUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case McpServersSaveError() when saveError != null:
return saveError(_that);case McpServersRemoveError() when removeError != null:
return removeError(_that);case McpServersUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( McpServersSaveError value)  saveError,required TResult Function( McpServersRemoveError value)  removeError,required TResult Function( McpServersUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case McpServersSaveError():
return saveError(_that);case McpServersRemoveError():
return removeError(_that);case McpServersUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( McpServersSaveError value)?  saveError,TResult? Function( McpServersRemoveError value)?  removeError,TResult? Function( McpServersUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case McpServersSaveError() when saveError != null:
return saveError(_that);case McpServersRemoveError() when removeError != null:
return removeError(_that);case McpServersUnknownError() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? detail)?  saveError,TResult Function( String? detail)?  removeError,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case McpServersSaveError() when saveError != null:
return saveError(_that.detail);case McpServersRemoveError() when removeError != null:
return removeError(_that.detail);case McpServersUnknownError() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? detail)  saveError,required TResult Function( String? detail)  removeError,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case McpServersSaveError():
return saveError(_that.detail);case McpServersRemoveError():
return removeError(_that.detail);case McpServersUnknownError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? detail)?  saveError,TResult? Function( String? detail)?  removeError,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case McpServersSaveError() when saveError != null:
return saveError(_that.detail);case McpServersRemoveError() when removeError != null:
return removeError(_that.detail);case McpServersUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class McpServersSaveError implements McpServersFailure {
  const McpServersSaveError([this.detail]);
  

 final  String? detail;

/// Create a copy of McpServersFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServersSaveErrorCopyWith<McpServersSaveError> get copyWith => _$McpServersSaveErrorCopyWithImpl<McpServersSaveError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServersSaveError&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'McpServersFailure.saveError(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $McpServersSaveErrorCopyWith<$Res> implements $McpServersFailureCopyWith<$Res> {
  factory $McpServersSaveErrorCopyWith(McpServersSaveError value, $Res Function(McpServersSaveError) _then) = _$McpServersSaveErrorCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$McpServersSaveErrorCopyWithImpl<$Res>
    implements $McpServersSaveErrorCopyWith<$Res> {
  _$McpServersSaveErrorCopyWithImpl(this._self, this._then);

  final McpServersSaveError _self;
  final $Res Function(McpServersSaveError) _then;

/// Create a copy of McpServersFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(McpServersSaveError(
freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class McpServersRemoveError implements McpServersFailure {
  const McpServersRemoveError([this.detail]);
  

 final  String? detail;

/// Create a copy of McpServersFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServersRemoveErrorCopyWith<McpServersRemoveError> get copyWith => _$McpServersRemoveErrorCopyWithImpl<McpServersRemoveError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServersRemoveError&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'McpServersFailure.removeError(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $McpServersRemoveErrorCopyWith<$Res> implements $McpServersFailureCopyWith<$Res> {
  factory $McpServersRemoveErrorCopyWith(McpServersRemoveError value, $Res Function(McpServersRemoveError) _then) = _$McpServersRemoveErrorCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$McpServersRemoveErrorCopyWithImpl<$Res>
    implements $McpServersRemoveErrorCopyWith<$Res> {
  _$McpServersRemoveErrorCopyWithImpl(this._self, this._then);

  final McpServersRemoveError _self;
  final $Res Function(McpServersRemoveError) _then;

/// Create a copy of McpServersFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(McpServersRemoveError(
freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class McpServersUnknownError implements McpServersFailure {
  const McpServersUnknownError(this.error);
  

 final  Object error;

/// Create a copy of McpServersFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServersUnknownErrorCopyWith<McpServersUnknownError> get copyWith => _$McpServersUnknownErrorCopyWithImpl<McpServersUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServersUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'McpServersFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $McpServersUnknownErrorCopyWith<$Res> implements $McpServersFailureCopyWith<$Res> {
  factory $McpServersUnknownErrorCopyWith(McpServersUnknownError value, $Res Function(McpServersUnknownError) _then) = _$McpServersUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$McpServersUnknownErrorCopyWithImpl<$Res>
    implements $McpServersUnknownErrorCopyWith<$Res> {
  _$McpServersUnknownErrorCopyWithImpl(this._self, this._then);

  final McpServersUnknownError _self;
  final $Res Function(McpServersUnknownError) _then;

/// Create a copy of McpServersFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(McpServersUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
