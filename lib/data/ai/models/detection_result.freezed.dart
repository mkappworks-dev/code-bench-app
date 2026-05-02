// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'detection_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DetectionResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetectionResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DetectionResult()';
}


}

/// @nodoc
class $DetectionResultCopyWith<$Res>  {
$DetectionResultCopyWith(DetectionResult _, $Res Function(DetectionResult) __);
}


/// Adds pattern-matching-related methods to [DetectionResult].
extension DetectionResultPatterns on DetectionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DetectionInstalled value)?  installed,TResult Function( DetectionUnhealthy value)?  unhealthy,TResult Function( DetectionMissing value)?  missing,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DetectionInstalled() when installed != null:
return installed(_that);case DetectionUnhealthy() when unhealthy != null:
return unhealthy(_that);case DetectionMissing() when missing != null:
return missing(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DetectionInstalled value)  installed,required TResult Function( DetectionUnhealthy value)  unhealthy,required TResult Function( DetectionMissing value)  missing,}){
final _that = this;
switch (_that) {
case DetectionInstalled():
return installed(_that);case DetectionUnhealthy():
return unhealthy(_that);case DetectionMissing():
return missing(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DetectionInstalled value)?  installed,TResult? Function( DetectionUnhealthy value)?  unhealthy,TResult? Function( DetectionMissing value)?  missing,}){
final _that = this;
switch (_that) {
case DetectionInstalled() when installed != null:
return installed(_that);case DetectionUnhealthy() when unhealthy != null:
return unhealthy(_that);case DetectionMissing() when missing != null:
return missing(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String version)?  installed,TResult Function( String reason)?  unhealthy,TResult Function()?  missing,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DetectionInstalled() when installed != null:
return installed(_that.version);case DetectionUnhealthy() when unhealthy != null:
return unhealthy(_that.reason);case DetectionMissing() when missing != null:
return missing();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String version)  installed,required TResult Function( String reason)  unhealthy,required TResult Function()  missing,}) {final _that = this;
switch (_that) {
case DetectionInstalled():
return installed(_that.version);case DetectionUnhealthy():
return unhealthy(_that.reason);case DetectionMissing():
return missing();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String version)?  installed,TResult? Function( String reason)?  unhealthy,TResult? Function()?  missing,}) {final _that = this;
switch (_that) {
case DetectionInstalled() when installed != null:
return installed(_that.version);case DetectionUnhealthy() when unhealthy != null:
return unhealthy(_that.reason);case DetectionMissing() when missing != null:
return missing();case _:
  return null;

}
}

}

/// @nodoc


class DetectionInstalled implements DetectionResult {
  const DetectionInstalled(this.version);
  

 final  String version;

/// Create a copy of DetectionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetectionInstalledCopyWith<DetectionInstalled> get copyWith => _$DetectionInstalledCopyWithImpl<DetectionInstalled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetectionInstalled&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,version);

@override
String toString() {
  return 'DetectionResult.installed(version: $version)';
}


}

/// @nodoc
abstract mixin class $DetectionInstalledCopyWith<$Res> implements $DetectionResultCopyWith<$Res> {
  factory $DetectionInstalledCopyWith(DetectionInstalled value, $Res Function(DetectionInstalled) _then) = _$DetectionInstalledCopyWithImpl;
@useResult
$Res call({
 String version
});




}
/// @nodoc
class _$DetectionInstalledCopyWithImpl<$Res>
    implements $DetectionInstalledCopyWith<$Res> {
  _$DetectionInstalledCopyWithImpl(this._self, this._then);

  final DetectionInstalled _self;
  final $Res Function(DetectionInstalled) _then;

/// Create a copy of DetectionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? version = null,}) {
  return _then(DetectionInstalled(
null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DetectionUnhealthy implements DetectionResult {
  const DetectionUnhealthy(this.reason);
  

 final  String reason;

/// Create a copy of DetectionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetectionUnhealthyCopyWith<DetectionUnhealthy> get copyWith => _$DetectionUnhealthyCopyWithImpl<DetectionUnhealthy>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetectionUnhealthy&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'DetectionResult.unhealthy(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $DetectionUnhealthyCopyWith<$Res> implements $DetectionResultCopyWith<$Res> {
  factory $DetectionUnhealthyCopyWith(DetectionUnhealthy value, $Res Function(DetectionUnhealthy) _then) = _$DetectionUnhealthyCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$DetectionUnhealthyCopyWithImpl<$Res>
    implements $DetectionUnhealthyCopyWith<$Res> {
  _$DetectionUnhealthyCopyWithImpl(this._self, this._then);

  final DetectionUnhealthy _self;
  final $Res Function(DetectionUnhealthy) _then;

/// Create a copy of DetectionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(DetectionUnhealthy(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DetectionMissing implements DetectionResult {
  const DetectionMissing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetectionMissing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DetectionResult.missing()';
}


}




// dart format on
