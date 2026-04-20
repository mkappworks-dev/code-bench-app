// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'available_models_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AvailableModelsFailure {

 Object get error;
/// Create a copy of AvailableModelsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailableModelsFailureCopyWith<AvailableModelsFailure> get copyWith => _$AvailableModelsFailureCopyWithImpl<AvailableModelsFailure>(this as AvailableModelsFailure, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailableModelsFailure&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'AvailableModelsFailure(error: $error)';
}


}

/// @nodoc
abstract mixin class $AvailableModelsFailureCopyWith<$Res>  {
  factory $AvailableModelsFailureCopyWith(AvailableModelsFailure value, $Res Function(AvailableModelsFailure) _then) = _$AvailableModelsFailureCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$AvailableModelsFailureCopyWithImpl<$Res>
    implements $AvailableModelsFailureCopyWith<$Res> {
  _$AvailableModelsFailureCopyWithImpl(this._self, this._then);

  final AvailableModelsFailure _self;
  final $Res Function(AvailableModelsFailure) _then;

/// Create a copy of AvailableModelsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? error = null,}) {
  return _then(_self.copyWith(
error: null == error ? _self.error : error ,
  ));
}

}


/// Adds pattern-matching-related methods to [AvailableModelsFailure].
extension AvailableModelsFailurePatterns on AvailableModelsFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AvailableModelsStorageError value)?  storageError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AvailableModelsStorageError() when storageError != null:
return storageError(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AvailableModelsStorageError value)  storageError,}){
final _that = this;
switch (_that) {
case AvailableModelsStorageError():
return storageError(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AvailableModelsStorageError value)?  storageError,}){
final _that = this;
switch (_that) {
case AvailableModelsStorageError() when storageError != null:
return storageError(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Object error)?  storageError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AvailableModelsStorageError() when storageError != null:
return storageError(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Object error)  storageError,}) {final _that = this;
switch (_that) {
case AvailableModelsStorageError():
return storageError(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Object error)?  storageError,}) {final _that = this;
switch (_that) {
case AvailableModelsStorageError() when storageError != null:
return storageError(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class AvailableModelsStorageError implements AvailableModelsFailure {
  const AvailableModelsStorageError(this.error);
  

@override final  Object error;

/// Create a copy of AvailableModelsFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailableModelsStorageErrorCopyWith<AvailableModelsStorageError> get copyWith => _$AvailableModelsStorageErrorCopyWithImpl<AvailableModelsStorageError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailableModelsStorageError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'AvailableModelsFailure.storageError(error: $error)';
}


}

/// @nodoc
abstract mixin class $AvailableModelsStorageErrorCopyWith<$Res> implements $AvailableModelsFailureCopyWith<$Res> {
  factory $AvailableModelsStorageErrorCopyWith(AvailableModelsStorageError value, $Res Function(AvailableModelsStorageError) _then) = _$AvailableModelsStorageErrorCopyWithImpl;
@override @useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$AvailableModelsStorageErrorCopyWithImpl<$Res>
    implements $AvailableModelsStorageErrorCopyWith<$Res> {
  _$AvailableModelsStorageErrorCopyWithImpl(this._self, this._then);

  final AvailableModelsStorageError _self;
  final $Res Function(AvailableModelsStorageError) _then;

/// Create a copy of AvailableModelsFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(AvailableModelsStorageError(
null == error ? _self.error : error ,
  ));
}


}

/// @nodoc
mixin _$ModelProviderFailure {

 AIProvider get provider;
/// Create a copy of ModelProviderFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelProviderFailureCopyWith<ModelProviderFailure> get copyWith => _$ModelProviderFailureCopyWithImpl<ModelProviderFailure>(this as ModelProviderFailure, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelProviderFailure&&(identical(other.provider, provider) || other.provider == provider));
}


@override
int get hashCode => Object.hash(runtimeType,provider);

@override
String toString() {
  return 'ModelProviderFailure(provider: $provider)';
}


}

