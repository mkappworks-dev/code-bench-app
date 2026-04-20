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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StreamTextDelta value)?  textDelta,TResult Function( StreamToolCallStart value)?  toolCallStart,TResult Function( StreamToolCallArgsDelta value)?  toolCallArgsDelta,TResult Function( StreamToolCallEnd value)?  toolCallEnd,TResult Function( StreamFinish value)?  finish,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StreamTextDelta() when textDelta != null:
return textDelta(_that);case StreamToolCallStart() when toolCallStart != null:
return toolCallStart(_that);case StreamToolCallArgsDelta() when toolCallArgsDelta != null:
return toolCallArgsDelta(_that);case StreamToolCallEnd() when toolCallEnd != null:
return toolCallEnd(_that);case StreamFinish() when finish != null:
return finish(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StreamTextDelta value)  textDelta,required TResult Function( StreamToolCallStart value)  toolCallStart,required TResult Function( StreamToolCallArgsDelta value)  toolCallArgsDelta,required TResult Function( StreamToolCallEnd value)  toolCallEnd,required TResult Function( StreamFinish value)  finish,}){
final _that = this;
switch (_that) {
case StreamTextDelta():
return textDelta(_that);case StreamToolCallStart():
return toolCallStart(_that);case StreamToolCallArgsDelta():
return toolCallArgsDelta(_that);case StreamToolCallEnd():
return toolCallEnd(_that);case StreamFinish():
return finish(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StreamTextDelta value)?  textDelta,TResult? Function( StreamToolCallStart value)?  toolCallStart,TResult? Function( StreamToolCallArgsDelta value)?  toolCallArgsDelta,TResult? Function( StreamToolCallEnd value)?  toolCallEnd,TResult? Function( StreamFinish value)?  finish,}){
final _that = this;
switch (_that) {
case StreamTextDelta() when textDelta != null:
return textDelta(_that);case StreamToolCallStart() when toolCallStart != null:
return toolCallStart(_that);case StreamToolCallArgsDelta() when toolCallArgsDelta != null:
return toolCallArgsDelta(_that);case StreamToolCallEnd() when toolCallEnd != null:
return toolCallEnd(_that);case StreamFinish() when finish != null:
return finish(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  textDelta,TResult Function( String id,  String name)?  toolCallStart,TResult Function( String id,  String argsJsonFragment)?  toolCallArgsDelta,TResult Function( String id)?  toolCallEnd,TResult Function( String reason)?  finish,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StreamTextDelta() when textDelta != null:
return textDelta(_that.text);case StreamToolCallStart() when toolCallStart != null:
return toolCallStart(_that.id,_that.name);case StreamToolCallArgsDelta() when toolCallArgsDelta != null:
return toolCallArgsDelta(_that.id,_that.argsJsonFragment);case StreamToolCallEnd() when toolCallEnd != null:
return toolCallEnd(_that.id);case StreamFinish() when finish != null:
return finish(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  textDelta,required TResult Function( String id,  String name)  toolCallStart,required TResult Function( String id,  String argsJsonFragment)  toolCallArgsDelta,required TResult Function( String id)  toolCallEnd,required TResult Function( String reason)  finish,}) {final _that = this;
switch (_that) {
case StreamTextDelta():
return textDelta(_that.text);case StreamToolCallStart():
return toolCallStart(_that.id,_that.name);case StreamToolCallArgsDelta():
return toolCallArgsDelta(_that.id,_that.argsJsonFragment);case StreamToolCallEnd():
return toolCallEnd(_that.id);case StreamFinish():
return finish(_that.reason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  textDelta,TResult? Function( String id,  String name)?  toolCallStart,TResult? Function( String id,  String argsJsonFragment)?  toolCallArgsDelta,TResult? Function( String id)?  toolCallEnd,TResult? Function( String reason)?  finish,}) {final _that = this;
switch (_that) {
case StreamTextDelta() when textDelta != null:
return textDelta(_that.text);case StreamToolCallStart() when toolCallStart != null:
return toolCallStart(_that.id,_that.name);case StreamToolCallArgsDelta() when toolCallArgsDelta != null:
return toolCallArgsDelta(_that.id,_that.argsJsonFragment);case StreamToolCallEnd() when toolCallEnd != null:
return toolCallEnd(_that.id);case StreamFinish() when finish != null:
return finish(_that.reason);case _:
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

// dart format on
