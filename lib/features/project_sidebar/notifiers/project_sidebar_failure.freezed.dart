// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_sidebar_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProjectSidebarFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSidebarFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectSidebarFailure()';
}


}

/// @nodoc
class $ProjectSidebarFailureCopyWith<$Res>  {
$ProjectSidebarFailureCopyWith(ProjectSidebarFailure _, $Res Function(ProjectSidebarFailure) __);
}


/// Adds pattern-matching-related methods to [ProjectSidebarFailure].
extension ProjectSidebarFailurePatterns on ProjectSidebarFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectSidebarDuplicatePath value)?  duplicatePath,TResult Function( ProjectSidebarInvalidPath value)?  invalidPath,TResult Function( ProjectSidebarPermissionDenied value)?  permissionDenied,TResult Function( ProjectSidebarStorageError value)?  storageError,TResult Function( ProjectSidebarUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectSidebarDuplicatePath() when duplicatePath != null:
return duplicatePath(_that);case ProjectSidebarInvalidPath() when invalidPath != null:
return invalidPath(_that);case ProjectSidebarPermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case ProjectSidebarStorageError() when storageError != null:
return storageError(_that);case ProjectSidebarUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectSidebarDuplicatePath value)  duplicatePath,required TResult Function( ProjectSidebarInvalidPath value)  invalidPath,required TResult Function( ProjectSidebarPermissionDenied value)  permissionDenied,required TResult Function( ProjectSidebarStorageError value)  storageError,required TResult Function( ProjectSidebarUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case ProjectSidebarDuplicatePath():
return duplicatePath(_that);case ProjectSidebarInvalidPath():
return invalidPath(_that);case ProjectSidebarPermissionDenied():
return permissionDenied(_that);case ProjectSidebarStorageError():
return storageError(_that);case ProjectSidebarUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectSidebarDuplicatePath value)?  duplicatePath,TResult? Function( ProjectSidebarInvalidPath value)?  invalidPath,TResult? Function( ProjectSidebarPermissionDenied value)?  permissionDenied,TResult? Function( ProjectSidebarStorageError value)?  storageError,TResult? Function( ProjectSidebarUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case ProjectSidebarDuplicatePath() when duplicatePath != null:
return duplicatePath(_that);case ProjectSidebarInvalidPath() when invalidPath != null:
return invalidPath(_that);case ProjectSidebarPermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case ProjectSidebarStorageError() when storageError != null:
return storageError(_that);case ProjectSidebarUnknownError() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String path)?  duplicatePath,TResult Function( String reason)?  invalidPath,TResult Function( String path)?  permissionDenied,TResult Function( String message)?  storageError,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectSidebarDuplicatePath() when duplicatePath != null:
return duplicatePath(_that.path);case ProjectSidebarInvalidPath() when invalidPath != null:
return invalidPath(_that.reason);case ProjectSidebarPermissionDenied() when permissionDenied != null:
return permissionDenied(_that.path);case ProjectSidebarStorageError() when storageError != null:
return storageError(_that.message);case ProjectSidebarUnknownError() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String path)  duplicatePath,required TResult Function( String reason)  invalidPath,required TResult Function( String path)  permissionDenied,required TResult Function( String message)  storageError,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case ProjectSidebarDuplicatePath():
return duplicatePath(_that.path);case ProjectSidebarInvalidPath():
return invalidPath(_that.reason);case ProjectSidebarPermissionDenied():
return permissionDenied(_that.path);case ProjectSidebarStorageError():
return storageError(_that.message);case ProjectSidebarUnknownError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String path)?  duplicatePath,TResult? Function( String reason)?  invalidPath,TResult? Function( String path)?  permissionDenied,TResult? Function( String message)?  storageError,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case ProjectSidebarDuplicatePath() when duplicatePath != null:
return duplicatePath(_that.path);case ProjectSidebarInvalidPath() when invalidPath != null:
return invalidPath(_that.reason);case ProjectSidebarPermissionDenied() when permissionDenied != null:
return permissionDenied(_that.path);case ProjectSidebarStorageError() when storageError != null:
return storageError(_that.message);case ProjectSidebarUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class ProjectSidebarDuplicatePath implements ProjectSidebarFailure {
  const ProjectSidebarDuplicatePath(this.path);
  

 final  String path;

/// Create a copy of ProjectSidebarFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSidebarDuplicatePathCopyWith<ProjectSidebarDuplicatePath> get copyWith => _$ProjectSidebarDuplicatePathCopyWithImpl<ProjectSidebarDuplicatePath>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSidebarDuplicatePath&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,path);

@override
String toString() {
  return 'ProjectSidebarFailure.duplicatePath(path: $path)';
}


}

