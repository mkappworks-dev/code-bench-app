// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'claude_cli_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClaudeCliFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClaudeCliFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ClaudeCliFailure()';
}


}

/// @nodoc
class $ClaudeCliFailureCopyWith<$Res>  {
$ClaudeCliFailureCopyWith(ClaudeCliFailure _, $Res Function(ClaudeCliFailure) __);
}


/// Adds pattern-matching-related methods to [ClaudeCliFailure].
extension ClaudeCliFailurePatterns on ClaudeCliFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ClaudeCliNotInstalled value)?  notInstalled,TResult Function( ClaudeCliUnauthenticated value)?  unauthenticated,TResult Function( ClaudeCliCrashed value)?  crashed,TResult Function( ClaudeCliTimedOut value)?  timedOut,TResult Function( ClaudeCliStreamParseFailed value)?  streamParseFailed,TResult Function( ClaudeCliCancelled value)?  cancelled,TResult Function( ClaudeCliUnknown value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ClaudeCliNotInstalled() when notInstalled != null:
return notInstalled(_that);case ClaudeCliUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case ClaudeCliCrashed() when crashed != null:
return crashed(_that);case ClaudeCliTimedOut() when timedOut != null:
return timedOut(_that);case ClaudeCliStreamParseFailed() when streamParseFailed != null:
return streamParseFailed(_that);case ClaudeCliCancelled() when cancelled != null:
return cancelled(_that);case ClaudeCliUnknown() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ClaudeCliNotInstalled value)  notInstalled,required TResult Function( ClaudeCliUnauthenticated value)  unauthenticated,required TResult Function( ClaudeCliCrashed value)  crashed,required TResult Function( ClaudeCliTimedOut value)  timedOut,required TResult Function( ClaudeCliStreamParseFailed value)  streamParseFailed,required TResult Function( ClaudeCliCancelled value)  cancelled,required TResult Function( ClaudeCliUnknown value)  unknown,}){
final _that = this;
switch (_that) {
case ClaudeCliNotInstalled():
return notInstalled(_that);case ClaudeCliUnauthenticated():
return unauthenticated(_that);case ClaudeCliCrashed():
return crashed(_that);case ClaudeCliTimedOut():
return timedOut(_that);case ClaudeCliStreamParseFailed():
return streamParseFailed(_that);case ClaudeCliCancelled():
return cancelled(_that);case ClaudeCliUnknown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ClaudeCliNotInstalled value)?  notInstalled,TResult? Function( ClaudeCliUnauthenticated value)?  unauthenticated,TResult? Function( ClaudeCliCrashed value)?  crashed,TResult? Function( ClaudeCliTimedOut value)?  timedOut,TResult? Function( ClaudeCliStreamParseFailed value)?  streamParseFailed,TResult? Function( ClaudeCliCancelled value)?  cancelled,TResult? Function( ClaudeCliUnknown value)?  unknown,}){
final _that = this;
switch (_that) {
case ClaudeCliNotInstalled() when notInstalled != null:
return notInstalled(_that);case ClaudeCliUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case ClaudeCliCrashed() when crashed != null:
return crashed(_that);case ClaudeCliTimedOut() when timedOut != null:
return timedOut(_that);case ClaudeCliStreamParseFailed() when streamParseFailed != null:
return streamParseFailed(_that);case ClaudeCliCancelled() when cancelled != null:
return cancelled(_that);case ClaudeCliUnknown() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  notInstalled,TResult Function()?  unauthenticated,TResult Function( int exitCode,  String stderr)?  crashed,TResult Function()?  timedOut,TResult Function( String line,  Object error)?  streamParseFailed,TResult Function()?  cancelled,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ClaudeCliNotInstalled() when notInstalled != null:
return notInstalled();case ClaudeCliUnauthenticated() when unauthenticated != null:
return unauthenticated();case ClaudeCliCrashed() when crashed != null:
return crashed(_that.exitCode,_that.stderr);case ClaudeCliTimedOut() when timedOut != null:
return timedOut();case ClaudeCliStreamParseFailed() when streamParseFailed != null:
return streamParseFailed(_that.line,_that.error);case ClaudeCliCancelled() when cancelled != null:
return cancelled();case ClaudeCliUnknown() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  notInstalled,required TResult Function()  unauthenticated,required TResult Function( int exitCode,  String stderr)  crashed,required TResult Function()  timedOut,required TResult Function( String line,  Object error)  streamParseFailed,required TResult Function()  cancelled,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case ClaudeCliNotInstalled():
return notInstalled();case ClaudeCliUnauthenticated():
return unauthenticated();case ClaudeCliCrashed():
return crashed(_that.exitCode,_that.stderr);case ClaudeCliTimedOut():
return timedOut();case ClaudeCliStreamParseFailed():
return streamParseFailed(_that.line,_that.error);case ClaudeCliCancelled():
return cancelled();case ClaudeCliUnknown():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  notInstalled,TResult? Function()?  unauthenticated,TResult? Function( int exitCode,  String stderr)?  crashed,TResult? Function()?  timedOut,TResult? Function( String line,  Object error)?  streamParseFailed,TResult? Function()?  cancelled,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case ClaudeCliNotInstalled() when notInstalled != null:
return notInstalled();case ClaudeCliUnauthenticated() when unauthenticated != null:
return unauthenticated();case ClaudeCliCrashed() when crashed != null:
return crashed(_that.exitCode,_that.stderr);case ClaudeCliTimedOut() when timedOut != null:
return timedOut();case ClaudeCliStreamParseFailed() when streamParseFailed != null:
return streamParseFailed(_that.line,_that.error);case ClaudeCliCancelled() when cancelled != null:
return cancelled();case ClaudeCliUnknown() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class ClaudeCliNotInstalled implements ClaudeCliFailure {
  const ClaudeCliNotInstalled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClaudeCliNotInstalled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ClaudeCliFailure.notInstalled()';
}


}




/// @nodoc


class ClaudeCliUnauthenticated implements ClaudeCliFailure {
  const ClaudeCliUnauthenticated();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClaudeCliUnauthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ClaudeCliFailure.unauthenticated()';
}


}




