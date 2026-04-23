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

/// Stable identity for the emission. Prefer the provider's tool-use
/// block id when available (Anthropic `tool_use.id`, OpenAI
/// `tool_call.id`); fall back to a UUID v4. Lets the emitter update a
/// [running] event into a terminal state without ambiguity when the
/// model calls the same tool twice in a single turn.
 String get id; String get type; String get toolName; ToolStatus get status; Map<String, dynamic> get input; String? get output; String? get filePath; int? get durationMs; int? get tokensIn; int? get tokensOut;/// Short human-readable error summary. Set **only** when [status] is
/// [ToolStatus.error]. Must not contain secrets — emitters should log
/// `runtimeType` via `dLog` and pass a scrubbed message here (see the
/// "no PAT header logging" rule in `macos/Runner/README.md`).
 String? get error; ToolEventSource get source;
/// Create a copy of ToolEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolEventCopyWith<ToolEvent> get copyWith => _$ToolEventCopyWithImpl<ToolEvent>(this as ToolEvent, _$identity);

  /// Serializes this ToolEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.input, input)&&(identical(other.output, output) || other.output == output)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.tokensIn, tokensIn) || other.tokensIn == tokensIn)&&(identical(other.tokensOut, tokensOut) || other.tokensOut == tokensOut)&&(identical(other.error, error) || other.error == error)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,toolName,status,const DeepCollectionEquality().hash(input),output,filePath,durationMs,tokensIn,tokensOut,error,source);

@override
String toString() {
  return 'ToolEvent(id: $id, type: $type, toolName: $toolName, status: $status, input: $input, output: $output, filePath: $filePath, durationMs: $durationMs, tokensIn: $tokensIn, tokensOut: $tokensOut, error: $error, source: $source)';
}


}

/// @nodoc
abstract mixin class $ToolEventCopyWith<$Res>  {
  factory $ToolEventCopyWith(ToolEvent value, $Res Function(ToolEvent) _then) = _$ToolEventCopyWithImpl;
@useResult
$Res call({
 String id, String type, String toolName, ToolStatus status, Map<String, dynamic> input, String? output, String? filePath, int? durationMs, int? tokensIn, int? tokensOut, String? error, ToolEventSource source
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? toolName = null,Object? status = null,Object? input = null,Object? output = freezed,Object? filePath = freezed,Object? durationMs = freezed,Object? tokensIn = freezed,Object? tokensOut = freezed,Object? error = freezed,Object? source = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ToolStatus,input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String?,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,tokensIn: freezed == tokensIn ? _self.tokensIn : tokensIn // ignore: cast_nullable_to_non_nullable
as int?,tokensOut: freezed == tokensOut ? _self.tokensOut : tokensOut // ignore: cast_nullable_to_non_nullable
as int?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ToolEventSource,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String toolName,  ToolStatus status,  Map<String, dynamic> input,  String? output,  String? filePath,  int? durationMs,  int? tokensIn,  int? tokensOut,  String? error,  ToolEventSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolEvent() when $default != null:
return $default(_that.id,_that.type,_that.toolName,_that.status,_that.input,_that.output,_that.filePath,_that.durationMs,_that.tokensIn,_that.tokensOut,_that.error,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String toolName,  ToolStatus status,  Map<String, dynamic> input,  String? output,  String? filePath,  int? durationMs,  int? tokensIn,  int? tokensOut,  String? error,  ToolEventSource source)  $default,) {final _that = this;
switch (_that) {
case _ToolEvent():
return $default(_that.id,_that.type,_that.toolName,_that.status,_that.input,_that.output,_that.filePath,_that.durationMs,_that.tokensIn,_that.tokensOut,_that.error,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String toolName,  ToolStatus status,  Map<String, dynamic> input,  String? output,  String? filePath,  int? durationMs,  int? tokensIn,  int? tokensOut,  String? error,  ToolEventSource source)?  $default,) {final _that = this;
switch (_that) {
case _ToolEvent() when $default != null:
return $default(_that.id,_that.type,_that.toolName,_that.status,_that.input,_that.output,_that.filePath,_that.durationMs,_that.tokensIn,_that.tokensOut,_that.error,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ToolEvent implements ToolEvent {
  const _ToolEvent({required this.id, required this.type, required this.toolName, this.status = ToolStatus.running, final  Map<String, dynamic> input = const {}, this.output, this.filePath, this.durationMs, this.tokensIn, this.tokensOut, this.error, this.source = ToolEventSource.agentLoop}): _input = input;
  factory _ToolEvent.fromJson(Map<String, dynamic> json) => _$ToolEventFromJson(json);

/// Stable identity for the emission. Prefer the provider's tool-use
/// block id when available (Anthropic `tool_use.id`, OpenAI
/// `tool_call.id`); fall back to a UUID v4. Lets the emitter update a
/// [running] event into a terminal state without ambiguity when the
/// model calls the same tool twice in a single turn.
@override final  String id;
@override final  String type;
@override final  String toolName;
@override@JsonKey() final  ToolStatus status;
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
/// Short human-readable error summary. Set **only** when [status] is
/// [ToolStatus.error]. Must not contain secrets — emitters should log
/// `runtimeType` via `dLog` and pass a scrubbed message here (see the
/// "no PAT header logging" rule in `macos/Runner/README.md`).
@override final  String? error;
@override@JsonKey() final  ToolEventSource source;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._input, _input)&&(identical(other.output, output) || other.output == output)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.tokensIn, tokensIn) || other.tokensIn == tokensIn)&&(identical(other.tokensOut, tokensOut) || other.tokensOut == tokensOut)&&(identical(other.error, error) || other.error == error)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,toolName,status,const DeepCollectionEquality().hash(_input),output,filePath,durationMs,tokensIn,tokensOut,error,source);

@override
String toString() {
  return 'ToolEvent(id: $id, type: $type, toolName: $toolName, status: $status, input: $input, output: $output, filePath: $filePath, durationMs: $durationMs, tokensIn: $tokensIn, tokensOut: $tokensOut, error: $error, source: $source)';
}


}

/// @nodoc
abstract mixin class _$ToolEventCopyWith<$Res> implements $ToolEventCopyWith<$Res> {
  factory _$ToolEventCopyWith(_ToolEvent value, $Res Function(_ToolEvent) _then) = __$ToolEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String toolName, ToolStatus status, Map<String, dynamic> input, String? output, String? filePath, int? durationMs, int? tokensIn, int? tokensOut, String? error, ToolEventSource source
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? toolName = null,Object? status = null,Object? input = null,Object? output = freezed,Object? filePath = freezed,Object? durationMs = freezed,Object? tokensIn = freezed,Object? tokensOut = freezed,Object? error = freezed,Object? source = null,}) {
  return _then(_ToolEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ToolStatus,input: null == input ? _self._input : input // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String?,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,tokensIn: freezed == tokensIn ? _self.tokensIn : tokensIn // ignore: cast_nullable_to_non_nullable
as int?,tokensOut: freezed == tokensOut ? _self.tokensOut : tokensOut // ignore: cast_nullable_to_non_nullable
as int?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ToolEventSource,
  ));
}


}

// dart format on
