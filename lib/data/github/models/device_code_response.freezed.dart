// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_code_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceCodeResponse {

@JsonKey(name: 'user_code') String get userCode;@JsonKey(name: 'verification_uri') String get verificationUri;@JsonKey(name: 'device_code') String get deviceCode; int get interval;@JsonKey(name: 'expires_in') int get expiresIn;
/// Create a copy of DeviceCodeResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceCodeResponseCopyWith<DeviceCodeResponse> get copyWith => _$DeviceCodeResponseCopyWithImpl<DeviceCodeResponse>(this as DeviceCodeResponse, _$identity);

  /// Serializes this DeviceCodeResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceCodeResponse&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.verificationUri, verificationUri) || other.verificationUri == verificationUri)&&(identical(other.deviceCode, deviceCode) || other.deviceCode == deviceCode)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userCode,verificationUri,deviceCode,interval,expiresIn);

@override
String toString() {
  return 'DeviceCodeResponse(userCode: $userCode, verificationUri: $verificationUri, deviceCode: $deviceCode, interval: $interval, expiresIn: $expiresIn)';
}


}

/// @nodoc
abstract mixin class $DeviceCodeResponseCopyWith<$Res>  {
  factory $DeviceCodeResponseCopyWith(DeviceCodeResponse value, $Res Function(DeviceCodeResponse) _then) = _$DeviceCodeResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_code') String userCode,@JsonKey(name: 'verification_uri') String verificationUri,@JsonKey(name: 'device_code') String deviceCode, int interval,@JsonKey(name: 'expires_in') int expiresIn
});




}
/// @nodoc
class _$DeviceCodeResponseCopyWithImpl<$Res>
    implements $DeviceCodeResponseCopyWith<$Res> {
  _$DeviceCodeResponseCopyWithImpl(this._self, this._then);

  final DeviceCodeResponse _self;
  final $Res Function(DeviceCodeResponse) _then;

/// Create a copy of DeviceCodeResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userCode = null,Object? verificationUri = null,Object? deviceCode = null,Object? interval = null,Object? expiresIn = null,}) {
  return _then(_self.copyWith(
userCode: null == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String,verificationUri: null == verificationUri ? _self.verificationUri : verificationUri // ignore: cast_nullable_to_non_nullable
as String,deviceCode: null == deviceCode ? _self.deviceCode : deviceCode // ignore: cast_nullable_to_non_nullable
as String,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceCodeResponse].
extension DeviceCodeResponsePatterns on DeviceCodeResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceCodeResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceCodeResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceCodeResponse value)  $default,){
final _that = this;
switch (_that) {
case _DeviceCodeResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceCodeResponse value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceCodeResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_code')  String userCode, @JsonKey(name: 'verification_uri')  String verificationUri, @JsonKey(name: 'device_code')  String deviceCode,  int interval, @JsonKey(name: 'expires_in')  int expiresIn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceCodeResponse() when $default != null:
return $default(_that.userCode,_that.verificationUri,_that.deviceCode,_that.interval,_that.expiresIn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_code')  String userCode, @JsonKey(name: 'verification_uri')  String verificationUri, @JsonKey(name: 'device_code')  String deviceCode,  int interval, @JsonKey(name: 'expires_in')  int expiresIn)  $default,) {final _that = this;
switch (_that) {
case _DeviceCodeResponse():
return $default(_that.userCode,_that.verificationUri,_that.deviceCode,_that.interval,_that.expiresIn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_code')  String userCode, @JsonKey(name: 'verification_uri')  String verificationUri, @JsonKey(name: 'device_code')  String deviceCode,  int interval, @JsonKey(name: 'expires_in')  int expiresIn)?  $default,) {final _that = this;
switch (_that) {
case _DeviceCodeResponse() when $default != null:
return $default(_that.userCode,_that.verificationUri,_that.deviceCode,_that.interval,_that.expiresIn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceCodeResponse implements DeviceCodeResponse {
  const _DeviceCodeResponse({@JsonKey(name: 'user_code') required this.userCode, @JsonKey(name: 'verification_uri') required this.verificationUri, @JsonKey(name: 'device_code') required this.deviceCode, required this.interval, @JsonKey(name: 'expires_in') required this.expiresIn});
  factory _DeviceCodeResponse.fromJson(Map<String, dynamic> json) => _$DeviceCodeResponseFromJson(json);

@override@JsonKey(name: 'user_code') final  String userCode;
@override@JsonKey(name: 'verification_uri') final  String verificationUri;
@override@JsonKey(name: 'device_code') final  String deviceCode;
@override final  int interval;
@override@JsonKey(name: 'expires_in') final  int expiresIn;

/// Create a copy of DeviceCodeResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceCodeResponseCopyWith<_DeviceCodeResponse> get copyWith => __$DeviceCodeResponseCopyWithImpl<_DeviceCodeResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceCodeResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceCodeResponse&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.verificationUri, verificationUri) || other.verificationUri == verificationUri)&&(identical(other.deviceCode, deviceCode) || other.deviceCode == deviceCode)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userCode,verificationUri,deviceCode,interval,expiresIn);

@override
String toString() {
  return 'DeviceCodeResponse(userCode: $userCode, verificationUri: $verificationUri, deviceCode: $deviceCode, interval: $interval, expiresIn: $expiresIn)';
}


}

/// @nodoc
abstract mixin class _$DeviceCodeResponseCopyWith<$Res> implements $DeviceCodeResponseCopyWith<$Res> {
  factory _$DeviceCodeResponseCopyWith(_DeviceCodeResponse value, $Res Function(_DeviceCodeResponse) _then) = __$DeviceCodeResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_code') String userCode,@JsonKey(name: 'verification_uri') String verificationUri,@JsonKey(name: 'device_code') String deviceCode, int interval,@JsonKey(name: 'expires_in') int expiresIn
});




}
/// @nodoc
class __$DeviceCodeResponseCopyWithImpl<$Res>
    implements _$DeviceCodeResponseCopyWith<$Res> {
  __$DeviceCodeResponseCopyWithImpl(this._self, this._then);

  final _DeviceCodeResponse _self;
  final $Res Function(_DeviceCodeResponse) _then;

/// Create a copy of DeviceCodeResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userCode = null,Object? verificationUri = null,Object? deviceCode = null,Object? interval = null,Object? expiresIn = null,}) {
  return _then(_DeviceCodeResponse(
userCode: null == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String,verificationUri: null == verificationUri ? _self.verificationUri : verificationUri // ignore: cast_nullable_to_non_nullable
as String,deviceCode: null == deviceCode ? _self.deviceCode : deviceCode // ignore: cast_nullable_to_non_nullable
as String,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