/// @nodoc
abstract mixin class $ProjectSidebarDuplicatePathCopyWith<$Res> implements $ProjectSidebarFailureCopyWith<$Res> {
  factory $ProjectSidebarDuplicatePathCopyWith(ProjectSidebarDuplicatePath value, $Res Function(ProjectSidebarDuplicatePath) _then) = _$ProjectSidebarDuplicatePathCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$ProjectSidebarDuplicatePathCopyWithImpl<$Res>
    implements $ProjectSidebarDuplicatePathCopyWith<$Res> {
  _$ProjectSidebarDuplicatePathCopyWithImpl(this._self, this._then);

  final ProjectSidebarDuplicatePath _self;
  final $Res Function(ProjectSidebarDuplicatePath) _then;

/// Create a copy of ProjectSidebarFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(ProjectSidebarDuplicatePath(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProjectSidebarInvalidPath implements ProjectSidebarFailure {
  const ProjectSidebarInvalidPath(this.reason);
  

 final  String reason;

/// Create a copy of ProjectSidebarFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSidebarInvalidPathCopyWith<ProjectSidebarInvalidPath> get copyWith => _$ProjectSidebarInvalidPathCopyWithImpl<ProjectSidebarInvalidPath>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSidebarInvalidPath&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'ProjectSidebarFailure.invalidPath(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $ProjectSidebarInvalidPathCopyWith<$Res> implements $ProjectSidebarFailureCopyWith<$Res> {
  factory $ProjectSidebarInvalidPathCopyWith(ProjectSidebarInvalidPath value, $Res Function(ProjectSidebarInvalidPath) _then) = _$ProjectSidebarInvalidPathCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$ProjectSidebarInvalidPathCopyWithImpl<$Res>
    implements $ProjectSidebarInvalidPathCopyWith<$Res> {
  _$ProjectSidebarInvalidPathCopyWithImpl(this._self, this._then);

  final ProjectSidebarInvalidPath _self;
  final $Res Function(ProjectSidebarInvalidPath) _then;

/// Create a copy of ProjectSidebarFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(ProjectSidebarInvalidPath(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProjectSidebarPermissionDenied implements ProjectSidebarFailure {
  const ProjectSidebarPermissionDenied(this.path);
  

 final  String path;

/// Create a copy of ProjectSidebarFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSidebarPermissionDeniedCopyWith<ProjectSidebarPermissionDenied> get copyWith => _$ProjectSidebarPermissionDeniedCopyWithImpl<ProjectSidebarPermissionDenied>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSidebarPermissionDenied&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,path);

@override
String toString() {
  return 'ProjectSidebarFailure.permissionDenied(path: $path)';
}


}

/// @nodoc
abstract mixin class $ProjectSidebarPermissionDeniedCopyWith<$Res> implements $ProjectSidebarFailureCopyWith<$Res> {
  factory $ProjectSidebarPermissionDeniedCopyWith(ProjectSidebarPermissionDenied value, $Res Function(ProjectSidebarPermissionDenied) _then) = _$ProjectSidebarPermissionDeniedCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$ProjectSidebarPermissionDeniedCopyWithImpl<$Res>
    implements $ProjectSidebarPermissionDeniedCopyWith<$Res> {
  _$ProjectSidebarPermissionDeniedCopyWithImpl(this._self, this._then);

  final ProjectSidebarPermissionDenied _self;
  final $Res Function(ProjectSidebarPermissionDenied) _then;

/// Create a copy of ProjectSidebarFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(ProjectSidebarPermissionDenied(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProjectSidebarStorageError implements ProjectSidebarFailure {
  const ProjectSidebarStorageError(this.message);
  

 final  String message;

/// Create a copy of ProjectSidebarFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSidebarStorageErrorCopyWith<ProjectSidebarStorageError> get copyWith => _$ProjectSidebarStorageErrorCopyWithImpl<ProjectSidebarStorageError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSidebarStorageError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ProjectSidebarFailure.storageError(message: $message)';
}


}

/// @nodoc
abstract mixin class $ProjectSidebarStorageErrorCopyWith<$Res> implements $ProjectSidebarFailureCopyWith<$Res> {
  factory $ProjectSidebarStorageErrorCopyWith(ProjectSidebarStorageError value, $Res Function(ProjectSidebarStorageError) _then) = _$ProjectSidebarStorageErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ProjectSidebarStorageErrorCopyWithImpl<$Res>
    implements $ProjectSidebarStorageErrorCopyWith<$Res> {
  _$ProjectSidebarStorageErrorCopyWithImpl(this._self, this._then);

  final ProjectSidebarStorageError _self;
  final $Res Function(ProjectSidebarStorageError) _then;

/// Create a copy of ProjectSidebarFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ProjectSidebarStorageError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProjectSidebarUnknownError implements ProjectSidebarFailure {
  const ProjectSidebarUnknownError(this.error);
  

 final  Object error;

/// Create a copy of ProjectSidebarFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSidebarUnknownErrorCopyWith<ProjectSidebarUnknownError> get copyWith => _$ProjectSidebarUnknownErrorCopyWithImpl<ProjectSidebarUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSidebarUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ProjectSidebarFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $ProjectSidebarUnknownErrorCopyWith<$Res> implements $ProjectSidebarFailureCopyWith<$Res> {
  factory $ProjectSidebarUnknownErrorCopyWith(ProjectSidebarUnknownError value, $Res Function(ProjectSidebarUnknownError) _then) = _$ProjectSidebarUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$ProjectSidebarUnknownErrorCopyWithImpl<$Res>
    implements $ProjectSidebarUnknownErrorCopyWith<$Res> {
  _$ProjectSidebarUnknownErrorCopyWithImpl(this._self, this._then);

  final ProjectSidebarUnknownError _self;
  final $Res Function(ProjectSidebarUnknownError) _then;

/// Create a copy of ProjectSidebarFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(ProjectSidebarUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
