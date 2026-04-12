// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_actions_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsActionsFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsActionsFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsActionsFailure()';
}


}

/// @nodoc
class $SettingsActionsFailureCopyWith<$Res>  {
$SettingsActionsFailureCopyWith(SettingsActionsFailure _, $Res Function(SettingsActionsFailure) __);
}


/// Adds pattern-matching-related methods to [SettingsActionsFailure].
extension SettingsActionsFailurePatterns on SettingsActionsFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SettingsStorageFailed value)?  storageFailed,TResult Function( SettingsUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SettingsStorageFailed() when storageFailed != null:
return storageFailed(_that);case SettingsUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SettingsStorageFailed value)  storageFailed,required TResult Function( SettingsUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case SettingsStorageFailed():
return storageFailed(_that);case SettingsUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SettingsStorageFailed value)?  storageFailed,TResult? Function( SettingsUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case SettingsStorageFailed() when storageFailed != null:
return storageFailed(_that);case SettingsUnknownError() when unknown != null:
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
case SettingsStorageFailed() when storageFailed != null:
return storageFailed(_that.providerName);case SettingsUnknownError() when unknown != null:
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
case SettingsStorageFailed():
return storageFailed(_that.providerName);case SettingsUnknownError():
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
case SettingsStorageFailed() when storageFailed != null:
return storageFailed(_that.providerName);case SettingsUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class SettingsStorageFailed implements SettingsActionsFailure {
  const SettingsStorageFailed(this.providerName);
  

 final  String providerName;

/// Create a copy of SettingsActionsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsStorageFailedCopyWith<SettingsStorageFailed> get copyWith => _$SettingsStorageFailedCopyWithImpl<SettingsStorageFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsStorageFailed&&(identical(other.providerName, providerName) || other.providerName == providerName));
}


@override
int get hashCode => Object.hash(runtimeType,providerName);

@override
String toString() {
  return 'SettingsActionsFailure.storageFailed(providerName: $providerName)';
}


}

/// @nodoc
abstract mixin class $SettingsStorageFailedCopyWith<$Res> implements $SettingsActionsFailureCopyWith<$Res> {
  factory $SettingsStorageFailedCopyWith(SettingsStorageFailed value, $Res Function(SettingsStorageFailed) _then) = _$SettingsStorageFailedCopyWithImpl;
@useResult
$Res call({
 String providerName
});




}
/// @nodoc
class _$SettingsStorageFailedCopyWithImpl<$Res>
    implements $SettingsStorageFailedCopyWith<$Res> {
  _$SettingsStorageFailedCopyWithImpl(this._self, this._then);

  final SettingsStorageFailed _self;
  final $Res Function(SettingsStorageFailed) _then;

/// Create a copy of SettingsActionsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? providerName = null,}) {
  return _then(SettingsStorageFailed(
null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SettingsUnknownError implements SettingsActionsFailure {
  const SettingsUnknownError(this.error);
  

 final  Object error;

/// Create a copy of SettingsActionsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsUnknownErrorCopyWith<SettingsUnknownError> get copyWith => _$SettingsUnknownErrorCopyWithImpl<SettingsUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'SettingsActionsFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $SettingsUnknownErrorCopyWith<$Res> implements $SettingsActionsFailureCopyWith<$Res> {
  factory $SettingsUnknownErrorCopyWith(SettingsUnknownError value, $Res Function(SettingsUnknownError) _then) = _$SettingsUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$SettingsUnknownErrorCopyWithImpl<$Res>
    implements $SettingsUnknownErrorCopyWith<$Res> {
  _$SettingsUnknownErrorCopyWithImpl(this._self, this._then);

  final SettingsUnknownError _self;
  final $Res Function(SettingsUnknownError) _then;

/// Create a copy of SettingsActionsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(SettingsUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
