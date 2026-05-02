// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StreamEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StreamEvent()';
}


}

/// @nodoc
class $StreamEventCopyWith<$Res>  {
$StreamEventCopyWith(StreamEvent _, $Res Function(StreamEvent) __);
}


/// Adds pattern-matching-related methods to [StreamEvent].
extension StreamEventPatterns on StreamEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StreamTextDelta value)?  textDelta,TResult Function( StreamToolCallStart value)?  toolCallStart,TResult Function( StreamToolCallArgsDelta value)?  toolCallArgsDelta,TResult Function( StreamToolCallEnd value)?  toolCallEnd,TResult Function( StreamFinish value)?  finish,TResult Function( TextDelta value)?  cliTextDelta,TResult Function( ToolUseStart value)?  cliToolUseStart,TResult Function( ToolUseInputDelta value)?  cliToolUseInputDelta,TResult Function( ToolUseComplete value)?  cliToolUseComplete,TResult Function( ToolResult value)?  cliToolResult,TResult Function( ThinkingDelta value)?  cliThinkingDelta,TResult Function( StreamDone value)?  cliStreamDone,TResult Function( StreamParseFailure value)?  cliStreamParseFailure,TResult Function( StreamError value)?  cliStreamError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StreamTextDelta() when textDelta != null:
return textDelta(_that);case StreamToolCallStart() when toolCallStart != null:
return toolCallStart(_that);case StreamToolCallArgsDelta() when toolCallArgsDelta != null:
return toolCallArgsDelta(_that);case StreamToolCallEnd() when toolCallEnd != null:
return toolCallEnd(_that);case StreamFinish() when finish != null:
return finish(_that);case TextDelta() when cliTextDelta != null:
return cliTextDelta(_that);case ToolUseStart() when cliToolUseStart != null:
return cliToolUseStart(_that);case ToolUseInputDelta() when cliToolUseInputDelta != null:
return cliToolUseInputDelta(_that);case ToolUseComplete() when cliToolUseComplete != null:
return cliToolUseComplete(_that);case ToolResult() when cliToolResult != null:
return cliToolResult(_that);case ThinkingDelta() when cliThinkingDelta != null:
return cliThinkingDelta(_that);case StreamDone() when cliStreamDone != null:
return cliStreamDone(_that);case StreamParseFailure() when cliStreamParseFailure != null:
return cliStreamParseFailure(_that);case StreamError() when cliStreamError != null:
return cliStreamError(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StreamTextDelta value)  textDelta,required TResult Function( StreamToolCallStart value)  toolCallStart,required TResult Function( StreamToolCallArgsDelta value)  toolCallArgsDelta,required TResult Function( StreamToolCallEnd value)  toolCallEnd,required TResult Function( StreamFinish value)  finish,required TResult Function( TextDelta value)  cliTextDelta,required TResult Function( ToolUseStart value)  cliToolUseStart,required TResult Function( ToolUseInputDelta value)  cliToolUseInputDelta,required TResult Function( ToolUseComplete value)  cliToolUseComplete,required TResult Function( ToolResult value)  cliToolResult,required TResult Function( ThinkingDelta value)  cliThinkingDelta,required TResult Function( StreamDone value)  cliStreamDone,required TResult Function( StreamParseFailure value)  cliStreamParseFailure,required TResult Function( StreamError value)  cliStreamError,}){
final _that = this;
switch (_that) {
case StreamTextDelta():
return textDelta(_that);case StreamToolCallStart():
return toolCallStart(_that);case StreamToolCallArgsDelta():
return toolCallArgsDelta(_that);case StreamToolCallEnd():
return toolCallEnd(_that);case StreamFinish():
return finish(_that);case TextDelta():
return cliTextDelta(_that);case ToolUseStart():
return cliToolUseStart(_that);case ToolUseInputDelta():
return cliToolUseInputDelta(_that);case ToolUseComplete():
return cliToolUseComplete(_that);case ToolResult():
return cliToolResult(_that);case ThinkingDelta():
return cliThinkingDelta(_that);case StreamDone():
return cliStreamDone(_that);case StreamParseFailure():
return cliStreamParseFailure(_that);case StreamError():
return cliStreamError(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StreamTextDelta value)?  textDelta,TResult? Function( StreamToolCallStart value)?  toolCallStart,TResult? Function( StreamToolCallArgsDelta value)?  toolCallArgsDelta,TResult? Function( StreamToolCallEnd value)?  toolCallEnd,TResult? Function( StreamFinish value)?  finish,TResult? Function( TextDelta value)?  cliTextDelta,TResult? Function( ToolUseStart value)?  cliToolUseStart,TResult? Function( ToolUseInputDelta value)?  cliToolUseInputDelta,TResult? Function( ToolUseComplete value)?  cliToolUseComplete,TResult? Function( ToolResult value)?  cliToolResult,TResult? Function( ThinkingDelta value)?  cliThinkingDelta,TResult? Function( StreamDone value)?  cliStreamDone,TResult? Function( StreamParseFailure value)?  cliStreamParseFailure,TResult? Function( StreamError value)?  cliStreamError,}){
final _that = this;
switch (_that) {
case StreamTextDelta() when textDelta != null:
return textDelta(_that);case StreamToolCallStart() when toolCallStart != null:
return toolCallStart(_that);case StreamToolCallArgsDelta() when toolCallArgsDelta != null:
return toolCallArgsDelta(_that);case StreamToolCallEnd() when toolCallEnd != null:
return toolCallEnd(_that);case StreamFinish() when finish != null:
return finish(_that);case TextDelta() when cliTextDelta != null:
return cliTextDelta(_that);case ToolUseStart() when cliToolUseStart != null:
return cliToolUseStart(_that);case ToolUseInputDelta() when cliToolUseInputDelta != null:
return cliToolUseInputDelta(_that);case ToolUseComplete() when cliToolUseComplete != null:
return cliToolUseComplete(_that);case ToolResult() when cliToolResult != null:
return cliToolResult(_that);case ThinkingDelta() when cliThinkingDelta != null:
return cliThinkingDelta(_that);case StreamDone() when cliStreamDone != null:
return cliStreamDone(_that);case StreamParseFailure() when cliStreamParseFailure != null:
return cliStreamParseFailure(_that);case StreamError() when cliStreamError != null:
return cliStreamError(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  textDelta,TResult Function( String id,  String name)?  toolCallStart,TResult Function( String id,  String argsJsonFragment)?  toolCallArgsDelta,TResult Function( String id)?  toolCallEnd,TResult Function( String reason)?  finish,TResult Function( String text)?  cliTextDelta,TResult Function( String id,  String name)?  cliToolUseStart,TResult Function( String id,  String partialJson)?  cliToolUseInputDelta,TResult Function( String id,  Map<String, dynamic> input)?  cliToolUseComplete,TResult Function( String toolUseId,  String content,  bool isError)?  cliToolResult,TResult Function( String text)?  cliThinkingDelta,TResult Function()?  cliStreamDone,TResult Function( String line,  Object error)?  cliStreamParseFailure,TResult Function( Object failure)?  cliStreamError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StreamTextDelta() when textDelta != null:
return textDelta(_that.text);case StreamToolCallStart() when toolCallStart != null:
return toolCallStart(_that.id,_that.name);case StreamToolCallArgsDelta() when toolCallArgsDelta != null:
return toolCallArgsDelta(_that.id,_that.argsJsonFragment);case StreamToolCallEnd() when toolCallEnd != null:
return toolCallEnd(_that.id);case StreamFinish() when finish != null:
return finish(_that.reason);case TextDelta() when cliTextDelta != null:
return cliTextDelta(_that.text);case ToolUseStart() when cliToolUseStart != null:
return cliToolUseStart(_that.id,_that.name);case ToolUseInputDelta() when cliToolUseInputDelta != null:
return cliToolUseInputDelta(_that.id,_that.partialJson);case ToolUseComplete() when cliToolUseComplete != null:
return cliToolUseComplete(_that.id,_that.input);case ToolResult() when cliToolResult != null:
return cliToolResult(_that.toolUseId,_that.content,_that.isError);case ThinkingDelta() when cliThinkingDelta != null:
return cliThinkingDelta(_that.text);case StreamDone() when cliStreamDone != null:
return cliStreamDone();case StreamParseFailure() when cliStreamParseFailure != null:
return cliStreamParseFailure(_that.line,_that.error);case StreamError() when cliStreamError != null:
return cliStreamError(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  textDelta,required TResult Function( String id,  String name)  toolCallStart,required TResult Function( String id,  String argsJsonFragment)  toolCallArgsDelta,required TResult Function( String id)  toolCallEnd,required TResult Function( String reason)  finish,required TResult Function( String text)  cliTextDelta,required TResult Function( String id,  String name)  cliToolUseStart,required TResult Function( String id,  String partialJson)  cliToolUseInputDelta,required TResult Function( String id,  Map<String, dynamic> input)  cliToolUseComplete,required TResult Function( String toolUseId,  String content,  bool isError)  cliToolResult,required TResult Function( String text)  cliThinkingDelta,required TResult Function()  cliStreamDone,required TResult Function( String line,  Object error)  cliStreamParseFailure,required TResult Function( Object failure)  cliStreamError,}) {final _that = this;
switch (_that) {
case StreamTextDelta():
return textDelta(_that.text);case StreamToolCallStart():
return toolCallStart(_that.id,_that.name);case StreamToolCallArgsDelta():
return toolCallArgsDelta(_that.id,_that.argsJsonFragment);case StreamToolCallEnd():
return toolCallEnd(_that.id);case StreamFinish():
return finish(_that.reason);case TextDelta():
return cliTextDelta(_that.text);case ToolUseStart():
return cliToolUseStart(_that.id,_that.name);case ToolUseInputDelta():
return cliToolUseInputDelta(_that.id,_that.partialJson);case ToolUseComplete():
return cliToolUseComplete(_that.id,_that.input);case ToolResult():
return cliToolResult(_that.toolUseId,_that.content,_that.isError);case ThinkingDelta():
return cliThinkingDelta(_that.text);case StreamDone():
return cliStreamDone();case StreamParseFailure():
return cliStreamParseFailure(_that.line,_that.error);case StreamError():
return cliStreamError(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  textDelta,TResult? Function( String id,  String name)?  toolCallStart,TResult? Function( String id,  String argsJsonFragment)?  toolCallArgsDelta,TResult? Function( String id)?  toolCallEnd,TResult? Function( String reason)?  finish,TResult? Function( String text)?  cliTextDelta,TResult? Function( String id,  String name)?  cliToolUseStart,TResult? Function( String id,  String partialJson)?  cliToolUseInputDelta,TResult? Function( String id,  Map<String, dynamic> input)?  cliToolUseComplete,TResult? Function( String toolUseId,  String content,  bool isError)?  cliToolResult,TResult? Function( String text)?  cliThinkingDelta,TResult? Function()?  cliStreamDone,TResult? Function( String line,  Object error)?  cliStreamParseFailure,TResult? Function( Object failure)?  cliStreamError,}) {final _that = this;
switch (_that) {
case StreamTextDelta() when textDelta != null:
return textDelta(_that.text);case StreamToolCallStart() when toolCallStart != null:
return toolCallStart(_that.id,_that.name);case StreamToolCallArgsDelta() when toolCallArgsDelta != null:
return toolCallArgsDelta(_that.id,_that.argsJsonFragment);case StreamToolCallEnd() when toolCallEnd != null:
return toolCallEnd(_that.id);case StreamFinish() when finish != null:
return finish(_that.reason);case TextDelta() when cliTextDelta != null:
return cliTextDelta(_that.text);case ToolUseStart() when cliToolUseStart != null:
return cliToolUseStart(_that.id,_that.name);case ToolUseInputDelta() when cliToolUseInputDelta != null:
return cliToolUseInputDelta(_that.id,_that.partialJson);case ToolUseComplete() when cliToolUseComplete != null:
return cliToolUseComplete(_that.id,_that.input);case ToolResult() when cliToolResult != null:
return cliToolResult(_that.toolUseId,_that.content,_that.isError);case ThinkingDelta() when cliThinkingDelta != null:
return cliThinkingDelta(_that.text);case StreamDone() when cliStreamDone != null:
return cliStreamDone();case StreamParseFailure() when cliStreamParseFailure != null:
return cliStreamParseFailure(_that.line,_that.error);case StreamError() when cliStreamError != null:
return cliStreamError(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class StreamTextDelta implements StreamEvent {
  const StreamTextDelta(this.text);
  

 final  String text;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamTextDeltaCopyWith<StreamTextDelta> get copyWith => _$StreamTextDeltaCopyWithImpl<StreamTextDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamTextDelta&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'StreamEvent.textDelta(text: $text)';
}


}

/// @nodoc
abstract mixin class $StreamTextDeltaCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $StreamTextDeltaCopyWith(StreamTextDelta value, $Res Function(StreamTextDelta) _then) = _$StreamTextDeltaCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$StreamTextDeltaCopyWithImpl<$Res>
    implements $StreamTextDeltaCopyWith<$Res> {
  _$StreamTextDeltaCopyWithImpl(this._self, this._then);

  final StreamTextDelta _self;
  final $Res Function(StreamTextDelta) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(StreamTextDelta(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StreamToolCallStart implements StreamEvent {
  const StreamToolCallStart({required this.id, required this.name});
  

 final  String id;
 final  String name;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamToolCallStartCopyWith<StreamToolCallStart> get copyWith => _$StreamToolCallStartCopyWithImpl<StreamToolCallStart>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamToolCallStart&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'StreamEvent.toolCallStart(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $StreamToolCallStartCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $StreamToolCallStartCopyWith(StreamToolCallStart value, $Res Function(StreamToolCallStart) _then) = _$StreamToolCallStartCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$StreamToolCallStartCopyWithImpl<$Res>
    implements $StreamToolCallStartCopyWith<$Res> {
  _$StreamToolCallStartCopyWithImpl(this._self, this._then);

  final StreamToolCallStart _self;
  final $Res Function(StreamToolCallStart) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(StreamToolCallStart(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StreamToolCallArgsDelta implements StreamEvent {
  const StreamToolCallArgsDelta({required this.id, required this.argsJsonFragment});
  

 final  String id;
 final  String argsJsonFragment;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamToolCallArgsDeltaCopyWith<StreamToolCallArgsDelta> get copyWith => _$StreamToolCallArgsDeltaCopyWithImpl<StreamToolCallArgsDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamToolCallArgsDelta&&(identical(other.id, id) || other.id == id)&&(identical(other.argsJsonFragment, argsJsonFragment) || other.argsJsonFragment == argsJsonFragment));
}


@override
int get hashCode => Object.hash(runtimeType,id,argsJsonFragment);

@override
String toString() {
  return 'StreamEvent.toolCallArgsDelta(id: $id, argsJsonFragment: $argsJsonFragment)';
}


}

/// @nodoc
abstract mixin class $StreamToolCallArgsDeltaCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $StreamToolCallArgsDeltaCopyWith(StreamToolCallArgsDelta value, $Res Function(StreamToolCallArgsDelta) _then) = _$StreamToolCallArgsDeltaCopyWithImpl;
@useResult
$Res call({
 String id, String argsJsonFragment
});




}
/// @nodoc
class _$StreamToolCallArgsDeltaCopyWithImpl<$Res>
    implements $StreamToolCallArgsDeltaCopyWith<$Res> {
  _$StreamToolCallArgsDeltaCopyWithImpl(this._self, this._then);

  final StreamToolCallArgsDelta _self;
  final $Res Function(StreamToolCallArgsDelta) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? argsJsonFragment = null,}) {
  return _then(StreamToolCallArgsDelta(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,argsJsonFragment: null == argsJsonFragment ? _self.argsJsonFragment : argsJsonFragment // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StreamToolCallEnd implements StreamEvent {
  const StreamToolCallEnd({required this.id});
  

 final  String id;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamToolCallEndCopyWith<StreamToolCallEnd> get copyWith => _$StreamToolCallEndCopyWithImpl<StreamToolCallEnd>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamToolCallEnd&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'StreamEvent.toolCallEnd(id: $id)';
}


}

/// @nodoc
abstract mixin class $StreamToolCallEndCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $StreamToolCallEndCopyWith(StreamToolCallEnd value, $Res Function(StreamToolCallEnd) _then) = _$StreamToolCallEndCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$StreamToolCallEndCopyWithImpl<$Res>
    implements $StreamToolCallEndCopyWith<$Res> {
  _$StreamToolCallEndCopyWithImpl(this._self, this._then);

  final StreamToolCallEnd _self;
  final $Res Function(StreamToolCallEnd) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(StreamToolCallEnd(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StreamFinish implements StreamEvent {
  const StreamFinish({required this.reason});
  

 final  String reason;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamFinishCopyWith<StreamFinish> get copyWith => _$StreamFinishCopyWithImpl<StreamFinish>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamFinish&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'StreamEvent.finish(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $StreamFinishCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $StreamFinishCopyWith(StreamFinish value, $Res Function(StreamFinish) _then) = _$StreamFinishCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$StreamFinishCopyWithImpl<$Res>
    implements $StreamFinishCopyWith<$Res> {
  _$StreamFinishCopyWithImpl(this._self, this._then);

  final StreamFinish _self;
  final $Res Function(StreamFinish) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(StreamFinish(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TextDelta implements StreamEvent {
  const TextDelta(this.text);
  

 final  String text;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextDeltaCopyWith<TextDelta> get copyWith => _$TextDeltaCopyWithImpl<TextDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextDelta&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'StreamEvent.cliTextDelta(text: $text)';
}


}

/// @nodoc
abstract mixin class $TextDeltaCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $TextDeltaCopyWith(TextDelta value, $Res Function(TextDelta) _then) = _$TextDeltaCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$TextDeltaCopyWithImpl<$Res>
    implements $TextDeltaCopyWith<$Res> {
  _$TextDeltaCopyWithImpl(this._self, this._then);

  final TextDelta _self;
  final $Res Function(TextDelta) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(TextDelta(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ToolUseStart implements StreamEvent {
  const ToolUseStart({required this.id, required this.name});
  

 final  String id;
 final  String name;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolUseStartCopyWith<ToolUseStart> get copyWith => _$ToolUseStartCopyWithImpl<ToolUseStart>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolUseStart&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'StreamEvent.cliToolUseStart(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $ToolUseStartCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $ToolUseStartCopyWith(ToolUseStart value, $Res Function(ToolUseStart) _then) = _$ToolUseStartCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$ToolUseStartCopyWithImpl<$Res>
    implements $ToolUseStartCopyWith<$Res> {
  _$ToolUseStartCopyWithImpl(this._self, this._then);

  final ToolUseStart _self;
  final $Res Function(ToolUseStart) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(ToolUseStart(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ToolUseInputDelta implements StreamEvent {
  const ToolUseInputDelta({required this.id, required this.partialJson});
  

 final  String id;
 final  String partialJson;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolUseInputDeltaCopyWith<ToolUseInputDelta> get copyWith => _$ToolUseInputDeltaCopyWithImpl<ToolUseInputDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolUseInputDelta&&(identical(other.id, id) || other.id == id)&&(identical(other.partialJson, partialJson) || other.partialJson == partialJson));
}


@override
int get hashCode => Object.hash(runtimeType,id,partialJson);

@override
String toString() {
  return 'StreamEvent.cliToolUseInputDelta(id: $id, partialJson: $partialJson)';
}


}

/// @nodoc
abstract mixin class $ToolUseInputDeltaCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $ToolUseInputDeltaCopyWith(ToolUseInputDelta value, $Res Function(ToolUseInputDelta) _then) = _$ToolUseInputDeltaCopyWithImpl;
@useResult
$Res call({
 String id, String partialJson
});




}
/// @nodoc
class _$ToolUseInputDeltaCopyWithImpl<$Res>
    implements $ToolUseInputDeltaCopyWith<$Res> {
  _$ToolUseInputDeltaCopyWithImpl(this._self, this._then);

  final ToolUseInputDelta _self;
  final $Res Function(ToolUseInputDelta) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? partialJson = null,}) {
  return _then(ToolUseInputDelta(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partialJson: null == partialJson ? _self.partialJson : partialJson // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ToolUseComplete implements StreamEvent {
  const ToolUseComplete({required this.id, required final  Map<String, dynamic> input}): _input = input;
  

 final  String id;
 final  Map<String, dynamic> _input;
 Map<String, dynamic> get input {
  if (_input is EqualUnmodifiableMapView) return _input;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_input);
}


/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolUseCompleteCopyWith<ToolUseComplete> get copyWith => _$ToolUseCompleteCopyWithImpl<ToolUseComplete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolUseComplete&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._input, _input));
}


@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_input));

@override
String toString() {
  return 'StreamEvent.cliToolUseComplete(id: $id, input: $input)';
}


}

/// @nodoc
abstract mixin class $ToolUseCompleteCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $ToolUseCompleteCopyWith(ToolUseComplete value, $Res Function(ToolUseComplete) _then) = _$ToolUseCompleteCopyWithImpl;
@useResult
$Res call({
 String id, Map<String, dynamic> input
});




}
/// @nodoc
class _$ToolUseCompleteCopyWithImpl<$Res>
    implements $ToolUseCompleteCopyWith<$Res> {
  _$ToolUseCompleteCopyWithImpl(this._self, this._then);

  final ToolUseComplete _self;
  final $Res Function(ToolUseComplete) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? input = null,}) {
  return _then(ToolUseComplete(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,input: null == input ? _self._input : input // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc


class ToolResult implements StreamEvent {
  const ToolResult({required this.toolUseId, required this.content, required this.isError});
  

 final  String toolUseId;
 final  String content;
 final  bool isError;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolResultCopyWith<ToolResult> get copyWith => _$ToolResultCopyWithImpl<ToolResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolResult&&(identical(other.toolUseId, toolUseId) || other.toolUseId == toolUseId)&&(identical(other.content, content) || other.content == content)&&(identical(other.isError, isError) || other.isError == isError));
}


@override
int get hashCode => Object.hash(runtimeType,toolUseId,content,isError);

@override
String toString() {
  return 'StreamEvent.cliToolResult(toolUseId: $toolUseId, content: $content, isError: $isError)';
}


}

/// @nodoc
abstract mixin class $ToolResultCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $ToolResultCopyWith(ToolResult value, $Res Function(ToolResult) _then) = _$ToolResultCopyWithImpl;
@useResult
$Res call({
 String toolUseId, String content, bool isError
});




}
/// @nodoc
class _$ToolResultCopyWithImpl<$Res>
    implements $ToolResultCopyWith<$Res> {
  _$ToolResultCopyWithImpl(this._self, this._then);

  final ToolResult _self;
  final $Res Function(ToolResult) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? toolUseId = null,Object? content = null,Object? isError = null,}) {
  return _then(ToolResult(
toolUseId: null == toolUseId ? _self.toolUseId : toolUseId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isError: null == isError ? _self.isError : isError // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class ThinkingDelta implements StreamEvent {
  const ThinkingDelta(this.text);
  

 final  String text;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThinkingDeltaCopyWith<ThinkingDelta> get copyWith => _$ThinkingDeltaCopyWithImpl<ThinkingDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThinkingDelta&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'StreamEvent.cliThinkingDelta(text: $text)';
}


}

/// @nodoc
abstract mixin class $ThinkingDeltaCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $ThinkingDeltaCopyWith(ThinkingDelta value, $Res Function(ThinkingDelta) _then) = _$ThinkingDeltaCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$ThinkingDeltaCopyWithImpl<$Res>
    implements $ThinkingDeltaCopyWith<$Res> {
  _$ThinkingDeltaCopyWithImpl(this._self, this._then);

  final ThinkingDelta _self;
  final $Res Function(ThinkingDelta) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(ThinkingDelta(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StreamDone implements StreamEvent {
  const StreamDone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamDone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StreamEvent.cliStreamDone()';
}


}




/// @nodoc


class StreamParseFailure implements StreamEvent {
  const StreamParseFailure({required this.line, required this.error});
  

 final  String line;
 final  Object error;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamParseFailureCopyWith<StreamParseFailure> get copyWith => _$StreamParseFailureCopyWithImpl<StreamParseFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamParseFailure&&(identical(other.line, line) || other.line == line)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,line,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'StreamEvent.cliStreamParseFailure(line: $line, error: $error)';
}


}

/// @nodoc
abstract mixin class $StreamParseFailureCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $StreamParseFailureCopyWith(StreamParseFailure value, $Res Function(StreamParseFailure) _then) = _$StreamParseFailureCopyWithImpl;
@useResult
$Res call({
 String line, Object error
});




}
/// @nodoc
class _$StreamParseFailureCopyWithImpl<$Res>
    implements $StreamParseFailureCopyWith<$Res> {
  _$StreamParseFailureCopyWithImpl(this._self, this._then);

  final StreamParseFailure _self;
  final $Res Function(StreamParseFailure) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? line = null,Object? error = null,}) {
  return _then(StreamParseFailure(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error ,
  ));
}


}

/// @nodoc


class StreamError implements StreamEvent {
  const StreamError(this.failure);
  

 final  Object failure;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamErrorCopyWith<StreamError> get copyWith => _$StreamErrorCopyWithImpl<StreamError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamError&&const DeepCollectionEquality().equals(other.failure, failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(failure));

@override
String toString() {
  return 'StreamEvent.cliStreamError(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $StreamErrorCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $StreamErrorCopyWith(StreamError value, $Res Function(StreamError) _then) = _$StreamErrorCopyWithImpl;
@useResult
$Res call({
 Object failure
});




}
/// @nodoc
class _$StreamErrorCopyWithImpl<$Res>
    implements $StreamErrorCopyWith<$Res> {
  _$StreamErrorCopyWithImpl(this._self, this._then);

  final StreamError _self;
  final $Res Function(StreamError) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(StreamError(
null == failure ? _self.failure : failure ,
  ));
}


}

// dart format on