/// @nodoc


class ClaudeCliCrashed implements ClaudeCliFailure {
  const ClaudeCliCrashed({required this.exitCode, required this.stderr});
  

 final  int exitCode;
 final  String stderr;

/// Create a copy of ClaudeCliFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClaudeCliCrashedCopyWith<ClaudeCliCrashed> get copyWith => _$ClaudeCliCrashedCopyWithImpl<ClaudeCliCrashed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClaudeCliCrashed&&(identical(other.exitCode, exitCode) || other.exitCode == exitCode)&&(identical(other.stderr, stderr) || other.stderr == stderr));
}


@override
int get hashCode => Object.hash(runtimeType,exitCode,stderr);

@override
String toString() {
  return 'ClaudeCliFailure.crashed(exitCode: $exitCode, stderr: $stderr)';
}


}

/// @nodoc
abstract mixin class $ClaudeCliCrashedCopyWith<$Res> implements $ClaudeCliFailureCopyWith<$Res> {
  factory $ClaudeCliCrashedCopyWith(ClaudeCliCrashed value, $Res Function(ClaudeCliCrashed) _then) = _$ClaudeCliCrashedCopyWithImpl;
@useResult
$Res call({
 int exitCode, String stderr
});




}
/// @nodoc
class _$ClaudeCliCrashedCopyWithImpl<$Res>
    implements $ClaudeCliCrashedCopyWith<$Res> {
  _$ClaudeCliCrashedCopyWithImpl(this._self, this._then);

  final ClaudeCliCrashed _self;
  final $Res Function(ClaudeCliCrashed) _then;

/// Create a copy of ClaudeCliFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? exitCode = null,Object? stderr = null,}) {
  return _then(ClaudeCliCrashed(
exitCode: null == exitCode ? _self.exitCode : exitCode // ignore: cast_nullable_to_non_nullable
as int,stderr: null == stderr ? _self.stderr : stderr // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ClaudeCliTimedOut implements ClaudeCliFailure {
  const ClaudeCliTimedOut();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClaudeCliTimedOut);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ClaudeCliFailure.timedOut()';
}


}




/// @nodoc


class ClaudeCliStreamParseFailed implements ClaudeCliFailure {
  const ClaudeCliStreamParseFailed({required this.line, required this.error});
  

 final  String line;
 final  Object error;

/// Create a copy of ClaudeCliFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClaudeCliStreamParseFailedCopyWith<ClaudeCliStreamParseFailed> get copyWith => _$ClaudeCliStreamParseFailedCopyWithImpl<ClaudeCliStreamParseFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClaudeCliStreamParseFailed&&(identical(other.line, line) || other.line == line)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,line,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ClaudeCliFailure.streamParseFailed(line: $line, error: $error)';
}


}

/// @nodoc
abstract mixin class $ClaudeCliStreamParseFailedCopyWith<$Res> implements $ClaudeCliFailureCopyWith<$Res> {
  factory $ClaudeCliStreamParseFailedCopyWith(ClaudeCliStreamParseFailed value, $Res Function(ClaudeCliStreamParseFailed) _then) = _$ClaudeCliStreamParseFailedCopyWithImpl;
@useResult
$Res call({
 String line, Object error
});




}
/// @nodoc
class _$ClaudeCliStreamParseFailedCopyWithImpl<$Res>
    implements $ClaudeCliStreamParseFailedCopyWith<$Res> {
  _$ClaudeCliStreamParseFailedCopyWithImpl(this._self, this._then);

  final ClaudeCliStreamParseFailed _self;
  final $Res Function(ClaudeCliStreamParseFailed) _then;

/// Create a copy of ClaudeCliFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? line = null,Object? error = null,}) {
  return _then(ClaudeCliStreamParseFailed(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error ,
  ));
}


}

/// @nodoc


class ClaudeCliCancelled implements ClaudeCliFailure {
  const ClaudeCliCancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClaudeCliCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ClaudeCliFailure.cancelled()';
}


}




/// @nodoc


class ClaudeCliUnknown implements ClaudeCliFailure {
  const ClaudeCliUnknown(this.error);
  

 final  Object error;

/// Create a copy of ClaudeCliFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClaudeCliUnknownCopyWith<ClaudeCliUnknown> get copyWith => _$ClaudeCliUnknownCopyWithImpl<ClaudeCliUnknown>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClaudeCliUnknown&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ClaudeCliFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $ClaudeCliUnknownCopyWith<$Res> implements $ClaudeCliFailureCopyWith<$Res> {
  factory $ClaudeCliUnknownCopyWith(ClaudeCliUnknown value, $Res Function(ClaudeCliUnknown) _then) = _$ClaudeCliUnknownCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$ClaudeCliUnknownCopyWithImpl<$Res>
    implements $ClaudeCliUnknownCopyWith<$Res> {
  _$ClaudeCliUnknownCopyWithImpl(this._self, this._then);

  final ClaudeCliUnknown _self;
  final $Res Function(ClaudeCliUnknown) _then;

/// Create a copy of ClaudeCliFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(ClaudeCliUnknown(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
