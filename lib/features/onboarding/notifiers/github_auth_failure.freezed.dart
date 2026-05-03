// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_auth_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GitHubAuthFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubAuthFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GitHubAuthFailure()';
}


}

/// @nodoc
class $GitHubAuthFailureCopyWith<$Res>  {
$GitHubAuthFailureCopyWith(GitHubAuthFailure _, $Res Function(GitHubAuthFailure) __);
}


/// Adds pattern-matching-related methods to [GitHubAuthFailure].
extension GitHubAuthFailurePatterns on GitHubAuthFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GitHubAuthTokenRevoked value)?  tokenRevoked,TResult Function( GitHubAuthRequestFailed value)?  requestFailed,TResult Function( GitHubAuthPollFailed value)?  pollFailed,TResult Function( GitHubAuthSignOutFailed value)?  signOutFailed,TResult Function( GitHubAuthUnknown value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GitHubAuthTokenRevoked() when tokenRevoked != null:
return tokenRevoked(_that);case GitHubAuthRequestFailed() when requestFailed != null:
return requestFailed(_that);case GitHubAuthPollFailed() when pollFailed != null:
return pollFailed(_that);case GitHubAuthSignOutFailed() when signOutFailed != null:
return signOutFailed(_that);case GitHubAuthUnknown() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GitHubAuthTokenRevoked value)  tokenRevoked,required TResult Function( GitHubAuthRequestFailed value)  requestFailed,required TResult Function( GitHubAuthPollFailed value)  pollFailed,required TResult Function( GitHubAuthSignOutFailed value)  signOutFailed,required TResult Function( GitHubAuthUnknown value)  unknown,}){
final _that = this;
switch (_that) {
case GitHubAuthTokenRevoked():
return tokenRevoked(_that);case GitHubAuthRequestFailed():
return requestFailed(_that);case GitHubAuthPollFailed():
return pollFailed(_that);case GitHubAuthSignOutFailed():
return signOutFailed(_that);case GitHubAuthUnknown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GitHubAuthTokenRevoked value)?  tokenRevoked,TResult? Function( GitHubAuthRequestFailed value)?  requestFailed,TResult? Function( GitHubAuthPollFailed value)?  pollFailed,TResult? Function( GitHubAuthSignOutFailed value)?  signOutFailed,TResult? Function( GitHubAuthUnknown value)?  unknown,}){
final _that = this;
switch (_that) {
case GitHubAuthTokenRevoked() when tokenRevoked != null:
return tokenRevoked(_that);case GitHubAuthRequestFailed() when requestFailed != null:
return requestFailed(_that);case GitHubAuthPollFailed() when pollFailed != null:
return pollFailed(_that);case GitHubAuthSignOutFailed() when signOutFailed != null:
return signOutFailed(_that);case GitHubAuthUnknown() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  tokenRevoked,TResult Function( String message)?  requestFailed,TResult Function( String message)?  pollFailed,TResult Function( String message)?  signOutFailed,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GitHubAuthTokenRevoked() when tokenRevoked != null:
return tokenRevoked();case GitHubAuthRequestFailed() when requestFailed != null:
return requestFailed(_that.message);case GitHubAuthPollFailed() when pollFailed != null:
return pollFailed(_that.message);case GitHubAuthSignOutFailed() when signOutFailed != null:
return signOutFailed(_that.message);case GitHubAuthUnknown() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  tokenRevoked,required TResult Function( String message)  requestFailed,required TResult Function( String message)  pollFailed,required TResult Function( String message)  signOutFailed,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case GitHubAuthTokenRevoked():
return tokenRevoked();case GitHubAuthRequestFailed():
return requestFailed(_that.message);case GitHubAuthPollFailed():
return pollFailed(_that.message);case GitHubAuthSignOutFailed():
return signOutFailed(_that.message);case GitHubAuthUnknown():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  tokenRevoked,TResult? Function( String message)?  requestFailed,TResult? Function( String message)?  pollFailed,TResult? Function( String message)?  signOutFailed,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case GitHubAuthTokenRevoked() when tokenRevoked != null:
return tokenRevoked();case GitHubAuthRequestFailed() when requestFailed != null:
return requestFailed(_that.message);case GitHubAuthPollFailed() when pollFailed != null:
return pollFailed(_that.message);case GitHubAuthSignOutFailed() when signOutFailed != null:
return signOutFailed(_that.message);case GitHubAuthUnknown() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class GitHubAuthTokenRevoked implements GitHubAuthFailure {
  const GitHubAuthTokenRevoked();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubAuthTokenRevoked);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GitHubAuthFailure.tokenRevoked()';
}


}




/// @nodoc


class GitHubAuthRequestFailed implements GitHubAuthFailure {
  const GitHubAuthRequestFailed(this.message);
  

