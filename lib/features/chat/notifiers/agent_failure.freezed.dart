// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AgentFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AgentFailure()';
}


}

/// @nodoc
class $AgentFailureCopyWith<$Res>  {
$AgentFailureCopyWith(AgentFailure _, $Res Function(AgentFailure) __);
}


/// Adds pattern-matching-related methods to [AgentFailure].
extension AgentFailurePatterns on AgentFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AgentIterationCapReached value)?  iterationCapReached,TResult Function( AgentProviderDoesNotSupportTools value)?  providerDoesNotSupportTools,TResult Function( AgentStreamAbortedUnexpectedly value)?  streamAbortedUnexpectedly,TResult Function( AgentToolDispatchFailed value)?  toolDispatchFailed,TResult Function( AgentNetworkExhausted value)?  networkExhausted,TResult Function( AgentUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AgentIterationCapReached() when iterationCapReached != null:
return iterationCapReached(_that);case AgentProviderDoesNotSupportTools() when providerDoesNotSupportTools != null:
return providerDoesNotSupportTools(_that);case AgentStreamAbortedUnexpectedly() when streamAbortedUnexpectedly != null:
return streamAbortedUnexpectedly(_that);case AgentToolDispatchFailed() when toolDispatchFailed != null:
return toolDispatchFailed(_that);case AgentNetworkExhausted() when networkExhausted != null:
return networkExhausted(_that);case AgentUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AgentIterationCapReached value)  iterationCapReached,required TResult Function( AgentProviderDoesNotSupportTools value)  providerDoesNotSupportTools,required TResult Function( AgentStreamAbortedUnexpectedly value)  streamAbortedUnexpectedly,required TResult Function( AgentToolDispatchFailed value)  toolDispatchFailed,required TResult Function( AgentNetworkExhausted value)  networkExhausted,required TResult Function( AgentUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case AgentIterationCapReached():
return iterationCapReached(_that);case AgentProviderDoesNotSupportTools():
return providerDoesNotSupportTools(_that);case AgentStreamAbortedUnexpectedly():
return streamAbortedUnexpectedly(_that);case AgentToolDispatchFailed():
return toolDispatchFailed(_that);case AgentNetworkExhausted():
return networkExhausted(_that);case AgentUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AgentIterationCapReached value)?  iterationCapReached,TResult? Function( AgentProviderDoesNotSupportTools value)?  providerDoesNotSupportTools,TResult? Function( AgentStreamAbortedUnexpectedly value)?  streamAbortedUnexpectedly,TResult? Function( AgentToolDispatchFailed value)?  toolDispatchFailed,TResult? Function( AgentNetworkExhausted value)?  networkExhausted,TResult? Function( AgentUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case AgentIterationCapReached() when iterationCapReached != null:
return iterationCapReached(_that);case AgentProviderDoesNotSupportTools() when providerDoesNotSupportTools != null:
return providerDoesNotSupportTools(_that);case AgentStreamAbortedUnexpectedly() when streamAbortedUnexpectedly != null:
return streamAbortedUnexpectedly(_that);case AgentToolDispatchFailed() when toolDispatchFailed != null:
return toolDispatchFailed(_that);case AgentNetworkExhausted() when networkExhausted != null:
return networkExhausted(_that);case AgentUnknownError() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  iterationCapReached,TResult Function()?  providerDoesNotSupportTools,TResult Function( String reason)?  streamAbortedUnexpectedly,TResult Function( String toolName,  String message)?  toolDispatchFailed,TResult Function( int attempts)?  networkExhausted,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AgentIterationCapReached() when iterationCapReached != null:
return iterationCapReached();case AgentProviderDoesNotSupportTools() when providerDoesNotSupportTools != null:
return providerDoesNotSupportTools();case AgentStreamAbortedUnexpectedly() when streamAbortedUnexpectedly != null:
return streamAbortedUnexpectedly(_that.reason);case AgentToolDispatchFailed() when toolDispatchFailed != null:
return toolDispatchFailed(_that.toolName,_that.message);case AgentNetworkExhausted() when networkExhausted != null:
return networkExhausted(_that.attempts);case AgentUnknownError() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  iterationCapReached,required TResult Function()  providerDoesNotSupportTools,required TResult Function( String reason)  streamAbortedUnexpectedly,required TResult Function( String toolName,  String message)  toolDispatchFailed,required TResult Function( int attempts)  networkExhausted,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case AgentIterationCapReached():
return iterationCapReached();case AgentProviderDoesNotSupportTools():
return providerDoesNotSupportTools();case AgentStreamAbortedUnexpectedly():
return streamAbortedUnexpectedly(_that.reason);case AgentToolDispatchFailed():
return toolDispatchFailed(_that.toolName,_that.message);case AgentNetworkExhausted():
return networkExhausted(_that.attempts);case AgentUnknownError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  iterationCapReached,TResult? Function()?  providerDoesNotSupportTools,TResult? Function( String reason)?  streamAbortedUnexpectedly,TResult? Function( String toolName,  String message)?  toolDispatchFailed,TResult? Function( int attempts)?  networkExhausted,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case AgentIterationCapReached() when iterationCapReached != null:
return iterationCapReached();case AgentProviderDoesNotSupportTools() when providerDoesNotSupportTools != null:
return providerDoesNotSupportTools();case AgentStreamAbortedUnexpectedly() when streamAbortedUnexpectedly != null:
return streamAbortedUnexpectedly(_that.reason);case AgentToolDispatchFailed() when toolDispatchFailed != null:
return toolDispatchFailed(_that.toolName,_that.message);case AgentNetworkExhausted() when networkExhausted != null:
return networkExhausted(_that.attempts);case AgentUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class AgentIterationCapReached implements AgentFailure {
  const AgentIterationCapReached();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentIterationCapReached);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AgentFailure.iterationCapReached()';
}


}




