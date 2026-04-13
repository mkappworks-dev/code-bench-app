// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CodeBlock {

 String get code; String? get language; String? get filename;
/// Create a copy of CodeBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CodeBlockCopyWith<CodeBlock> get copyWith => _$CodeBlockCopyWithImpl<CodeBlock>(this as CodeBlock, _$identity);

  /// Serializes this CodeBlock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodeBlock&&(identical(other.code, code) || other.code == code)&&(identical(other.language, language) || other.language == language)&&(identical(other.filename, filename) || other.filename == filename));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,language,filename);

@override
String toString() {
  return 'CodeBlock(code: $code, language: $language, filename: $filename)';
}


}

/// @nodoc
abstract mixin class $CodeBlockCopyWith<$Res>  {
  factory $CodeBlockCopyWith(CodeBlock value, $Res Function(CodeBlock) _then) = _$CodeBlockCopyWithImpl;
@useResult
$Res call({
 String code, String? language, String? filename
});




}
/// @nodoc
class _$CodeBlockCopyWithImpl<$Res>
    implements $CodeBlockCopyWith<$Res> {
  _$CodeBlockCopyWithImpl(this._self, this._then);

  final CodeBlock _self;
  final $Res Function(CodeBlock) _then;

/// Create a copy of CodeBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? language = freezed,Object? filename = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,filename: freezed == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CodeBlock].
extension CodeBlockPatterns on CodeBlock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CodeBlock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CodeBlock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CodeBlock value)  $default,){
final _that = this;
switch (_that) {
case _CodeBlock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CodeBlock value)?  $default,){
final _that = this;
switch (_that) {
case _CodeBlock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String? language,  String? filename)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CodeBlock() when $default != null:
return $default(_that.code,_that.language,_that.filename);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String? language,  String? filename)  $default,) {final _that = this;
switch (_that) {
case _CodeBlock():
return $default(_that.code,_that.language,_that.filename);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String? language,  String? filename)?  $default,) {final _that = this;
switch (_that) {
case _CodeBlock() when $default != null:
return $default(_that.code,_that.language,_that.filename);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CodeBlock implements CodeBlock {
  const _CodeBlock({required this.code, this.language, this.filename});
  factory _CodeBlock.fromJson(Map<String, dynamic> json) => _$CodeBlockFromJson(json);

@override final  String code;
@override final  String? language;
@override final  String? filename;

/// Create a copy of CodeBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CodeBlockCopyWith<_CodeBlock> get copyWith => __$CodeBlockCopyWithImpl<_CodeBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CodeBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CodeBlock&&(identical(other.code, code) || other.code == code)&&(identical(other.language, language) || other.language == language)&&(identical(other.filename, filename) || other.filename == filename));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,language,filename);

@override
String toString() {
  return 'CodeBlock(code: $code, language: $language, filename: $filename)';
}


}

/// @nodoc
abstract mixin class _$CodeBlockCopyWith<$Res> implements $CodeBlockCopyWith<$Res> {
  factory _$CodeBlockCopyWith(_CodeBlock value, $Res Function(_CodeBlock) _then) = __$CodeBlockCopyWithImpl;
@override @useResult
$Res call({
 String code, String? language, String? filename
});




}
/// @nodoc
class __$CodeBlockCopyWithImpl<$Res>
    implements _$CodeBlockCopyWith<$Res> {
  __$CodeBlockCopyWithImpl(this._self, this._then);

  final _CodeBlock _self;
  final $Res Function(_CodeBlock) _then;

/// Create a copy of CodeBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? language = freezed,Object? filename = freezed,}) {
  return _then(_CodeBlock(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,filename: freezed == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ChatMessage {

 String get id; String get sessionId; MessageRole get role; String get content; List<CodeBlock> get codeBlocks; List<ToolEvent> get toolEvents; DateTime get timestamp; bool get isStreaming; AskUserQuestion? get askQuestion;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other.codeBlocks, codeBlocks)&&const DeepCollectionEquality().equals(other.toolEvents, toolEvents)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.isStreaming, isStreaming) || other.isStreaming == isStreaming)&&(identical(other.askQuestion, askQuestion) || other.askQuestion == askQuestion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,role,content,const DeepCollectionEquality().hash(codeBlocks),const DeepCollectionEquality().hash(toolEvents),timestamp,isStreaming,askQuestion);

@override
String toString() {
  return 'ChatMessage(id: $id, sessionId: $sessionId, role: $role, content: $content, codeBlocks: $codeBlocks, toolEvents: $toolEvents, timestamp: $timestamp, isStreaming: $isStreaming, askQuestion: $askQuestion)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, MessageRole role, String content, List<CodeBlock> codeBlocks, List<ToolEvent> toolEvents, DateTime timestamp, bool isStreaming, AskUserQuestion? askQuestion
});


$AskUserQuestionCopyWith<$Res>? get askQuestion;

}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? role = null,Object? content = null,Object? codeBlocks = null,Object? toolEvents = null,Object? timestamp = null,Object? isStreaming = null,Object? askQuestion = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MessageRole,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,codeBlocks: null == codeBlocks ? _self.codeBlocks : codeBlocks // ignore: cast_nullable_to_non_nullable
as List<CodeBlock>,toolEvents: null == toolEvents ? _self.toolEvents : toolEvents // ignore: cast_nullable_to_non_nullable
as List<ToolEvent>,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,isStreaming: null == isStreaming ? _self.isStreaming : isStreaming // ignore: cast_nullable_to_non_nullable
as bool,askQuestion: freezed == askQuestion ? _self.askQuestion : askQuestion // ignore: cast_nullable_to_non_nullable
as AskUserQuestion?,
  ));
}
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AskUserQuestionCopyWith<$Res>? get askQuestion {
    if (_self.askQuestion == null) {
    return null;
  }

  return $AskUserQuestionCopyWith<$Res>(_self.askQuestion!, (value) {
    return _then(_self.copyWith(askQuestion: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  MessageRole role,  String content,  List<CodeBlock> codeBlocks,  List<ToolEvent> toolEvents,  DateTime timestamp,  bool isStreaming,  AskUserQuestion? askQuestion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.sessionId,_that.role,_that.content,_that.codeBlocks,_that.toolEvents,_that.timestamp,_that.isStreaming,_that.askQuestion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  MessageRole role,  String content,  List<CodeBlock> codeBlocks,  List<ToolEvent> toolEvents,  DateTime timestamp,  bool isStreaming,  AskUserQuestion? askQuestion)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.sessionId,_that.role,_that.content,_that.codeBlocks,_that.toolEvents,_that.timestamp,_that.isStreaming,_that.askQuestion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  MessageRole role,  String content,  List<CodeBlock> codeBlocks,  List<ToolEvent> toolEvents,  DateTime timestamp,  bool isStreaming,  AskUserQuestion? askQuestion)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.sessionId,_that.role,_that.content,_that.codeBlocks,_that.toolEvents,_that.timestamp,_that.isStreaming,_that.askQuestion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.id, required this.sessionId, required this.role, required this.content, final  List<CodeBlock> codeBlocks = const [], final  List<ToolEvent> toolEvents = const [], required this.timestamp, this.isStreaming = false, this.askQuestion}): _codeBlocks = codeBlocks,_toolEvents = toolEvents;
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override final  String id;
@override final  String sessionId;
@override final  MessageRole role;
@override final  String content;
 final  List<CodeBlock> _codeBlocks;
@override@JsonKey() List<CodeBlock> get codeBlocks {
  if (_codeBlocks is EqualUnmodifiableListView) return _codeBlocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_codeBlocks);
}

 final  List<ToolEvent> _toolEvents;