 final  String message;

/// Create a copy of GitHubAuthFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubAuthRequestFailedCopyWith<GitHubAuthRequestFailed> get copyWith => _$GitHubAuthRequestFailedCopyWithImpl<GitHubAuthRequestFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubAuthRequestFailed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'GitHubAuthFailure.requestFailed(message: $message)';
}


}

/// @nodoc
abstract mixin class $GitHubAuthRequestFailedCopyWith<$Res> implements $GitHubAuthFailureCopyWith<$Res> {
  factory $GitHubAuthRequestFailedCopyWith(GitHubAuthRequestFailed value, $Res Function(GitHubAuthRequestFailed) _then) = _$GitHubAuthRequestFailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$GitHubAuthRequestFailedCopyWithImpl<$Res>
    implements $GitHubAuthRequestFailedCopyWith<$Res> {
  _$GitHubAuthRequestFailedCopyWithImpl(this._self, this._then);

  final GitHubAuthRequestFailed _self;
  final $Res Function(GitHubAuthRequestFailed) _then;

/// Create a copy of GitHubAuthFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(GitHubAuthRequestFailed(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class GitHubAuthPollFailed implements GitHubAuthFailure {
  const GitHubAuthPollFailed(this.message);
  

 final  String message;

/// Create a copy of GitHubAuthFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubAuthPollFailedCopyWith<GitHubAuthPollFailed> get copyWith => _$GitHubAuthPollFailedCopyWithImpl<GitHubAuthPollFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubAuthPollFailed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'GitHubAuthFailure.pollFailed(message: $message)';
}


}

/// @nodoc
abstract mixin class $GitHubAuthPollFailedCopyWith<$Res> implements $GitHubAuthFailureCopyWith<$Res> {
  factory $GitHubAuthPollFailedCopyWith(GitHubAuthPollFailed value, $Res Function(GitHubAuthPollFailed) _then) = _$GitHubAuthPollFailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$GitHubAuthPollFailedCopyWithImpl<$Res>
    implements $GitHubAuthPollFailedCopyWith<$Res> {
  _$GitHubAuthPollFailedCopyWithImpl(this._self, this._then);

  final GitHubAuthPollFailed _self;
  final $Res Function(GitHubAuthPollFailed) _then;

/// Create a copy of GitHubAuthFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(GitHubAuthPollFailed(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class GitHubAuthSignOutFailed implements GitHubAuthFailure {
  const GitHubAuthSignOutFailed(this.message);
  

 final  String message;

/// Create a copy of GitHubAuthFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubAuthSignOutFailedCopyWith<GitHubAuthSignOutFailed> get copyWith => _$GitHubAuthSignOutFailedCopyWithImpl<GitHubAuthSignOutFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubAuthSignOutFailed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'GitHubAuthFailure.signOutFailed(message: $message)';
}


}

/// @nodoc
abstract mixin class $GitHubAuthSignOutFailedCopyWith<$Res> implements $GitHubAuthFailureCopyWith<$Res> {
  factory $GitHubAuthSignOutFailedCopyWith(GitHubAuthSignOutFailed value, $Res Function(GitHubAuthSignOutFailed) _then) = _$GitHubAuthSignOutFailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$GitHubAuthSignOutFailedCopyWithImpl<$Res>
    implements $GitHubAuthSignOutFailedCopyWith<$Res> {
  _$GitHubAuthSignOutFailedCopyWithImpl(this._self, this._then);

  final GitHubAuthSignOutFailed _self;
  final $Res Function(GitHubAuthSignOutFailed) _then;

/// Create a copy of GitHubAuthFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(GitHubAuthSignOutFailed(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class GitHubAuthUnknown implements GitHubAuthFailure {
  const GitHubAuthUnknown(this.error);
  

 final  Object error;

/// Create a copy of GitHubAuthFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubAuthUnknownCopyWith<GitHubAuthUnknown> get copyWith => _$GitHubAuthUnknownCopyWithImpl<GitHubAuthUnknown>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubAuthUnknown&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'GitHubAuthFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $GitHubAuthUnknownCopyWith<$Res> implements $GitHubAuthFailureCopyWith<$Res> {
  factory $GitHubAuthUnknownCopyWith(GitHubAuthUnknown value, $Res Function(GitHubAuthUnknown) _then) = _$GitHubAuthUnknownCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$GitHubAuthUnknownCopyWithImpl<$Res>
    implements $GitHubAuthUnknownCopyWith<$Res> {
  _$GitHubAuthUnknownCopyWithImpl(this._self, this._then);

  final GitHubAuthUnknown _self;
  final $Res Function(GitHubAuthUnknown) _then;

/// Create a copy of GitHubAuthFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(GitHubAuthUnknown(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
