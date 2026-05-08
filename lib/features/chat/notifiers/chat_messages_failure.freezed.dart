// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_messages_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatMessagesFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessagesFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatMessagesFailure()';
}


}

/// @nodoc
class $ChatMessagesFailureCopyWith<$Res>  {
$ChatMessagesFailureCopyWith(ChatMessagesFailure _, $Res Function(ChatMessagesFailure) __);
}


/// Adds pattern-matching-related methods to [ChatMessagesFailure].
extension ChatMessagesFailurePatterns on ChatMessagesFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatMessagesDeleteFailed value)?  deleteFailed,TResult Function( ChatMessagesRetryFailed value)?  retryFailed,TResult Function( ChatMessagesLoadMoreFailed value)?  loadMoreFailed,TResult Function( ChatMessagesUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatMessagesDeleteFailed() when deleteFailed != null:
return deleteFailed(_that);case ChatMessagesRetryFailed() when retryFailed != null:
return retryFailed(_that);case ChatMessagesLoadMoreFailed() when loadMoreFailed != null:
return loadMoreFailed(_that);case ChatMessagesUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatMessagesDeleteFailed value)  deleteFailed,required TResult Function( ChatMessagesRetryFailed value)  retryFailed,required TResult Function( ChatMessagesLoadMoreFailed value)  loadMoreFailed,required TResult Function( ChatMessagesUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case ChatMessagesDeleteFailed():
return deleteFailed(_that);case ChatMessagesRetryFailed():
return retryFailed(_that);case ChatMessagesLoadMoreFailed():
return loadMoreFailed(_that);case ChatMessagesUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatMessagesDeleteFailed value)?  deleteFailed,TResult? Function( ChatMessagesRetryFailed value)?  retryFailed,TResult? Function( ChatMessagesLoadMoreFailed value)?  loadMoreFailed,TResult? Function( ChatMessagesUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case ChatMessagesDeleteFailed() when deleteFailed != null:
return deleteFailed(_that);case ChatMessagesRetryFailed() when retryFailed != null:
return retryFailed(_that);case ChatMessagesLoadMoreFailed() when loadMoreFailed != null:
return loadMoreFailed(_that);case ChatMessagesUnknownError() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  deleteFailed,TResult Function()?  retryFailed,TResult Function()?  loadMoreFailed,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatMessagesDeleteFailed() when deleteFailed != null:
return deleteFailed();case ChatMessagesRetryFailed() when retryFailed != null:
return retryFailed();case ChatMessagesLoadMoreFailed() when loadMoreFailed != null:
return loadMoreFailed();case ChatMessagesUnknownError() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  deleteFailed,required TResult Function()  retryFailed,required TResult Function()  loadMoreFailed,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case ChatMessagesDeleteFailed():
return deleteFailed();case ChatMessagesRetryFailed():
return retryFailed();case ChatMessagesLoadMoreFailed():
return loadMoreFailed();case ChatMessagesUnknownError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  deleteFailed,TResult? Function()?  retryFailed,TResult? Function()?  loadMoreFailed,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case ChatMessagesDeleteFailed() when deleteFailed != null:
return deleteFailed();case ChatMessagesRetryFailed() when retryFailed != null:
return retryFailed();case ChatMessagesLoadMoreFailed() when loadMoreFailed != null:
return loadMoreFailed();case ChatMessagesUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class ChatMessagesDeleteFailed implements ChatMessagesFailure {
  const ChatMessagesDeleteFailed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessagesDeleteFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatMessagesFailure.deleteFailed()';
}


}




/// @nodoc


class ChatMessagesRetryFailed implements ChatMessagesFailure {
  const ChatMessagesRetryFailed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessagesRetryFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatMessagesFailure.retryFailed()';
}


}




/// @nodoc


class ChatMessagesLoadMoreFailed implements ChatMessagesFailure {
  const ChatMessagesLoadMoreFailed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessagesLoadMoreFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatMessagesFailure.loadMoreFailed()';
}


}




/// @nodoc


class ChatMessagesUnknownError implements ChatMessagesFailure {
  const ChatMessagesUnknownError(this.error);
  

 final  Object error;

/// Create a copy of ChatMessagesFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessagesUnknownErrorCopyWith<ChatMessagesUnknownError> get copyWith => _$ChatMessagesUnknownErrorCopyWithImpl<ChatMessagesUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessagesUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ChatMessagesFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $ChatMessagesUnknownErrorCopyWith<$Res> implements $ChatMessagesFailureCopyWith<$Res> {
  factory $ChatMessagesUnknownErrorCopyWith(ChatMessagesUnknownError value, $Res Function(ChatMessagesUnknownError) _then) = _$ChatMessagesUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$ChatMessagesUnknownErrorCopyWithImpl<$Res>
    implements $ChatMessagesUnknownErrorCopyWith<$Res> {
  _$ChatMessagesUnknownErrorCopyWithImpl(this._self, this._then);

  final ChatMessagesUnknownError _self;
  final $Res Function(ChatMessagesUnknownError) _then;

/// Create a copy of ChatMessagesFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(ChatMessagesUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
