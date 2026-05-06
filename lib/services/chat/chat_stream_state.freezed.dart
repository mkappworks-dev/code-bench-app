// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_stream_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatStreamState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStreamState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatStreamState()';
}


}

/// @nodoc
class $ChatStreamStateCopyWith<$Res>  {
$ChatStreamStateCopyWith(ChatStreamState _, $Res Function(ChatStreamState) __);
}


/// Adds pattern-matching-related methods to [ChatStreamState].
extension ChatStreamStatePatterns on ChatStreamState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatStreamIdle value)?  idle,TResult Function( ChatStreamConnecting value)?  connecting,TResult Function( ChatStreamStreaming value)?  streaming,TResult Function( ChatStreamRetrying value)?  retrying,TResult Function( ChatStreamFailed value)?  failed,TResult Function( ChatStreamDone value)?  done,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatStreamIdle() when idle != null:
return idle(_that);case ChatStreamConnecting() when connecting != null:
return connecting(_that);case ChatStreamStreaming() when streaming != null:
return streaming(_that);case ChatStreamRetrying() when retrying != null:
return retrying(_that);case ChatStreamFailed() when failed != null:
return failed(_that);case ChatStreamDone() when done != null:
return done(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatStreamIdle value)  idle,required TResult Function( ChatStreamConnecting value)  connecting,required TResult Function( ChatStreamStreaming value)  streaming,required TResult Function( ChatStreamRetrying value)  retrying,required TResult Function( ChatStreamFailed value)  failed,required TResult Function( ChatStreamDone value)  done,}){
final _that = this;
switch (_that) {
case ChatStreamIdle():
return idle(_that);case ChatStreamConnecting():
return connecting(_that);case ChatStreamStreaming():
return streaming(_that);case ChatStreamRetrying():
return retrying(_that);case ChatStreamFailed():
return failed(_that);case ChatStreamDone():
return done(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatStreamIdle value)?  idle,TResult? Function( ChatStreamConnecting value)?  connecting,TResult? Function( ChatStreamStreaming value)?  streaming,TResult? Function( ChatStreamRetrying value)?  retrying,TResult? Function( ChatStreamFailed value)?  failed,TResult? Function( ChatStreamDone value)?  done,}){
final _that = this;
switch (_that) {
case ChatStreamIdle() when idle != null:
return idle(_that);case ChatStreamConnecting() when connecting != null:
return connecting(_that);case ChatStreamStreaming() when streaming != null:
return streaming(_that);case ChatStreamRetrying() when retrying != null:
return retrying(_that);case ChatStreamFailed() when failed != null:
return failed(_that);case ChatStreamDone() when done != null:
return done(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( int attempt)?  connecting,TResult Function()?  streaming,TResult Function( int attempt,  Duration nextDelay)?  retrying,TResult Function( AgentFailure failure)?  failed,TResult Function()?  done,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatStreamIdle() when idle != null:
return idle();case ChatStreamConnecting() when connecting != null:
return connecting(_that.attempt);case ChatStreamStreaming() when streaming != null:
return streaming();case ChatStreamRetrying() when retrying != null:
return retrying(_that.attempt,_that.nextDelay);case ChatStreamFailed() when failed != null:
return failed(_that.failure);case ChatStreamDone() when done != null:
return done();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( int attempt)  connecting,required TResult Function()  streaming,required TResult Function( int attempt,  Duration nextDelay)  retrying,required TResult Function( AgentFailure failure)  failed,required TResult Function()  done,}) {final _that = this;
switch (_that) {
case ChatStreamIdle():
return idle();case ChatStreamConnecting():
return connecting(_that.attempt);case ChatStreamStreaming():
return streaming();case ChatStreamRetrying():
return retrying(_that.attempt,_that.nextDelay);case ChatStreamFailed():
return failed(_that.failure);case ChatStreamDone():
return done();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( int attempt)?  connecting,TResult? Function()?  streaming,TResult? Function( int attempt,  Duration nextDelay)?  retrying,TResult? Function( AgentFailure failure)?  failed,TResult? Function()?  done,}) {final _that = this;
switch (_that) {
case ChatStreamIdle() when idle != null:
return idle();case ChatStreamConnecting() when connecting != null:
return connecting(_that.attempt);case ChatStreamStreaming() when streaming != null:
return streaming();case ChatStreamRetrying() when retrying != null:
return retrying(_that.attempt,_that.nextDelay);case ChatStreamFailed() when failed != null:
return failed(_that.failure);case ChatStreamDone() when done != null:
return done();case _:
  return null;

}
}

}

/// @nodoc


class ChatStreamIdle implements ChatStreamState {
  const ChatStreamIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStreamIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatStreamState.idle()';
}


}




