// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'provider_capabilities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProviderCapabilities {

 bool get supportsModelOverride; bool get supportsSystemPrompt; Set<ChatMode> get supportedModes; Set<ChatEffort> get supportedEfforts; Set<ChatPermission> get supportedPermissions;
/// Create a copy of ProviderCapabilities
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderCapabilitiesCopyWith<ProviderCapabilities> get copyWith => _$ProviderCapabilitiesCopyWithImpl<ProviderCapabilities>(this as ProviderCapabilities, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderCapabilities&&(identical(other.supportsModelOverride, supportsModelOverride) || other.supportsModelOverride == supportsModelOverride)&&(identical(other.supportsSystemPrompt, supportsSystemPrompt) || other.supportsSystemPrompt == supportsSystemPrompt)&&const DeepCollectionEquality().equals(other.supportedModes, supportedModes)&&const DeepCollectionEquality().equals(other.supportedEfforts, supportedEfforts)&&const DeepCollectionEquality().equals(other.supportedPermissions, supportedPermissions));
}


@override
int get hashCode => Object.hash(runtimeType,supportsModelOverride,supportsSystemPrompt,const DeepCollectionEquality().hash(supportedModes),const DeepCollectionEquality().hash(supportedEfforts),const DeepCollectionEquality().hash(supportedPermissions));

@override
String toString() {
  return 'ProviderCapabilities(supportsModelOverride: $supportsModelOverride, supportsSystemPrompt: $supportsSystemPrompt, supportedModes: $supportedModes, supportedEfforts: $supportedEfforts, supportedPermissions: $supportedPermissions)';
}


}

/// @nodoc
abstract mixin class $ProviderCapabilitiesCopyWith<$Res>  {
  factory $ProviderCapabilitiesCopyWith(ProviderCapabilities value, $Res Function(ProviderCapabilities) _then) = _$ProviderCapabilitiesCopyWithImpl;
@useResult
$Res call({
 bool supportsModelOverride, bool supportsSystemPrompt, Set<ChatMode> supportedModes, Set<ChatEffort> supportedEfforts, Set<ChatPermission> supportedPermissions
});




}
/// @nodoc
class _$ProviderCapabilitiesCopyWithImpl<$Res>
    implements $ProviderCapabilitiesCopyWith<$Res> {
  _$ProviderCapabilitiesCopyWithImpl(this._self, this._then);

  final ProviderCapabilities _self;
  final $Res Function(ProviderCapabilities) _then;

/// Create a copy of ProviderCapabilities
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? supportsModelOverride = null,Object? supportsSystemPrompt = null,Object? supportedModes = null,Object? supportedEfforts = null,Object? supportedPermissions = null,}) {
  return _then(_self.copyWith(
supportsModelOverride: null == supportsModelOverride ? _self.supportsModelOverride : supportsModelOverride // ignore: cast_nullable_to_non_nullable
as bool,supportsSystemPrompt: null == supportsSystemPrompt ? _self.supportsSystemPrompt : supportsSystemPrompt // ignore: cast_nullable_to_non_nullable
as bool,supportedModes: null == supportedModes ? _self.supportedModes : supportedModes // ignore: cast_nullable_to_non_nullable
as Set<ChatMode>,supportedEfforts: null == supportedEfforts ? _self.supportedEfforts : supportedEfforts // ignore: cast_nullable_to_non_nullable
as Set<ChatEffort>,supportedPermissions: null == supportedPermissions ? _self.supportedPermissions : supportedPermissions // ignore: cast_nullable_to_non_nullable
as Set<ChatPermission>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderCapabilities].
extension ProviderCapabilitiesPatterns on ProviderCapabilities {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderCapabilities value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderCapabilities() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderCapabilities value)  $default,){
final _that = this;
switch (_that) {
case _ProviderCapabilities():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderCapabilities value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderCapabilities() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool supportsModelOverride,  bool supportsSystemPrompt,  Set<ChatMode> supportedModes,  Set<ChatEffort> supportedEfforts,  Set<ChatPermission> supportedPermissions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderCapabilities() when $default != null:
return $default(_that.supportsModelOverride,_that.supportsSystemPrompt,_that.supportedModes,_that.supportedEfforts,_that.supportedPermissions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool supportsModelOverride,  bool supportsSystemPrompt,  Set<ChatMode> supportedModes,  Set<ChatEffort> supportedEfforts,  Set<ChatPermission> supportedPermissions)  $default,) {final _that = this;
switch (_that) {
case _ProviderCapabilities():
return $default(_that.supportsModelOverride,_that.supportsSystemPrompt,_that.supportedModes,_that.supportedEfforts,_that.supportedPermissions);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool supportsModelOverride,  bool supportsSystemPrompt,  Set<ChatMode> supportedModes,  Set<ChatEffort> supportedEfforts,  Set<ChatPermission> supportedPermissions)?  $default,) {final _that = this;
switch (_that) {
case _ProviderCapabilities() when $default != null:
return $default(_that.supportsModelOverride,_that.supportsSystemPrompt,_that.supportedModes,_that.supportedEfforts,_that.supportedPermissions);case _:
  return null;

}
}

}

/// @nodoc


class _ProviderCapabilities implements ProviderCapabilities {
  const _ProviderCapabilities({this.supportsModelOverride = false, this.supportsSystemPrompt = false, final  Set<ChatMode> supportedModes = const <ChatMode>{}, final  Set<ChatEffort> supportedEfforts = const <ChatEffort>{}, final  Set<ChatPermission> supportedPermissions = const <ChatPermission>{}}): _supportedModes = supportedModes,_supportedEfforts = supportedEfforts,_supportedPermissions = supportedPermissions;
  

@override@JsonKey() final  bool supportsModelOverride;
@override@JsonKey() final  bool supportsSystemPrompt;
 final  Set<ChatMode> _supportedModes;
@override@JsonKey() Set<ChatMode> get supportedModes {
  if (_supportedModes is EqualUnmodifiableSetView) return _supportedModes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_supportedModes);
}

 final  Set<ChatEffort> _supportedEfforts;
@override@JsonKey() Set<ChatEffort> get supportedEfforts {
  if (_supportedEfforts is EqualUnmodifiableSetView) return _supportedEfforts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_supportedEfforts);
}

 final  Set<ChatPermission> _supportedPermissions;
