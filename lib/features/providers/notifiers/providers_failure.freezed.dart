// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'providers_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProvidersFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProvidersFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProvidersFailure()';
}


}

/// @nodoc
class $ProvidersFailureCopyWith<$Res>  {
$ProvidersFailureCopyWith(ProvidersFailure _, $Res Function(ProvidersFailure) __);
}


/// Adds pattern-matching-related methods to [ProvidersFailure].
extension ProvidersFailurePatterns on ProvidersFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProvidersStorageFailed value)?  storageFailed,TResult Function( ProvidersUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProvidersStorageFailed() when storageFailed != null:
return storageFailed(_that);case ProvidersUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProvidersStorageFailed value)  storageFailed,required TResult Function( ProvidersUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case ProvidersStorageFailed():
return storageFailed(_that);case ProvidersUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProvidersStorageFailed value)?  storageFailed,TResult? Function( ProvidersUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case ProvidersStorageFailed() when storageFailed != null:
return storageFailed(_that);case ProvidersUnknownError() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String providerName)?  storageFailed,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProvidersStorageFailed() when storageFailed != null:
return storageFailed(_that.providerName);case ProvidersUnknownError() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String providerName)  storageFailed,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case ProvidersStorageFailed():
return storageFailed(_that.providerName);case ProvidersUnknownError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String providerName)?  storageFailed,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case ProvidersStorageFailed() when storageFailed != null:
return storageFailed(_that.providerName);case ProvidersUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class ProvidersStorageFailed implements ProvidersFailure {
  const ProvidersStorageFailed(this.providerName);
  

 final  String providerName;

/// Create a copy of ProvidersFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProvidersStorageFailedCopyWith<ProvidersStorageFailed> get copyWith => _$ProvidersStorageFailedCopyWithImpl<ProvidersStorageFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProvidersStorageFailed&&(identical(other.providerName, providerName) || other.providerName == providerName));
}


@override
int get hashCode => Object.hash(runtimeType,providerName);

@override
String toString() {
  return 'ProvidersFailure.storageFailed(providerName: $providerName)';
}


}

/// @nodoc
abstract mixin class $ProvidersStorageFailedCopyWith<$Res> implements $ProvidersFailureCopyWith<$Res> {
  factory $ProvidersStorageFailedCopyWith(ProvidersStorageFailed value, $Res Function(ProvidersStorageFailed) _then) = _$ProvidersStorageFailedCopyWithImpl;
@useResult
$Res call({
 String providerName
});




}
/// @nodoc
class _$ProvidersStorageFailedCopyWithImpl<$Res>
    implements $ProvidersStorageFailedCopyWith<$Res> {
  _$ProvidersStorageFailedCopyWithImpl(this._self, this._then);

  final ProvidersStorageFailed _self;
  final $Res Function(ProvidersStorageFailed) _then;

/// Create a copy of ProvidersFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? providerName = null,}) {
  return _then(ProvidersStorageFailed(
null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProvidersUnknownError implements ProvidersFailure {
  const ProvidersUnknownError(this.error);
  

 final  Object error;

/// Create a copy of ProvidersFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProvidersUnknownErrorCopyWith<ProvidersUnknownError> get copyWith => _$ProvidersUnknownErrorCopyWithImpl<ProvidersUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProvidersUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ProvidersFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $ProvidersUnknownErrorCopyWith<$Res> implements $ProvidersFailureCopyWith<$Res> {
  factory $ProvidersUnknownErrorCopyWith(ProvidersUnknownError value, $Res Function(ProvidersUnknownError) _then) = _$ProvidersUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$ProvidersUnknownErrorCopyWithImpl<$Res>
    implements $ProvidersUnknownErrorCopyWith<$Res> {
  _$ProvidersUnknownErrorCopyWithImpl(this._self, this._then);

  final ProvidersUnknownError _self;
  final $Res Function(ProvidersUnknownError) _then;

/// Create a copy of ProvidersFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(ProvidersUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
