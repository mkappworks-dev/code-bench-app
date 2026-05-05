// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_pr_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreatePrFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePrFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CreatePrFailure()';
}


}

/// @nodoc
class $CreatePrFailureCopyWith<$Res>  {
$CreatePrFailureCopyWith(CreatePrFailure _, $Res Function(CreatePrFailure) __);
}


/// Adds pattern-matching-related methods to [CreatePrFailure].
extension CreatePrFailurePatterns on CreatePrFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CreatePrNotAuthenticated value)?  notAuthenticated,TResult Function( CreatePrAppNotInstalled value)?  appNotInstalled,TResult Function( CreatePrNetwork value)?  network,TResult Function( CreatePrPermissionDenied value)?  permissionDenied,TResult Function( CreatePrUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CreatePrNotAuthenticated() when notAuthenticated != null:
return notAuthenticated(_that);case CreatePrAppNotInstalled() when appNotInstalled != null:
return appNotInstalled(_that);case CreatePrNetwork() when network != null:
return network(_that);case CreatePrPermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case CreatePrUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CreatePrNotAuthenticated value)  notAuthenticated,required TResult Function( CreatePrAppNotInstalled value)  appNotInstalled,required TResult Function( CreatePrNetwork value)  network,required TResult Function( CreatePrPermissionDenied value)  permissionDenied,required TResult Function( CreatePrUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case CreatePrNotAuthenticated():
return notAuthenticated(_that);case CreatePrAppNotInstalled():
return appNotInstalled(_that);case CreatePrNetwork():
return network(_that);case CreatePrPermissionDenied():
return permissionDenied(_that);case CreatePrUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CreatePrNotAuthenticated value)?  notAuthenticated,TResult? Function( CreatePrAppNotInstalled value)?  appNotInstalled,TResult? Function( CreatePrNetwork value)?  network,TResult? Function( CreatePrPermissionDenied value)?  permissionDenied,TResult? Function( CreatePrUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case CreatePrNotAuthenticated() when notAuthenticated != null:
return notAuthenticated(_that);case CreatePrAppNotInstalled() when appNotInstalled != null:
return appNotInstalled(_that);case CreatePrNetwork() when network != null:
return network(_that);case CreatePrPermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case CreatePrUnknownError() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  notAuthenticated,TResult Function()?  appNotInstalled,TResult Function( String message)?  network,TResult Function()?  permissionDenied,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CreatePrNotAuthenticated() when notAuthenticated != null:
return notAuthenticated();case CreatePrAppNotInstalled() when appNotInstalled != null:
return appNotInstalled();case CreatePrNetwork() when network != null:
return network(_that.message);case CreatePrPermissionDenied() when permissionDenied != null:
return permissionDenied();case CreatePrUnknownError() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  notAuthenticated,required TResult Function()  appNotInstalled,required TResult Function( String message)  network,required TResult Function()  permissionDenied,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case CreatePrNotAuthenticated():
return notAuthenticated();case CreatePrAppNotInstalled():
return appNotInstalled();case CreatePrNetwork():
return network(_that.message);case CreatePrPermissionDenied():
return permissionDenied();case CreatePrUnknownError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  notAuthenticated,TResult? Function()?  appNotInstalled,TResult? Function( String message)?  network,TResult? Function()?  permissionDenied,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case CreatePrNotAuthenticated() when notAuthenticated != null:
return notAuthenticated();case CreatePrAppNotInstalled() when appNotInstalled != null:
return appNotInstalled();case CreatePrNetwork() when network != null:
return network(_that.message);case CreatePrPermissionDenied() when permissionDenied != null:
return permissionDenied();case CreatePrUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class CreatePrNotAuthenticated implements CreatePrFailure {
  const CreatePrNotAuthenticated();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePrNotAuthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CreatePrFailure.notAuthenticated()';
}


}




/// @nodoc


class CreatePrAppNotInstalled implements CreatePrFailure {
  const CreatePrAppNotInstalled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePrAppNotInstalled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CreatePrFailure.appNotInstalled()';
}


}




/// @nodoc


class CreatePrNetwork implements CreatePrFailure {
  const CreatePrNetwork(this.message);
  

 final  String message;

/// Create a copy of CreatePrFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatePrNetworkCopyWith<CreatePrNetwork> get copyWith => _$CreatePrNetworkCopyWithImpl<CreatePrNetwork>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePrNetwork&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'CreatePrFailure.network(message: $message)';
}


}

/// @nodoc
abstract mixin class $CreatePrNetworkCopyWith<$Res> implements $CreatePrFailureCopyWith<$Res> {
  factory $CreatePrNetworkCopyWith(CreatePrNetwork value, $Res Function(CreatePrNetwork) _then) = _$CreatePrNetworkCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$CreatePrNetworkCopyWithImpl<$Res>
    implements $CreatePrNetworkCopyWith<$Res> {
  _$CreatePrNetworkCopyWithImpl(this._self, this._then);

  final CreatePrNetwork _self;
  final $Res Function(CreatePrNetwork) _then;

/// Create a copy of CreatePrFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(CreatePrNetwork(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CreatePrPermissionDenied implements CreatePrFailure {
  const CreatePrPermissionDenied();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePrPermissionDenied);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CreatePrFailure.permissionDenied()';
}


}




/// @nodoc


class CreatePrUnknownError implements CreatePrFailure {
  const CreatePrUnknownError(this.error);
  

 final  Object error;

/// Create a copy of CreatePrFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatePrUnknownErrorCopyWith<CreatePrUnknownError> get copyWith => _$CreatePrUnknownErrorCopyWithImpl<CreatePrUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePrUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'CreatePrFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $CreatePrUnknownErrorCopyWith<$Res> implements $CreatePrFailureCopyWith<$Res> {
  factory $CreatePrUnknownErrorCopyWith(CreatePrUnknownError value, $Res Function(CreatePrUnknownError) _then) = _$CreatePrUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$CreatePrUnknownErrorCopyWithImpl<$Res>
    implements $CreatePrUnknownErrorCopyWith<$Res> {
  _$CreatePrUnknownErrorCopyWithImpl(this._self, this._then);

  final CreatePrUnknownError _self;
  final $Res Function(CreatePrUnknownError) _then;

/// Create a copy of CreatePrFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(CreatePrUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
