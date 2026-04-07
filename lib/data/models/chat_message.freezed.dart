// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CodeBlock _$CodeBlockFromJson(Map<String, dynamic> json) {
  return _CodeBlock.fromJson(json);
}

/// @nodoc
mixin _$CodeBlock {
  String get code => throw _privateConstructorUsedError;
  String? get language => throw _privateConstructorUsedError;
  String? get filename => throw _privateConstructorUsedError;

  /// Serializes this CodeBlock to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CodeBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CodeBlockCopyWith<CodeBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CodeBlockCopyWith<$Res> {
  factory $CodeBlockCopyWith(CodeBlock value, $Res Function(CodeBlock) then) =
      _$CodeBlockCopyWithImpl<$Res, CodeBlock>;
  @useResult
  $Res call({String code, String? language, String? filename});
}

/// @nodoc
class _$CodeBlockCopyWithImpl<$Res, $Val extends CodeBlock>
    implements $CodeBlockCopyWith<$Res> {
  _$CodeBlockCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CodeBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? language = freezed,
    Object? filename = freezed,
  }) {
    return _then(
      _value.copyWith(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                as String,
        language: freezed == language
            ? _value.language
            : language // ignore: cast_nullable_to_non_nullable
                as String?,
        filename: freezed == filename
            ? _value.filename
            : filename // ignore: cast_nullable_to_non_nullable
                as String?,
      ) as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CodeBlockImplCopyWith<$Res>
    implements $CodeBlockCopyWith<$Res> {
  factory _$$CodeBlockImplCopyWith(
    _$CodeBlockImpl value,
    $Res Function(_$CodeBlockImpl) then,
  ) = __$$CodeBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String code, String? language, String? filename});
}

/// @nodoc
class __$$CodeBlockImplCopyWithImpl<$Res>
    extends _$CodeBlockCopyWithImpl<$Res, _$CodeBlockImpl>
    implements _$$CodeBlockImplCopyWith<$Res> {
  __$$CodeBlockImplCopyWithImpl(
    _$CodeBlockImpl _value,
    $Res Function(_$CodeBlockImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CodeBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? language = freezed,
    Object? filename = freezed,
  }) {
    return _then(
      _$CodeBlockImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                as String,
        language: freezed == language
            ? _value.language
            : language // ignore: cast_nullable_to_non_nullable
                as String?,
        filename: freezed == filename
            ? _value.filename
            : filename // ignore: cast_nullable_to_non_nullable
                as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CodeBlockImpl implements _CodeBlock {
  const _$CodeBlockImpl({required this.code, this.language, this.filename});

  factory _$CodeBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$CodeBlockImplFromJson(json);

  @override
  final String code;
  @override
  final String? language;
  @override
  final String? filename;

  @override
  String toString() {
    return 'CodeBlock(code: $code, language: $language, filename: $filename)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CodeBlockImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.filename, filename) ||
                other.filename == filename));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, language, filename);

  /// Create a copy of CodeBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CodeBlockImplCopyWith<_$CodeBlockImpl> get copyWith =>
      __$$CodeBlockImplCopyWithImpl<_$CodeBlockImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CodeBlockImplToJson(this);
  }
}

abstract class _CodeBlock implements CodeBlock {
  const factory _CodeBlock({
    required final String code,
    final String? language,
    final String? filename,
  }) = _$CodeBlockImpl;

  factory _CodeBlock.fromJson(Map<String, dynamic> json) =
      _$CodeBlockImpl.fromJson;

  @override
  String get code;
  @override
  String? get language;
  @override
  String? get filename;

  /// Create a copy of CodeBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CodeBlockImplCopyWith<_$CodeBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  String get id => throw _privateConstructorUsedError;
  String get sessionId => throw _privateConstructorUsedError;
  MessageRole get role => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  List<CodeBlock> get codeBlocks => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  bool get isStreaming => throw _privateConstructorUsedError;

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
    ChatMessage value,
    $Res Function(ChatMessage) then,
  ) = _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call({
    String id,
    String sessionId,
    MessageRole role,
    String content,
    List<CodeBlock> codeBlocks,
    DateTime timestamp,
    bool isStreaming,
  });
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? role = null,
    Object? content = null,
    Object? codeBlocks = null,
    Object? timestamp = null,
    Object? isStreaming = null,
  }) {
    return _then(
      _value.copyWith(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                as String,
        sessionId: null == sessionId
            ? _value.sessionId
            : sessionId // ignore: cast_nullable_to_non_nullable
                as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                as MessageRole,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                as String,
        codeBlocks: null == codeBlocks
            ? _value.codeBlocks
            : codeBlocks // ignore: cast_nullable_to_non_nullable
                as List<CodeBlock>,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                as DateTime,
        isStreaming: null == isStreaming
            ? _value.isStreaming
            : isStreaming // ignore: cast_nullable_to_non_nullable
                as bool,
      ) as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
    _$ChatMessageImpl value,
    $Res Function(_$ChatMessageImpl) then,
  ) = __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String sessionId,
    MessageRole role,
    String content,
    List<CodeBlock> codeBlocks,
    DateTime timestamp,
    bool isStreaming,
  });
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
    _$ChatMessageImpl _value,
    $Res Function(_$ChatMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? role = null,
    Object? content = null,
    Object? codeBlocks = null,
    Object? timestamp = null,
    Object? isStreaming = null,
  }) {
    return _then(
      _$ChatMessageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                as String,
        sessionId: null == sessionId
            ? _value.sessionId
            : sessionId // ignore: cast_nullable_to_non_nullable
                as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                as MessageRole,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                as String,
        codeBlocks: null == codeBlocks
            ? _value._codeBlocks
            : codeBlocks // ignore: cast_nullable_to_non_nullable
                as List<CodeBlock>,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                as DateTime,
        isStreaming: null == isStreaming
            ? _value.isStreaming
            : isStreaming // ignore: cast_nullable_to_non_nullable
                as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageImpl implements _ChatMessage {
  const _$ChatMessageImpl({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    final List<CodeBlock> codeBlocks = const [],
    required this.timestamp,
    this.isStreaming = false,
  }) : _codeBlocks = codeBlocks;

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

  @override
  final String id;
  @override
  final String sessionId;
  @override
  final MessageRole role;
  @override
  final String content;
  final List<CodeBlock> _codeBlocks;
  @override
  @JsonKey()
  List<CodeBlock> get codeBlocks {
    if (_codeBlocks is EqualUnmodifiableListView) return _codeBlocks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_codeBlocks);
  }

  @override
  final DateTime timestamp;
  @override
  @JsonKey()
  final bool isStreaming;

  @override
  String toString() {
    return 'ChatMessage(id: $id, sessionId: $sessionId, role: $role, content: $content, codeBlocks: $codeBlocks, timestamp: $timestamp, isStreaming: $isStreaming)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(
              other._codeBlocks,
              _codeBlocks,
            ) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.isStreaming, isStreaming) ||
                other.isStreaming == isStreaming));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
        runtimeType,
        id,
        sessionId,
        role,
        content,
        const DeepCollectionEquality().hash(_codeBlocks),
        timestamp,
        isStreaming,
      );

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(this);
  }
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage({
    required final String id,
    required final String sessionId,
    required final MessageRole role,
    required final String content,
    final List<CodeBlock> codeBlocks,
    required final DateTime timestamp,
    final bool isStreaming,
  }) = _$ChatMessageImpl;

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get sessionId;
  @override
  MessageRole get role;
  @override
  String get content;
  @override
  List<CodeBlock> get codeBlocks;
  @override
  DateTime get timestamp;
  @override
  bool get isStreaming;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
