// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_file_scan_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProjectFileScanFailure {

 String get message;
/// Create a copy of ProjectFileScanFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectFileScanFailureCopyWith<ProjectFileScanFailure> get copyWith => _$ProjectFileScanFailureCopyWithImpl<ProjectFileScanFailure>(this as ProjectFileScanFailure, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectFileScanFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ProjectFileScanFailure(message: $message)';
}


}

/// @nodoc
abstract mixin class $ProjectFileScanFailureCopyWith<$Res>  {
  factory $ProjectFileScanFailureCopyWith(ProjectFileScanFailure value, $Res Function(ProjectFileScanFailure) _then) = _$ProjectFileScanFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ProjectFileScanFailureCopyWithImpl<$Res>
    implements $ProjectFileScanFailureCopyWith<$Res> {
  _$ProjectFileScanFailureCopyWithImpl(this._self, this._then);

  final ProjectFileScanFailure _self;
  final $Res Function(ProjectFileScanFailure) _then;

/// Create a copy of ProjectFileScanFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectFileScanFailure].
extension ProjectFileScanFailurePatterns on ProjectFileScanFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectFileScanScan value)?  scan,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectFileScanScan() when scan != null:
return scan(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectFileScanScan value)  scan,}){
final _that = this;
switch (_that) {
case ProjectFileScanScan():
return scan(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectFileScanScan value)?  scan,}){
final _that = this;
switch (_that) {
case ProjectFileScanScan() when scan != null:
return scan(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  scan,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectFileScanScan() when scan != null:
return scan(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  scan,}) {final _that = this;
switch (_that) {
case ProjectFileScanScan():
return scan(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  scan,}) {final _that = this;
switch (_that) {
case ProjectFileScanScan() when scan != null:
return scan(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ProjectFileScanScan implements ProjectFileScanFailure {
  const ProjectFileScanScan(this.message);
  

@override final  String message;

/// Create a copy of ProjectFileScanFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectFileScanScanCopyWith<ProjectFileScanScan> get copyWith => _$ProjectFileScanScanCopyWithImpl<ProjectFileScanScan>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectFileScanScan&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ProjectFileScanFailure.scan(message: $message)';
}


}

/// @nodoc
abstract mixin class $ProjectFileScanScanCopyWith<$Res> implements $ProjectFileScanFailureCopyWith<$Res> {
  factory $ProjectFileScanScanCopyWith(ProjectFileScanScan value, $Res Function(ProjectFileScanScan) _then) = _$ProjectFileScanScanCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ProjectFileScanScanCopyWithImpl<$Res>
    implements $ProjectFileScanScanCopyWith<$Res> {
  _$ProjectFileScanScanCopyWithImpl(this._self, this._then);

  final ProjectFileScanScan _self;
  final $Res Function(ProjectFileScanScan) _then;

/// Create a copy of ProjectFileScanFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ProjectFileScanScan(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
