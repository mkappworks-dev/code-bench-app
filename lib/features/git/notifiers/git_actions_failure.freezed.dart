// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'git_actions_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GitActionsFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitActionsFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GitActionsFailure()';
}


}

/// @nodoc
class $GitActionsFailureCopyWith<$Res>  {
$GitActionsFailureCopyWith(GitActionsFailure _, $Res Function(GitActionsFailure) __);
}


/// Adds pattern-matching-related methods to [GitActionsFailure].
extension GitActionsFailurePatterns on GitActionsFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GitActionsGitError value)?  gitError,TResult Function( GitActionsNoUpstream value)?  noUpstream,TResult Function( GitActionsAuthFailed value)?  authFailed,TResult Function( GitActionsConflict value)?  conflict,TResult Function( GitActionsUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GitActionsGitError() when gitError != null:
return gitError(_that);case GitActionsNoUpstream() when noUpstream != null:
return noUpstream(_that);case GitActionsAuthFailed() when authFailed != null:
return authFailed(_that);case GitActionsConflict() when conflict != null:
return conflict(_that);case GitActionsUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GitActionsGitError value)  gitError,required TResult Function( GitActionsNoUpstream value)  noUpstream,required TResult Function( GitActionsAuthFailed value)  authFailed,required TResult Function( GitActionsConflict value)  conflict,required TResult Function( GitActionsUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case GitActionsGitError():
return gitError(_that);case GitActionsNoUpstream():
return noUpstream(_that);case GitActionsAuthFailed():
return authFailed(_that);case GitActionsConflict():
return conflict(_that);case GitActionsUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GitActionsGitError value)?  gitError,TResult? Function( GitActionsNoUpstream value)?  noUpstream,TResult? Function( GitActionsAuthFailed value)?  authFailed,TResult? Function( GitActionsConflict value)?  conflict,TResult? Function( GitActionsUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case GitActionsGitError() when gitError != null:
return gitError(_that);case GitActionsNoUpstream() when noUpstream != null:
return noUpstream(_that);case GitActionsAuthFailed() when authFailed != null:
return authFailed(_that);case GitActionsConflict() when conflict != null:
return conflict(_that);case GitActionsUnknownError() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  gitError,TResult Function( String branch)?  noUpstream,TResult Function()?  authFailed,TResult Function()?  conflict,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GitActionsGitError() when gitError != null:
return gitError(_that.message);case GitActionsNoUpstream() when noUpstream != null:
return noUpstream(_that.branch);case GitActionsAuthFailed() when authFailed != null:
return authFailed();case GitActionsConflict() when conflict != null:
return conflict();case GitActionsUnknownError() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  gitError,required TResult Function( String branch)  noUpstream,required TResult Function()  authFailed,required TResult Function()  conflict,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case GitActionsGitError():
return gitError(_that.message);case GitActionsNoUpstream():
return noUpstream(_that.branch);case GitActionsAuthFailed():
return authFailed();case GitActionsConflict():
return conflict();case GitActionsUnknownError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  gitError,TResult? Function( String branch)?  noUpstream,TResult? Function()?  authFailed,TResult? Function()?  conflict,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case GitActionsGitError() when gitError != null:
return gitError(_that.message);case GitActionsNoUpstream() when noUpstream != null:
return noUpstream(_that.branch);case GitActionsAuthFailed() when authFailed != null:
return authFailed();case GitActionsConflict() when conflict != null:
return conflict();case GitActionsUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class GitActionsGitError implements GitActionsFailure {
  const GitActionsGitError(this.message);
  

 final  String message;

/// Create a copy of GitActionsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitActionsGitErrorCopyWith<GitActionsGitError> get copyWith => _$GitActionsGitErrorCopyWithImpl<GitActionsGitError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitActionsGitError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'GitActionsFailure.gitError(message: $message)';
}


}

/// @nodoc
abstract mixin class $GitActionsGitErrorCopyWith<$Res> implements $GitActionsFailureCopyWith<$Res> {
  factory $GitActionsGitErrorCopyWith(GitActionsGitError value, $Res Function(GitActionsGitError) _then) = _$GitActionsGitErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$GitActionsGitErrorCopyWithImpl<$Res>
    implements $GitActionsGitErrorCopyWith<$Res> {
  _$GitActionsGitErrorCopyWithImpl(this._self, this._then);

  final GitActionsGitError _self;
  final $Res Function(GitActionsGitError) _then;

/// Create a copy of GitActionsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(GitActionsGitError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class GitActionsNoUpstream implements GitActionsFailure {
  const GitActionsNoUpstream(this.branch);
  

 final  String branch;

/// Create a copy of GitActionsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitActionsNoUpstreamCopyWith<GitActionsNoUpstream> get copyWith => _$GitActionsNoUpstreamCopyWithImpl<GitActionsNoUpstream>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitActionsNoUpstream&&(identical(other.branch, branch) || other.branch == branch));
}


@override
int get hashCode => Object.hash(runtimeType,branch);

@override
String toString() {
  return 'GitActionsFailure.noUpstream(branch: $branch)';
}


}

/// @nodoc
abstract mixin class $GitActionsNoUpstreamCopyWith<$Res> implements $GitActionsFailureCopyWith<$Res> {
  factory $GitActionsNoUpstreamCopyWith(GitActionsNoUpstream value, $Res Function(GitActionsNoUpstream) _then) = _$GitActionsNoUpstreamCopyWithImpl;
@useResult
$Res call({
 String branch
});




}
/// @nodoc
class _$GitActionsNoUpstreamCopyWithImpl<$Res>
    implements $GitActionsNoUpstreamCopyWith<$Res> {
  _$GitActionsNoUpstreamCopyWithImpl(this._self, this._then);

  final GitActionsNoUpstream _self;
  final $Res Function(GitActionsNoUpstream) _then;

/// Create a copy of GitActionsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? branch = null,}) {
  return _then(GitActionsNoUpstream(
null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class GitActionsAuthFailed implements GitActionsFailure {
  const GitActionsAuthFailed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitActionsAuthFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GitActionsFailure.authFailed()';
}


}




/// @nodoc


class GitActionsConflict implements GitActionsFailure {
  const GitActionsConflict();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitActionsConflict);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GitActionsFailure.conflict()';
}


}




/// @nodoc


class GitActionsUnknownError implements GitActionsFailure {
  const GitActionsUnknownError(this.error);
  

 final  Object error;

/// Create a copy of GitActionsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitActionsUnknownErrorCopyWith<GitActionsUnknownError> get copyWith => _$GitActionsUnknownErrorCopyWithImpl<GitActionsUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitActionsUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'GitActionsFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $GitActionsUnknownErrorCopyWith<$Res> implements $GitActionsFailureCopyWith<$Res> {
  factory $GitActionsUnknownErrorCopyWith(GitActionsUnknownError value, $Res Function(GitActionsUnknownError) _then) = _$GitActionsUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$GitActionsUnknownErrorCopyWithImpl<$Res>
    implements $GitActionsUnknownErrorCopyWith<$Res> {
  _$GitActionsUnknownErrorCopyWithImpl(this._self, this._then);

  final GitActionsUnknownError _self;
  final $Res Function(GitActionsUnknownError) _then;

/// Create a copy of GitActionsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(GitActionsUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
