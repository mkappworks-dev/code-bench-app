// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tool_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ToolEvent {

 String get type; String get toolName; Map<String, dynamic> get input; String? get output; String? get filePath; int? get durationMs; int? get tokensIn; int? get tokensOut;
/// Create a copy of ToolEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolEventCopyWith<ToolEvent> get copyWith => _$ToolEventCopyWithImpl<ToolEvent>(this as ToolEvent, _$identity);

  /// Serializes this ToolEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&const DeepCollectionEquality().equals(other.input, input)&&(identical(other.output, output) || other.output == output)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.tokensIn, tokensIn) || other.tokensIn == tokensIn)&&(identical(other.tokensOut, tokensOut) || other.tokensOut == tokensOut));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,toolName,const DeepCollectionEquality().hash(input),output,filePath,durationMs,tokensIn,tokensOut);

@override
String toString() {
  return 'ToolEvent(type: $type, toolName: $toolName, input: $input, output: $output, filePath: $filePath, durationMs: $durationMs, tokensIn: $tokensIn, tokensOut: $tokensOut)';
}


}

/// @nodoc
abstract mixin class $ToolEventCopyWith<$Res>  {
  factory $ToolEventCopyWith(ToolEvent value, $Res Function(ToolEvent) _then) = _$ToolEventCopyWithImpl;
@useResult
$Res call({
 String type, String toolName, Map<String, dynamic> input, String? output, String? filePath, int? durationMs, int? tokensIn, int? tokensOut
});




}
/// @nodoc
class _$ToolEventCopyWithImpl<$Res>
    implements $ToolEventCopyWith<$Res> {
  _$ToolEventCopyWithImpl(this._self, this._then);

  final ToolEvent _self;
  final $Res Function(ToolEvent) _then;

/// Create a copy of ToolEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? toolName = null,Object? input = null,Object? output = freezed,Object? filePath = freezed,Object? durationMs = freezed,Object? tokensIn = freezed,Object? tokensOut = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String?,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,tokensIn: freezed == tokensIn ? _self.tokensIn : tokensIn // ignore: cast_nullable_to_non_nullable
as int?,tokensOut: freezed == tokensOut ? _self.tokensOut : tokensOut // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolEvent].
extension ToolEventPatterns on ToolEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolEvent value)  $default,){
final _that = this;
switch (_that) {
case _ToolEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ToolEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String toolName,  Map<String, dynamic> input,  String? output,  String? filePath,  int? durationMs,  int? tokensIn,  int? tokensOut)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolEvent() when $default != null:
return $default(_that.type,_that.toolName,_that.input,_that.output,_that.filePath,_that.durationMs,_that.tokensIn,_that.tokensOut);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String toolName,  Map<String, dynamic> input,  String? output,  String? filePath,  int? durationMs,  int? tokensIn,  int? tokensOut)  $default,) {final _that = this;
switch (_that) {
case _ToolEvent():
return $default(_that.type,_that.toolName,_that.input,_that.output,_that.filePath,_that.durationMs,_that.tokensIn,_that.tokensOut);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String toolName,  Map<String, dynamic> input,  String? output,  String? filePath,  int? durationMs,  int? tokensIn,  int? tokensOut)?  $default,) {final _that = this;
switch (_that) {
case _ToolEvent() when $default != null:
return $default(_that.type,_that.toolName,_that.input,_that.output,_that.filePath,_that.durationMs,_that.tokensIn,_that.tokensOut);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ToolEvent implements ToolEvent {
  const _ToolEvent({required this.type, required this.toolName, final  Map<String, dynamic> input = const {}, this.output, this.filePath, this.durationMs, this.tokensIn, this.tokensOut}): _input = input;
  factory _ToolEvent.fromJson(Map<String, dynamic> json) => _$ToolEventFromJson(json);

@override final  String type;
@override final  String toolName;
 final  Map<String, dynamic> _input;
@override@JsonKey() Map<String, dynamic> get input {
  if (_input is EqualUnmodifiableMapView) return _input;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_input);
}

@override final  String? output;
@override final  String? filePath;
@override final  int? durationMs;
@override final  int? tokensIn;
@override final  int? tokensOut;

/// Create a copy of ToolEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolEventCopyWith<_ToolEvent> get copyWith => __$ToolEventCopyWithImpl<_ToolEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ToolEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&const DeepCollectionEquality().equals(other._input, _input)&&(identical(other.output, output) || other.output == output)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.tokensIn, tokensIn) || other.tokensIn == tokensIn)&&(identical(other.tokensOut, tokensOut) || other.tokensOut == tokensOut));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,toolName,const DeepCollectionEquality().hash(_input),output,filePath,durationMs,tokensIn,tokensOut);

@override
String toString() {
  return 'ToolEvent(type: $type, toolName: $toolName, input: $input, output: $output, filePath: $filePath, durationMs: $durationMs, tokensIn: $tokensIn, tokensOut: $tokensOut)';
}


}

/// @nodoc
abstract mixin class _$ToolEventCopyWith<$Res> implements $ToolEventCopyWith<$Res> {
  factory _$ToolEventCopyWith(_ToolEvent value, $Res Function(_ToolEvent) _then) = __$ToolEventCopyWithImpl;
@override @useResult
$Res call({
 String type, String toolName, Map<String, dynamic> input, String? output, String? filePath, int? durationMs, int? tokensIn, int? tokensOut
});




}
/// @nodoc
class __$ToolEventCopyWithImpl<$Res>
    implements _$ToolEventCopyWith<$Res> {
  __$ToolEventCopyWithImpl(this._self, this._then);

  final _ToolEvent _self;
  final $Res Function(_ToolEvent) _then;

/// Create a copy of ToolEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? toolName = null,Object? input = null,Object? output = freezed,Object? filePath = freezed,Object? durationMs = freezed,Object? tokensIn = freezed,Object? tokensOut = freezed,}) {
  return _then(_ToolEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,input: null == input ? _self._input : input // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String?,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,tokensIn: freezed == tokensIn ? _self.tokensIn : tokensIn // ignore: cast_nullable_to_non_nullable
as int?,tokensOut: freezed == tokensOut ? _self.tokensOut : tokensOut // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
