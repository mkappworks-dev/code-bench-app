// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mcp_server_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$McpServerStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'McpServerStatus()';
}


}

/// @nodoc
class $McpServerStatusCopyWith<$Res>  {
$McpServerStatusCopyWith(McpServerStatus _, $Res Function(McpServerStatus) __);
}


/// Adds pattern-matching-related methods to [McpServerStatus].
extension McpServerStatusPatterns on McpServerStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( McpServerStopped value)?  stopped,TResult Function( McpServerStarting value)?  starting,TResult Function( McpServerRunning value)?  running,TResult Function( McpServerError value)?  error,TResult Function( McpServerPendingRemoval value)?  pendingRemoval,required TResult orElse(),}){
final _that = this;
switch (_that) {
case McpServerStopped() when stopped != null:
return stopped(_that);case McpServerStarting() when starting != null:
return starting(_that);case McpServerRunning() when running != null:
return running(_that);case McpServerError() when error != null:
return error(_that);case McpServerPendingRemoval() when pendingRemoval != null:
return pendingRemoval(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( McpServerStopped value)  stopped,required TResult Function( McpServerStarting value)  starting,required TResult Function( McpServerRunning value)  running,required TResult Function( McpServerError value)  error,required TResult Function( McpServerPendingRemoval value)  pendingRemoval,}){
final _that = this;
switch (_that) {
case McpServerStopped():
return stopped(_that);case McpServerStarting():
return starting(_that);case McpServerRunning():
return running(_that);case McpServerError():
return error(_that);case McpServerPendingRemoval():
return pendingRemoval(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( McpServerStopped value)?  stopped,TResult? Function( McpServerStarting value)?  starting,TResult? Function( McpServerRunning value)?  running,TResult? Function( McpServerError value)?  error,TResult? Function( McpServerPendingRemoval value)?  pendingRemoval,}){
final _that = this;
switch (_that) {
case McpServerStopped() when stopped != null:
return stopped(_that);case McpServerStarting() when starting != null:
return starting(_that);case McpServerRunning() when running != null:
return running(_that);case McpServerError() when error != null:
return error(_that);case McpServerPendingRemoval() when pendingRemoval != null:
return pendingRemoval(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  stopped,TResult Function()?  starting,TResult Function()?  running,TResult Function( String message)?  error,TResult Function()?  pendingRemoval,required TResult orElse(),}) {final _that = this;
switch (_that) {
case McpServerStopped() when stopped != null:
return stopped();case McpServerStarting() when starting != null:
return starting();case McpServerRunning() when running != null:
return running();case McpServerError() when error != null:
return error(_that.message);case McpServerPendingRemoval() when pendingRemoval != null:
return pendingRemoval();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  stopped,required TResult Function()  starting,required TResult Function()  running,required TResult Function( String message)  error,required TResult Function()  pendingRemoval,}) {final _that = this;
switch (_that) {
case McpServerStopped():
return stopped();case McpServerStarting():
return starting();case McpServerRunning():
return running();case McpServerError():
return error(_that.message);case McpServerPendingRemoval():
return pendingRemoval();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  stopped,TResult? Function()?  starting,TResult? Function()?  running,TResult? Function( String message)?  error,TResult? Function()?  pendingRemoval,}) {final _that = this;
switch (_that) {
case McpServerStopped() when stopped != null:
return stopped();case McpServerStarting() when starting != null:
return starting();case McpServerRunning() when running != null:
return running();case McpServerError() when error != null:
return error(_that.message);case McpServerPendingRemoval() when pendingRemoval != null:
return pendingRemoval();case _:
  return null;

}
}

}

/// @nodoc


class McpServerStopped implements McpServerStatus {
  const McpServerStopped();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerStopped);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'McpServerStatus.stopped()';
}


}




/// @nodoc


class McpServerStarting implements McpServerStatus {
  const McpServerStarting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerStarting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'McpServerStatus.starting()';
}


}




/// @nodoc


class McpServerRunning implements McpServerStatus {
  const McpServerRunning();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerRunning);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'McpServerStatus.running()';
}


}




/// @nodoc


class McpServerError implements McpServerStatus {
  const McpServerError(this.message);
  

 final  String message;

/// Create a copy of McpServerStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServerErrorCopyWith<McpServerError> get copyWith => _$McpServerErrorCopyWithImpl<McpServerError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'McpServerStatus.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $McpServerErrorCopyWith<$Res> implements $McpServerStatusCopyWith<$Res> {
  factory $McpServerErrorCopyWith(McpServerError value, $Res Function(McpServerError) _then) = _$McpServerErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$McpServerErrorCopyWithImpl<$Res>
    implements $McpServerErrorCopyWith<$Res> {
  _$McpServerErrorCopyWithImpl(this._self, this._then);

  final McpServerError _self;
  final $Res Function(McpServerError) _then;

/// Create a copy of McpServerStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(McpServerError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class McpServerPendingRemoval implements McpServerStatus {
  const McpServerPendingRemoval();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerPendingRemoval);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'McpServerStatus.pendingRemoval()';
}


}




// dart format on