/// @nodoc


class ChatStreamConnecting implements ChatStreamState {
  const ChatStreamConnecting({required this.attempt});
  

 final  int attempt;

/// Create a copy of ChatStreamState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStreamConnectingCopyWith<ChatStreamConnecting> get copyWith => _$ChatStreamConnectingCopyWithImpl<ChatStreamConnecting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStreamConnecting&&(identical(other.attempt, attempt) || other.attempt == attempt));
}


@override
int get hashCode => Object.hash(runtimeType,attempt);

@override
String toString() {
  return 'ChatStreamState.connecting(attempt: $attempt)';
}


}

/// @nodoc
abstract mixin class $ChatStreamConnectingCopyWith<$Res> implements $ChatStreamStateCopyWith<$Res> {
  factory $ChatStreamConnectingCopyWith(ChatStreamConnecting value, $Res Function(ChatStreamConnecting) _then) = _$ChatStreamConnectingCopyWithImpl;
@useResult
$Res call({
 int attempt
});




}
/// @nodoc
class _$ChatStreamConnectingCopyWithImpl<$Res>
    implements $ChatStreamConnectingCopyWith<$Res> {
  _$ChatStreamConnectingCopyWithImpl(this._self, this._then);

  final ChatStreamConnecting _self;
  final $Res Function(ChatStreamConnecting) _then;

/// Create a copy of ChatStreamState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? attempt = null,}) {
  return _then(ChatStreamConnecting(
attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ChatStreamStreaming implements ChatStreamState {
  const ChatStreamStreaming();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStreamStreaming);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatStreamState.streaming()';
}


}




/// @nodoc


class ChatStreamRetrying implements ChatStreamState {
  const ChatStreamRetrying({required this.attempt, required this.nextDelay});
  

 final  int attempt;
 final  Duration nextDelay;

/// Create a copy of ChatStreamState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStreamRetryingCopyWith<ChatStreamRetrying> get copyWith => _$ChatStreamRetryingCopyWithImpl<ChatStreamRetrying>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStreamRetrying&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.nextDelay, nextDelay) || other.nextDelay == nextDelay));
}


@override
int get hashCode => Object.hash(runtimeType,attempt,nextDelay);

@override
String toString() {
  return 'ChatStreamState.retrying(attempt: $attempt, nextDelay: $nextDelay)';
}


}

/// @nodoc
abstract mixin class $ChatStreamRetryingCopyWith<$Res> implements $ChatStreamStateCopyWith<$Res> {
  factory $ChatStreamRetryingCopyWith(ChatStreamRetrying value, $Res Function(ChatStreamRetrying) _then) = _$ChatStreamRetryingCopyWithImpl;
@useResult
$Res call({
 int attempt, Duration nextDelay
});




}
/// @nodoc
class _$ChatStreamRetryingCopyWithImpl<$Res>
    implements $ChatStreamRetryingCopyWith<$Res> {
  _$ChatStreamRetryingCopyWithImpl(this._self, this._then);

  final ChatStreamRetrying _self;
  final $Res Function(ChatStreamRetrying) _then;

/// Create a copy of ChatStreamState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? attempt = null,Object? nextDelay = null,}) {
  return _then(ChatStreamRetrying(
attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,nextDelay: null == nextDelay ? _self.nextDelay : nextDelay // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc


class ChatStreamFailed implements ChatStreamState {
  const ChatStreamFailed(this.failure);
  

 final  AgentFailure failure;

/// Create a copy of ChatStreamState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStreamFailedCopyWith<ChatStreamFailed> get copyWith => _$ChatStreamFailedCopyWithImpl<ChatStreamFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStreamFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ChatStreamState.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ChatStreamFailedCopyWith<$Res> implements $ChatStreamStateCopyWith<$Res> {
  factory $ChatStreamFailedCopyWith(ChatStreamFailed value, $Res Function(ChatStreamFailed) _then) = _$ChatStreamFailedCopyWithImpl;
@useResult
$Res call({
 AgentFailure failure
});


$AgentFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ChatStreamFailedCopyWithImpl<$Res>
    implements $ChatStreamFailedCopyWith<$Res> {
  _$ChatStreamFailedCopyWithImpl(this._self, this._then);

  final ChatStreamFailed _self;
  final $Res Function(ChatStreamFailed) _then;

/// Create a copy of ChatStreamState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ChatStreamFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AgentFailure,
  ));
}

/// Create a copy of ChatStreamState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgentFailureCopyWith<$Res> get failure {
  
  return $AgentFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class ChatStreamDone implements ChatStreamState {
  const ChatStreamDone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStreamDone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatStreamState.done()';
}


}




// dart format on
