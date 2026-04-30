// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdateFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateFailure()';
}


}

/// @nodoc
class $UpdateFailureCopyWith<$Res>  {
$UpdateFailureCopyWith(UpdateFailure _, $Res Function(UpdateFailure) __);
}


/// Adds pattern-matching-related methods to [UpdateFailure].
extension UpdateFailurePatterns on UpdateFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UpdateNetworkError value)?  networkError,TResult Function( UpdateDownloadFailed value)?  downloadFailed,TResult Function( UpdateInstallFailed value)?  installFailed,TResult Function( UpdateUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UpdateNetworkError() when networkError != null:
return networkError(_that);case UpdateDownloadFailed() when downloadFailed != null:
return downloadFailed(_that);case UpdateInstallFailed() when installFailed != null:
return installFailed(_that);case UpdateUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UpdateNetworkError value)  networkError,required TResult Function( UpdateDownloadFailed value)  downloadFailed,required TResult Function( UpdateInstallFailed value)  installFailed,required TResult Function( UpdateUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case UpdateNetworkError():
return networkError(_that);case UpdateDownloadFailed():
return downloadFailed(_that);case UpdateInstallFailed():
return installFailed(_that);case UpdateUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UpdateNetworkError value)?  networkError,TResult? Function( UpdateDownloadFailed value)?  downloadFailed,TResult? Function( UpdateInstallFailed value)?  installFailed,TResult? Function( UpdateUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case UpdateNetworkError() when networkError != null:
return networkError(_that);case UpdateDownloadFailed() when downloadFailed != null:
return downloadFailed(_that);case UpdateInstallFailed() when installFailed != null:
return installFailed(_that);case UpdateUnknownError() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? detail)?  networkError,TResult Function( String? detail)?  downloadFailed,TResult Function( String? detail)?  installFailed,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UpdateNetworkError() when networkError != null:
return networkError(_that.detail);case UpdateDownloadFailed() when downloadFailed != null:
return downloadFailed(_that.detail);case UpdateInstallFailed() when installFailed != null:
return installFailed(_that.detail);case UpdateUnknownError() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? detail)  networkError,required TResult Function( String? detail)  downloadFailed,required TResult Function( String? detail)  installFailed,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case UpdateNetworkError():
return networkError(_that.detail);case UpdateDownloadFailed():
return downloadFailed(_that.detail);case UpdateInstallFailed():
return installFailed(_that.detail);case UpdateUnknownError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? detail)?  networkError,TResult? Function( String? detail)?  downloadFailed,TResult? Function( String? detail)?  installFailed,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case UpdateNetworkError() when networkError != null:
return networkError(_that.detail);case UpdateDownloadFailed() when downloadFailed != null:
return downloadFailed(_that.detail);case UpdateInstallFailed() when installFailed != null:
return installFailed(_that.detail);case UpdateUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class UpdateNetworkError implements UpdateFailure {
  const UpdateNetworkError([this.detail]);
  

 final  String? detail;

/// Create a copy of UpdateFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateNetworkErrorCopyWith<UpdateNetworkError> get copyWith => _$UpdateNetworkErrorCopyWithImpl<UpdateNetworkError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateNetworkError&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'UpdateFailure.networkError(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $UpdateNetworkErrorCopyWith<$Res> implements $UpdateFailureCopyWith<$Res> {
  factory $UpdateNetworkErrorCopyWith(UpdateNetworkError value, $Res Function(UpdateNetworkError) _then) = _$UpdateNetworkErrorCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$UpdateNetworkErrorCopyWithImpl<$Res>
    implements $UpdateNetworkErrorCopyWith<$Res> {
  _$UpdateNetworkErrorCopyWithImpl(this._self, this._then);

  final UpdateNetworkError _self;
  final $Res Function(UpdateNetworkError) _then;

/// Create a copy of UpdateFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(UpdateNetworkError(
freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UpdateDownloadFailed implements UpdateFailure {
  const UpdateDownloadFailed([this.detail]);
  

 final  String? detail;

/// Create a copy of UpdateFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateDownloadFailedCopyWith<UpdateDownloadFailed> get copyWith => _$UpdateDownloadFailedCopyWithImpl<UpdateDownloadFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateDownloadFailed&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'UpdateFailure.downloadFailed(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $UpdateDownloadFailedCopyWith<$Res> implements $UpdateFailureCopyWith<$Res> {
  factory $UpdateDownloadFailedCopyWith(UpdateDownloadFailed value, $Res Function(UpdateDownloadFailed) _then) = _$UpdateDownloadFailedCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$UpdateDownloadFailedCopyWithImpl<$Res>
    implements $UpdateDownloadFailedCopyWith<$Res> {
  _$UpdateDownloadFailedCopyWithImpl(this._self, this._then);

  final UpdateDownloadFailed _self;
  final $Res Function(UpdateDownloadFailed) _then;

/// Create a copy of UpdateFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(UpdateDownloadFailed(
freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UpdateInstallFailed implements UpdateFailure {
  const UpdateInstallFailed([this.detail]);
  

 final  String? detail;

/// Create a copy of UpdateFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateInstallFailedCopyWith<UpdateInstallFailed> get copyWith => _$UpdateInstallFailedCopyWithImpl<UpdateInstallFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateInstallFailed&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'UpdateFailure.installFailed(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $UpdateInstallFailedCopyWith<$Res> implements $UpdateFailureCopyWith<$Res> {
  factory $UpdateInstallFailedCopyWith(UpdateInstallFailed value, $Res Function(UpdateInstallFailed) _then) = _$UpdateInstallFailedCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$UpdateInstallFailedCopyWithImpl<$Res>
    implements $UpdateInstallFailedCopyWith<$Res> {
  _$UpdateInstallFailedCopyWithImpl(this._self, this._then);

  final UpdateInstallFailed _self;
  final $Res Function(UpdateInstallFailed) _then;

/// Create a copy of UpdateFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(UpdateInstallFailed(
freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UpdateUnknownError implements UpdateFailure {
  const UpdateUnknownError(this.error);
  

 final  Object error;

/// Create a copy of UpdateFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateUnknownErrorCopyWith<UpdateUnknownError> get copyWith => _$UpdateUnknownErrorCopyWithImpl<UpdateUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'UpdateFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $UpdateUnknownErrorCopyWith<$Res> implements $UpdateFailureCopyWith<$Res> {
  factory $UpdateUnknownErrorCopyWith(UpdateUnknownError value, $Res Function(UpdateUnknownError) _then) = _$UpdateUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$UpdateUnknownErrorCopyWithImpl<$Res>
    implements $UpdateUnknownErrorCopyWith<$Res> {
  _$UpdateUnknownErrorCopyWithImpl(this._self, this._then);

  final UpdateUnknownError _self;
  final $Res Function(UpdateUnknownError) _then;

/// Create a copy of UpdateFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(UpdateUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
