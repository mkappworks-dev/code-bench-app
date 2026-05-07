// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'provider_turn_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProviderTurnSettings {

 String? get modelId; String? get systemPrompt; ChatMode? get mode; ChatEffort? get effort; ChatPermission? get permission;
/// Create a copy of ProviderTurnSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderTurnSettingsCopyWith<ProviderTurnSettings> get copyWith => _$ProviderTurnSettingsCopyWithImpl<ProviderTurnSettings>(this as ProviderTurnSettings, _$identity);

  /// Serializes this ProviderTurnSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderTurnSettings&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.systemPrompt, systemPrompt) || other.systemPrompt == systemPrompt)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.effort, effort) || other.effort == effort)&&(identical(other.permission, permission) || other.permission == permission));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,modelId,systemPrompt,mode,effort,permission);

@override
String toString() {
  return 'ProviderTurnSettings(modelId: $modelId, systemPrompt: $systemPrompt, mode: $mode, effort: $effort, permission: $permission)';
}


}

/// @nodoc
abstract mixin class $ProviderTurnSettingsCopyWith<$Res>  {
  factory $ProviderTurnSettingsCopyWith(ProviderTurnSettings value, $Res Function(ProviderTurnSettings) _then) = _$ProviderTurnSettingsCopyWithImpl;
@useResult
$Res call({
 String? modelId, String? systemPrompt, ChatMode? mode, ChatEffort? effort, ChatPermission? permission
});




}
/// @nodoc
class _$ProviderTurnSettingsCopyWithImpl<$Res>
    implements $ProviderTurnSettingsCopyWith<$Res> {
  _$ProviderTurnSettingsCopyWithImpl(this._self, this._then);

  final ProviderTurnSettings _self;
  final $Res Function(ProviderTurnSettings) _then;

/// Create a copy of ProviderTurnSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modelId = freezed,Object? systemPrompt = freezed,Object? mode = freezed,Object? effort = freezed,Object? permission = freezed,}) {
  return _then(_self.copyWith(
modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,systemPrompt: freezed == systemPrompt ? _self.systemPrompt : systemPrompt // ignore: cast_nullable_to_non_nullable
as String?,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ChatMode?,effort: freezed == effort ? _self.effort : effort // ignore: cast_nullable_to_non_nullable
as ChatEffort?,permission: freezed == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as ChatPermission?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderTurnSettings].
extension ProviderTurnSettingsPatterns on ProviderTurnSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderTurnSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderTurnSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderTurnSettings value)  $default,){
final _that = this;
switch (_that) {
case _ProviderTurnSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderTurnSettings value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderTurnSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? modelId,  String? systemPrompt,  ChatMode? mode,  ChatEffort? effort,  ChatPermission? permission)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderTurnSettings() when $default != null:
return $default(_that.modelId,_that.systemPrompt,_that.mode,_that.effort,_that.permission);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? modelId,  String? systemPrompt,  ChatMode? mode,  ChatEffort? effort,  ChatPermission? permission)  $default,) {final _that = this;
switch (_that) {
case _ProviderTurnSettings():
return $default(_that.modelId,_that.systemPrompt,_that.mode,_that.effort,_that.permission);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? modelId,  String? systemPrompt,  ChatMode? mode,  ChatEffort? effort,  ChatPermission? permission)?  $default,) {final _that = this;
switch (_that) {
case _ProviderTurnSettings() when $default != null:
return $default(_that.modelId,_that.systemPrompt,_that.mode,_that.effort,_that.permission);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderTurnSettings implements ProviderTurnSettings {
  const _ProviderTurnSettings({this.modelId, this.systemPrompt, this.mode, this.effort, this.permission});
  factory _ProviderTurnSettings.fromJson(Map<String, dynamic> json) => _$ProviderTurnSettingsFromJson(json);

@override final  String? modelId;
@override final  String? systemPrompt;
@override final  ChatMode? mode;
@override final  ChatEffort? effort;
@override final  ChatPermission? permission;

/// Create a copy of ProviderTurnSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderTurnSettingsCopyWith<_ProviderTurnSettings> get copyWith => __$ProviderTurnSettingsCopyWithImpl<_ProviderTurnSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderTurnSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderTurnSettings&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.systemPrompt, systemPrompt) || other.systemPrompt == systemPrompt)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.effort, effort) || other.effort == effort)&&(identical(other.permission, permission) || other.permission == permission));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,modelId,systemPrompt,mode,effort,permission);

@override
String toString() {
  return 'ProviderTurnSettings(modelId: $modelId, systemPrompt: $systemPrompt, mode: $mode, effort: $effort, permission: $permission)';
}


}

/// @nodoc
abstract mixin class _$ProviderTurnSettingsCopyWith<$Res> implements $ProviderTurnSettingsCopyWith<$Res> {
  factory _$ProviderTurnSettingsCopyWith(_ProviderTurnSettings value, $Res Function(_ProviderTurnSettings) _then) = __$ProviderTurnSettingsCopyWithImpl;
@override @useResult
$Res call({
 String? modelId, String? systemPrompt, ChatMode? mode, ChatEffort? effort, ChatPermission? permission
});




}
/// @nodoc
class __$ProviderTurnSettingsCopyWithImpl<$Res>
    implements _$ProviderTurnSettingsCopyWith<$Res> {
  __$ProviderTurnSettingsCopyWithImpl(this._self, this._then);

  final _ProviderTurnSettings _self;
  final $Res Function(_ProviderTurnSettings) _then;

/// Create a copy of ProviderTurnSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? modelId = freezed,Object? systemPrompt = freezed,Object? mode = freezed,Object? effort = freezed,Object? permission = freezed,}) {
  return _then(_ProviderTurnSettings(
modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,systemPrompt: freezed == systemPrompt ? _self.systemPrompt : systemPrompt // ignore: cast_nullable_to_non_nullable
as String?,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ChatMode?,effort: freezed == effort ? _self.effort : effort // ignore: cast_nullable_to_non_nullable
as ChatEffort?,permission: freezed == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as ChatPermission?,
  ));
}


}

// dart format on
