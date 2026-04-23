// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cli_detection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CliDetection {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CliDetection);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CliDetection()';
}


}

/// @nodoc
class $CliDetectionCopyWith<$Res>  {
$CliDetectionCopyWith(CliDetection _, $Res Function(CliDetection) __);
}


/// Adds pattern-matching-related methods to [CliDetection].
extension CliDetectionPatterns on CliDetection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CliNotInstalled value)?  notInstalled,TResult Function( CliInstalled value)?  installed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CliNotInstalled() when notInstalled != null:
return notInstalled(_that);case CliInstalled() when installed != null:
return installed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CliNotInstalled value)  notInstalled,required TResult Function( CliInstalled value)  installed,}){
final _that = this;
switch (_that) {
case CliNotInstalled():
return notInstalled(_that);case CliInstalled():
return installed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CliNotInstalled value)?  notInstalled,TResult? Function( CliInstalled value)?  installed,}){
final _that = this;
switch (_that) {
case CliNotInstalled() when notInstalled != null:
return notInstalled(_that);case CliInstalled() when installed != null:
return installed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  notInstalled,TResult Function( String version,  String binaryPath,  CliAuthStatus authStatus,  DateTime checkedAt)?  installed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CliNotInstalled() when notInstalled != null:
return notInstalled();case CliInstalled() when installed != null:
return installed(_that.version,_that.binaryPath,_that.authStatus,_that.checkedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  notInstalled,required TResult Function( String version,  String binaryPath,  CliAuthStatus authStatus,  DateTime checkedAt)  installed,}) {final _that = this;
switch (_that) {
case CliNotInstalled():
return notInstalled();case CliInstalled():
return installed(_that.version,_that.binaryPath,_that.authStatus,_that.checkedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  notInstalled,TResult? Function( String version,  String binaryPath,  CliAuthStatus authStatus,  DateTime checkedAt)?  installed,}) {final _that = this;
switch (_that) {
case CliNotInstalled() when notInstalled != null:
return notInstalled();case CliInstalled() when installed != null:
return installed(_that.version,_that.binaryPath,_that.authStatus,_that.checkedAt);case _:
  return null;

}
}

}

/// @nodoc


class CliNotInstalled implements CliDetection {
  const CliNotInstalled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CliNotInstalled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CliDetection.notInstalled()';
}


}




/// @nodoc


class CliInstalled implements CliDetection {
  const CliInstalled({required this.version, required this.binaryPath, required this.authStatus, required this.checkedAt});
  

 final  String version;
 final  String binaryPath;
 final  CliAuthStatus authStatus;
 final  DateTime checkedAt;

/// Create a copy of CliDetection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CliInstalledCopyWith<CliInstalled> get copyWith => _$CliInstalledCopyWithImpl<CliInstalled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CliInstalled&&(identical(other.version, version) || other.version == version)&&(identical(other.binaryPath, binaryPath) || other.binaryPath == binaryPath)&&(identical(other.authStatus, authStatus) || other.authStatus == authStatus)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt));
}


@override
int get hashCode => Object.hash(runtimeType,version,binaryPath,authStatus,checkedAt);

@override
String toString() {
  return 'CliDetection.installed(version: $version, binaryPath: $binaryPath, authStatus: $authStatus, checkedAt: $checkedAt)';
}


}

/// @nodoc
abstract mixin class $CliInstalledCopyWith<$Res> implements $CliDetectionCopyWith<$Res> {
  factory $CliInstalledCopyWith(CliInstalled value, $Res Function(CliInstalled) _then) = _$CliInstalledCopyWithImpl;
@useResult
$Res call({
 String version, String binaryPath, CliAuthStatus authStatus, DateTime checkedAt
});




}
/// @nodoc
class _$CliInstalledCopyWithImpl<$Res>
    implements $CliInstalledCopyWith<$Res> {
  _$CliInstalledCopyWithImpl(this._self, this._then);

  final CliInstalled _self;
  final $Res Function(CliInstalled) _then;

/// Create a copy of CliDetection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? version = null,Object? binaryPath = null,Object? authStatus = null,Object? checkedAt = null,}) {
  return _then(CliInstalled(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,binaryPath: null == binaryPath ? _self.binaryPath : binaryPath // ignore: cast_nullable_to_non_nullable
as String,authStatus: null == authStatus ? _self.authStatus : authStatus // ignore: cast_nullable_to_non_nullable
as CliAuthStatus,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