/// @nodoc
abstract mixin class $ModelProviderFailureCopyWith<$Res>  {
  factory $ModelProviderFailureCopyWith(ModelProviderFailure value, $Res Function(ModelProviderFailure) _then) = _$ModelProviderFailureCopyWithImpl;
@useResult
$Res call({
 AIProvider provider
});




}
/// @nodoc
class _$ModelProviderFailureCopyWithImpl<$Res>
    implements $ModelProviderFailureCopyWith<$Res> {
  _$ModelProviderFailureCopyWithImpl(this._self, this._then);

  final ModelProviderFailure _self;
  final $Res Function(ModelProviderFailure) _then;

/// Create a copy of ModelProviderFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AIProvider,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelProviderFailure].
extension ModelProviderFailurePatterns on ModelProviderFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ModelProviderUnreachable value)?  unreachable,TResult Function( ModelProviderAuth value)?  auth,TResult Function( ModelProviderMalformedResponse value)?  malformedResponse,TResult Function( ModelProviderUnknown value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ModelProviderUnreachable() when unreachable != null:
return unreachable(_that);case ModelProviderAuth() when auth != null:
return auth(_that);case ModelProviderMalformedResponse() when malformedResponse != null:
return malformedResponse(_that);case ModelProviderUnknown() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ModelProviderUnreachable value)  unreachable,required TResult Function( ModelProviderAuth value)  auth,required TResult Function( ModelProviderMalformedResponse value)  malformedResponse,required TResult Function( ModelProviderUnknown value)  unknown,}){
final _that = this;
switch (_that) {
case ModelProviderUnreachable():
return unreachable(_that);case ModelProviderAuth():
return auth(_that);case ModelProviderMalformedResponse():
return malformedResponse(_that);case ModelProviderUnknown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ModelProviderUnreachable value)?  unreachable,TResult? Function( ModelProviderAuth value)?  auth,TResult? Function( ModelProviderMalformedResponse value)?  malformedResponse,TResult? Function( ModelProviderUnknown value)?  unknown,}){
final _that = this;
switch (_that) {
case ModelProviderUnreachable() when unreachable != null:
return unreachable(_that);case ModelProviderAuth() when auth != null:
return auth(_that);case ModelProviderMalformedResponse() when malformedResponse != null:
return malformedResponse(_that);case ModelProviderUnknown() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( AIProvider provider)?  unreachable,TResult Function( AIProvider provider)?  auth,TResult Function( AIProvider provider,  String detail)?  malformedResponse,TResult Function( AIProvider provider,  Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ModelProviderUnreachable() when unreachable != null:
return unreachable(_that.provider);case ModelProviderAuth() when auth != null:
return auth(_that.provider);case ModelProviderMalformedResponse() when malformedResponse != null:
return malformedResponse(_that.provider,_that.detail);case ModelProviderUnknown() when unknown != null:
return unknown(_that.provider,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( AIProvider provider)  unreachable,required TResult Function( AIProvider provider)  auth,required TResult Function( AIProvider provider,  String detail)  malformedResponse,required TResult Function( AIProvider provider,  Object error)  unknown,}) {final _that = this;
switch (_that) {
case ModelProviderUnreachable():
return unreachable(_that.provider);case ModelProviderAuth():
return auth(_that.provider);case ModelProviderMalformedResponse():
return malformedResponse(_that.provider,_that.detail);case ModelProviderUnknown():
return unknown(_that.provider,_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( AIProvider provider)?  unreachable,TResult? Function( AIProvider provider)?  auth,TResult? Function( AIProvider provider,  String detail)?  malformedResponse,TResult? Function( AIProvider provider,  Object error)?  unknown,}) {final _that = this;
switch (_that) {
case ModelProviderUnreachable() when unreachable != null:
return unreachable(_that.provider);case ModelProviderAuth() when auth != null:
return auth(_that.provider);case ModelProviderMalformedResponse() when malformedResponse != null:
return malformedResponse(_that.provider,_that.detail);case ModelProviderUnknown() when unknown != null:
return unknown(_that.provider,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class ModelProviderUnreachable implements ModelProviderFailure {
  const ModelProviderUnreachable(this.provider);
  

@override final  AIProvider provider;

/// Create a copy of ModelProviderFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelProviderUnreachableCopyWith<ModelProviderUnreachable> get copyWith => _$ModelProviderUnreachableCopyWithImpl<ModelProviderUnreachable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelProviderUnreachable&&(identical(other.provider, provider) || other.provider == provider));
}


@override
int get hashCode => Object.hash(runtimeType,provider);

@override
String toString() {
  return 'ModelProviderFailure.unreachable(provider: $provider)';
}


}

/// @nodoc
abstract mixin class $ModelProviderUnreachableCopyWith<$Res> implements $ModelProviderFailureCopyWith<$Res> {
  factory $ModelProviderUnreachableCopyWith(ModelProviderUnreachable value, $Res Function(ModelProviderUnreachable) _then) = _$ModelProviderUnreachableCopyWithImpl;
@override @useResult
$Res call({
 AIProvider provider
});




}
/// @nodoc
class _$ModelProviderUnreachableCopyWithImpl<$Res>
    implements $ModelProviderUnreachableCopyWith<$Res> {
  _$ModelProviderUnreachableCopyWithImpl(this._self, this._then);

  final ModelProviderUnreachable _self;
  final $Res Function(ModelProviderUnreachable) _then;

/// Create a copy of ModelProviderFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,}) {
  return _then(ModelProviderUnreachable(
null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AIProvider,
  ));
}


}

/// @nodoc


class ModelProviderAuth implements ModelProviderFailure {
  const ModelProviderAuth(this.provider);
  

@override final  AIProvider provider;

/// Create a copy of ModelProviderFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelProviderAuthCopyWith<ModelProviderAuth> get copyWith => _$ModelProviderAuthCopyWithImpl<ModelProviderAuth>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelProviderAuth&&(identical(other.provider, provider) || other.provider == provider));
}


@override
int get hashCode => Object.hash(runtimeType,provider);

@override
String toString() {
  return 'ModelProviderFailure.auth(provider: $provider)';
}


}

/// @nodoc
abstract mixin class $ModelProviderAuthCopyWith<$Res> implements $ModelProviderFailureCopyWith<$Res> {
  factory $ModelProviderAuthCopyWith(ModelProviderAuth value, $Res Function(ModelProviderAuth) _then) = _$ModelProviderAuthCopyWithImpl;
@override @useResult
$Res call({
 AIProvider provider
});




}
/// @nodoc
class _$ModelProviderAuthCopyWithImpl<$Res>
    implements $ModelProviderAuthCopyWith<$Res> {
  _$ModelProviderAuthCopyWithImpl(this._self, this._then);

  final ModelProviderAuth _self;
  final $Res Function(ModelProviderAuth) _then;

/// Create a copy of ModelProviderFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,}) {
  return _then(ModelProviderAuth(
null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AIProvider,
  ));
}


}

/// @nodoc


class ModelProviderMalformedResponse implements ModelProviderFailure {
  const ModelProviderMalformedResponse(this.provider, this.detail);
  

@override final  AIProvider provider;
 final  String detail;

/// Create a copy of ModelProviderFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelProviderMalformedResponseCopyWith<ModelProviderMalformedResponse> get copyWith => _$ModelProviderMalformedResponseCopyWithImpl<ModelProviderMalformedResponse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelProviderMalformedResponse&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,provider,detail);

@override
String toString() {
  return 'ModelProviderFailure.malformedResponse(provider: $provider, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $ModelProviderMalformedResponseCopyWith<$Res> implements $ModelProviderFailureCopyWith<$Res> {
  factory $ModelProviderMalformedResponseCopyWith(ModelProviderMalformedResponse value, $Res Function(ModelProviderMalformedResponse) _then) = _$ModelProviderMalformedResponseCopyWithImpl;
@override @useResult
$Res call({
 AIProvider provider, String detail
});




}
/// @nodoc
class _$ModelProviderMalformedResponseCopyWithImpl<$Res>
    implements $ModelProviderMalformedResponseCopyWith<$Res> {
  _$ModelProviderMalformedResponseCopyWithImpl(this._self, this._then);

  final ModelProviderMalformedResponse _self;
  final $Res Function(ModelProviderMalformedResponse) _then;

/// Create a copy of ModelProviderFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? detail = null,}) {
  return _then(ModelProviderMalformedResponse(
null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AIProvider,null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ModelProviderUnknown implements ModelProviderFailure {
  const ModelProviderUnknown(this.provider, this.error);
  

@override final  AIProvider provider;
 final  Object error;

/// Create a copy of ModelProviderFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelProviderUnknownCopyWith<ModelProviderUnknown> get copyWith => _$ModelProviderUnknownCopyWithImpl<ModelProviderUnknown>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelProviderUnknown&&(identical(other.provider, provider) || other.provider == provider)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,provider,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ModelProviderFailure.unknown(provider: $provider, error: $error)';
}


}

/// @nodoc
abstract mixin class $ModelProviderUnknownCopyWith<$Res> implements $ModelProviderFailureCopyWith<$Res> {
  factory $ModelProviderUnknownCopyWith(ModelProviderUnknown value, $Res Function(ModelProviderUnknown) _then) = _$ModelProviderUnknownCopyWithImpl;
@override @useResult
$Res call({
 AIProvider provider, Object error
});




}
/// @nodoc
class _$ModelProviderUnknownCopyWithImpl<$Res>
    implements $ModelProviderUnknownCopyWith<$Res> {
  _$ModelProviderUnknownCopyWithImpl(this._self, this._then);

  final ModelProviderUnknown _self;
  final $Res Function(ModelProviderUnknown) _then;

/// Create a copy of ModelProviderFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? error = null,}) {
  return _then(ModelProviderUnknown(
null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AIProvider,null == error ? _self.error : error ,
  ));
}


}

// dart format on