/// @nodoc


class AgentProviderDoesNotSupportTools implements AgentFailure {
  const AgentProviderDoesNotSupportTools();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentProviderDoesNotSupportTools);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AgentFailure.providerDoesNotSupportTools()';
}


}




/// @nodoc


class AgentStreamAbortedUnexpectedly implements AgentFailure {
  const AgentStreamAbortedUnexpectedly(this.reason);
  

 final  String reason;

/// Create a copy of AgentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentStreamAbortedUnexpectedlyCopyWith<AgentStreamAbortedUnexpectedly> get copyWith => _$AgentStreamAbortedUnexpectedlyCopyWithImpl<AgentStreamAbortedUnexpectedly>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentStreamAbortedUnexpectedly&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'AgentFailure.streamAbortedUnexpectedly(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $AgentStreamAbortedUnexpectedlyCopyWith<$Res> implements $AgentFailureCopyWith<$Res> {
  factory $AgentStreamAbortedUnexpectedlyCopyWith(AgentStreamAbortedUnexpectedly value, $Res Function(AgentStreamAbortedUnexpectedly) _then) = _$AgentStreamAbortedUnexpectedlyCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$AgentStreamAbortedUnexpectedlyCopyWithImpl<$Res>
    implements $AgentStreamAbortedUnexpectedlyCopyWith<$Res> {
  _$AgentStreamAbortedUnexpectedlyCopyWithImpl(this._self, this._then);

  final AgentStreamAbortedUnexpectedly _self;
  final $Res Function(AgentStreamAbortedUnexpectedly) _then;

/// Create a copy of AgentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(AgentStreamAbortedUnexpectedly(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AgentToolDispatchFailed implements AgentFailure {
  const AgentToolDispatchFailed(this.toolName, this.message);
  

 final  String toolName;
 final  String message;

/// Create a copy of AgentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentToolDispatchFailedCopyWith<AgentToolDispatchFailed> get copyWith => _$AgentToolDispatchFailedCopyWithImpl<AgentToolDispatchFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentToolDispatchFailed&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,toolName,message);

@override
String toString() {
  return 'AgentFailure.toolDispatchFailed(toolName: $toolName, message: $message)';
}


}

/// @nodoc
abstract mixin class $AgentToolDispatchFailedCopyWith<$Res> implements $AgentFailureCopyWith<$Res> {
  factory $AgentToolDispatchFailedCopyWith(AgentToolDispatchFailed value, $Res Function(AgentToolDispatchFailed) _then) = _$AgentToolDispatchFailedCopyWithImpl;
@useResult
$Res call({
 String toolName, String message
});




}
/// @nodoc
class _$AgentToolDispatchFailedCopyWithImpl<$Res>
    implements $AgentToolDispatchFailedCopyWith<$Res> {
  _$AgentToolDispatchFailedCopyWithImpl(this._self, this._then);

  final AgentToolDispatchFailed _self;
  final $Res Function(AgentToolDispatchFailed) _then;

/// Create a copy of AgentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? toolName = null,Object? message = null,}) {
  return _then(AgentToolDispatchFailed(
null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AgentNetworkExhausted implements AgentFailure {
  const AgentNetworkExhausted(this.attempts);
  

 final  int attempts;

/// Create a copy of AgentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentNetworkExhaustedCopyWith<AgentNetworkExhausted> get copyWith => _$AgentNetworkExhaustedCopyWithImpl<AgentNetworkExhausted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentNetworkExhausted&&(identical(other.attempts, attempts) || other.attempts == attempts));
}


@override
int get hashCode => Object.hash(runtimeType,attempts);

@override
String toString() {
  return 'AgentFailure.networkExhausted(attempts: $attempts)';
}


}

/// @nodoc
abstract mixin class $AgentNetworkExhaustedCopyWith<$Res> implements $AgentFailureCopyWith<$Res> {
  factory $AgentNetworkExhaustedCopyWith(AgentNetworkExhausted value, $Res Function(AgentNetworkExhausted) _then) = _$AgentNetworkExhaustedCopyWithImpl;
@useResult
$Res call({
 int attempts
});




}
/// @nodoc
class _$AgentNetworkExhaustedCopyWithImpl<$Res>
    implements $AgentNetworkExhaustedCopyWith<$Res> {
  _$AgentNetworkExhaustedCopyWithImpl(this._self, this._then);

  final AgentNetworkExhausted _self;
  final $Res Function(AgentNetworkExhausted) _then;

/// Create a copy of AgentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? attempts = null,}) {
  return _then(AgentNetworkExhausted(
null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class AgentUnknownError implements AgentFailure {
  const AgentUnknownError(this.error);
  

 final  Object error;

/// Create a copy of AgentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentUnknownErrorCopyWith<AgentUnknownError> get copyWith => _$AgentUnknownErrorCopyWithImpl<AgentUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'AgentFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $AgentUnknownErrorCopyWith<$Res> implements $AgentFailureCopyWith<$Res> {
  factory $AgentUnknownErrorCopyWith(AgentUnknownError value, $Res Function(AgentUnknownError) _then) = _$AgentUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$AgentUnknownErrorCopyWithImpl<$Res>
    implements $AgentUnknownErrorCopyWith<$Res> {
  _$AgentUnknownErrorCopyWithImpl(this._self, this._then);

  final AgentUnknownError _self;
  final $Res Function(AgentUnknownError) _then;

/// Create a copy of AgentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(AgentUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