@override@JsonKey() Set<ChatPermission> get supportedPermissions {
  if (_supportedPermissions is EqualUnmodifiableSetView) return _supportedPermissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_supportedPermissions);
}


/// Create a copy of ProviderCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderCapabilitiesCopyWith<_ProviderCapabilities> get copyWith => __$ProviderCapabilitiesCopyWithImpl<_ProviderCapabilities>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderCapabilities&&(identical(other.supportsModelOverride, supportsModelOverride) || other.supportsModelOverride == supportsModelOverride)&&(identical(other.supportsSystemPrompt, supportsSystemPrompt) || other.supportsSystemPrompt == supportsSystemPrompt)&&const DeepCollectionEquality().equals(other._supportedModes, _supportedModes)&&const DeepCollectionEquality().equals(other._supportedEfforts, _supportedEfforts)&&const DeepCollectionEquality().equals(other._supportedPermissions, _supportedPermissions));
}


@override
int get hashCode => Object.hash(runtimeType,supportsModelOverride,supportsSystemPrompt,const DeepCollectionEquality().hash(_supportedModes),const DeepCollectionEquality().hash(_supportedEfforts),const DeepCollectionEquality().hash(_supportedPermissions));

@override
String toString() {
  return 'ProviderCapabilities(supportsModelOverride: $supportsModelOverride, supportsSystemPrompt: $supportsSystemPrompt, supportedModes: $supportedModes, supportedEfforts: $supportedEfforts, supportedPermissions: $supportedPermissions)';
}


}

/// @nodoc
abstract mixin class _$ProviderCapabilitiesCopyWith<$Res> implements $ProviderCapabilitiesCopyWith<$Res> {
  factory _$ProviderCapabilitiesCopyWith(_ProviderCapabilities value, $Res Function(_ProviderCapabilities) _then) = __$ProviderCapabilitiesCopyWithImpl;
@override @useResult
$Res call({
 bool supportsModelOverride, bool supportsSystemPrompt, Set<ChatMode> supportedModes, Set<ChatEffort> supportedEfforts, Set<ChatPermission> supportedPermissions
});




}
/// @nodoc
class __$ProviderCapabilitiesCopyWithImpl<$Res>
    implements _$ProviderCapabilitiesCopyWith<$Res> {
  __$ProviderCapabilitiesCopyWithImpl(this._self, this._then);

  final _ProviderCapabilities _self;
  final $Res Function(_ProviderCapabilities) _then;

/// Create a copy of ProviderCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? supportsModelOverride = null,Object? supportsSystemPrompt = null,Object? supportedModes = null,Object? supportedEfforts = null,Object? supportedPermissions = null,}) {
  return _then(_ProviderCapabilities(
supportsModelOverride: null == supportsModelOverride ? _self.supportsModelOverride : supportsModelOverride // ignore: cast_nullable_to_non_nullable
as bool,supportsSystemPrompt: null == supportsSystemPrompt ? _self.supportsSystemPrompt : supportsSystemPrompt // ignore: cast_nullable_to_non_nullable
as bool,supportedModes: null == supportedModes ? _self._supportedModes : supportedModes // ignore: cast_nullable_to_non_nullable
as Set<ChatMode>,supportedEfforts: null == supportedEfforts ? _self._supportedEfforts : supportedEfforts // ignore: cast_nullable_to_non_nullable
as Set<ChatEffort>,supportedPermissions: null == supportedPermissions ? _self._supportedPermissions : supportedPermissions // ignore: cast_nullable_to_non_nullable
as Set<ChatPermission>,
  ));
}


}

// dart format on
