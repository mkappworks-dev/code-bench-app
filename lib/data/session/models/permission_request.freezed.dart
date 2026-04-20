// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'permission_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PermissionRequest {

 String get toolEventId; String get toolName; String get summary; Map<String, dynamic> get input;
/// Create a copy of PermissionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PermissionRequestCopyWith<PermissionRequest> get copyWith => _$PermissionRequestCopyWithImpl<PermissionRequest>(this as PermissionRequest, _$identity);

  /// Serializes this PermissionRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PermissionRequest&&(identical(other.toolEventId, toolEventId) || other.toolEventId == toolEventId)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.input, input));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,toolEventId,toolName,summary,const DeepCollectionEquality().hash(input));

@override
String toString() {
  return 'PermissionRequest(toolEventId: $toolEventId, toolName: $toolName, summary: $summary, input: $input)';
}


}

/// @nodoc
abstract mixin class $PermissionRequestCopyWith<$Res>  {
  factory $PermissionRequestCopyWith(PermissionRequest value, $Res Function(PermissionRequest) _then) = _$PermissionRequestCopyWithImpl;
@useResult
$Res call({
 String toolEventId, String toolName, String summary, Map<String, dynamic> input
});




}
/// @nodoc
class _$PermissionRequestCopyWithImpl<$Res>
    implements $PermissionRequestCopyWith<$Res> {
  _$PermissionRequestCopyWithImpl(this._self, this._then);

  final PermissionRequest _self;
  final $Res Function(PermissionRequest) _then;

/// Create a copy of PermissionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? toolEventId = null,Object? toolName = null,Object? summary = null,Object? input = null,}) {
  return _then(_self.copyWith(
toolEventId: null == toolEventId ? _self.toolEventId : toolEventId // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [PermissionRequest].
extension PermissionRequestPatterns on PermissionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PermissionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PermissionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PermissionRequest value)  $default,){
final _that = this;
switch (_that) {
case _PermissionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PermissionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PermissionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String toolEventId,  String toolName,  String summary,  Map<String, dynamic> input)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PermissionRequest() when $default != null:
return $default(_that.toolEventId,_that.toolName,_that.summary,_that.input);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String toolEventId,  String toolName,  String summary,  Map<String, dynamic> input)  $default,) {final _that = this;
switch (_that) {
case _PermissionRequest():
return $default(_that.toolEventId,_that.toolName,_that.summary,_that.input);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String toolEventId,  String toolName,  String summary,  Map<String, dynamic> input)?  $default,) {final _that = this;
switch (_that) {
case _PermissionRequest() when $default != null:
return $default(_that.toolEventId,_that.toolName,_that.summary,_that.input);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PermissionRequest implements PermissionRequest {
  const _PermissionRequest({required this.toolEventId, required this.toolName, required this.summary, required final  Map<String, dynamic> input}): _input = input;
  factory _PermissionRequest.fromJson(Map<String, dynamic> json) => _$PermissionRequestFromJson(json);

@override final  String toolEventId;
@override final  String toolName;
@override final  String summary;
 final  Map<String, dynamic> _input;
@override Map<String, dynamic> get input {
  if (_input is EqualUnmodifiableMapView) return _input;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_input);
}


/// Create a copy of PermissionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PermissionRequestCopyWith<_PermissionRequest> get copyWith => __$PermissionRequestCopyWithImpl<_PermissionRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PermissionRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PermissionRequest&&(identical(other.toolEventId, toolEventId) || other.toolEventId == toolEventId)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._input, _input));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,toolEventId,toolName,summary,const DeepCollectionEquality().hash(_input));

@override
String toString() {
  return 'PermissionRequest(toolEventId: $toolEventId, toolName: $toolName, summary: $summary, input: $input)';
}


}

/// @nodoc
abstract mixin class _$PermissionRequestCopyWith<$Res> implements $PermissionRequestCopyWith<$Res> {
  factory _$PermissionRequestCopyWith(_PermissionRequest value, $Res Function(_PermissionRequest) _then) = __$PermissionRequestCopyWithImpl;
@override @useResult
$Res call({
 String toolEventId, String toolName, String summary, Map<String, dynamic> input
});




}
/// @nodoc
class __$PermissionRequestCopyWithImpl<$Res>
    implements _$PermissionRequestCopyWith<$Res> {
  __$PermissionRequestCopyWithImpl(this._self, this._then);

  final _PermissionRequest _self;
  final $Res Function(_PermissionRequest) _then;

/// Create a copy of PermissionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? toolEventId = null,Object? toolName = null,Object? summary = null,Object? input = null,}) {
  return _then(_PermissionRequest(
toolEventId: null == toolEventId ? _self.toolEventId : toolEventId // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,input: null == input ? _self._input : input // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