@override@JsonKey() List<ToolEvent> get toolEvents {
  if (_toolEvents is EqualUnmodifiableListView) return _toolEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_toolEvents);
}

@override final  DateTime timestamp;
@override@JsonKey() final  bool isStreaming;
@override final  AskUserQuestion? askQuestion;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other._codeBlocks, _codeBlocks)&&const DeepCollectionEquality().equals(other._toolEvents, _toolEvents)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.isStreaming, isStreaming) || other.isStreaming == isStreaming)&&(identical(other.askQuestion, askQuestion) || other.askQuestion == askQuestion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,role,content,const DeepCollectionEquality().hash(_codeBlocks),const DeepCollectionEquality().hash(_toolEvents),timestamp,isStreaming,askQuestion);

@override
String toString() {
  return 'ChatMessage(id: $id, sessionId: $sessionId, role: $role, content: $content, codeBlocks: $codeBlocks, toolEvents: $toolEvents, timestamp: $timestamp, isStreaming: $isStreaming, askQuestion: $askQuestion)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, MessageRole role, String content, List<CodeBlock> codeBlocks, List<ToolEvent> toolEvents, DateTime timestamp, bool isStreaming, AskUserQuestion? askQuestion
});


@override $AskUserQuestionCopyWith<$Res>? get askQuestion;

}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? role = null,Object? content = null,Object? codeBlocks = null,Object? toolEvents = null,Object? timestamp = null,Object? isStreaming = null,Object? askQuestion = freezed,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MessageRole,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,codeBlocks: null == codeBlocks ? _self._codeBlocks : codeBlocks // ignore: cast_nullable_to_non_nullable
as List<CodeBlock>,toolEvents: null == toolEvents ? _self._toolEvents : toolEvents // ignore: cast_nullable_to_non_nullable
as List<ToolEvent>,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,isStreaming: null == isStreaming ? _self.isStreaming : isStreaming // ignore: cast_nullable_to_non_nullable
as bool,askQuestion: freezed == askQuestion ? _self.askQuestion : askQuestion // ignore: cast_nullable_to_non_nullable
as AskUserQuestion?,
  ));
}

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AskUserQuestionCopyWith<$Res>? get askQuestion {
    if (_self.askQuestion == null) {
    return null;
  }

  return $AskUserQuestionCopyWith<$Res>(_self.askQuestion!, (value) {
    return _then(_self.copyWith(askQuestion: value));
  });
}
}

// dart format on
