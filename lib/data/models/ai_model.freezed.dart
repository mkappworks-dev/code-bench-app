// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AIModel _$AIModelFromJson(Map<String, dynamic> json) {
  return _AIModel.fromJson(json);
}

/// @nodoc
mixin _$AIModel {
  String get id => throw _privateConstructorUsedError;
  AIProvider get provider => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get modelId => throw _privateConstructorUsedError;
  String? get endpoint => throw _privateConstructorUsedError;
  int get contextWindow => throw _privateConstructorUsedError;
  bool get supportsStreaming => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;

  /// Serializes this AIModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AIModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AIModelCopyWith<AIModel> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AIModelCopyWith<$Res> {
  factory $AIModelCopyWith(AIModel value, $Res Function(AIModel) then) =
      _$AIModelCopyWithImpl<$Res, AIModel>;
  @useResult
  $Res call({
    String id,
    AIProvider provider,
    String name,
    String modelId,
    String? endpoint,
    int contextWindow,
    bool supportsStreaming,
    bool isDefault,
  });
}

/// @nodoc
class _$AIModelCopyWithImpl<$Res, $Val extends AIModel>
    implements $AIModelCopyWith<$Res> {
  _$AIModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AIModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? provider = null,
    Object? name = null,
    Object? modelId = null,
    Object? endpoint = freezed,
    Object? contextWindow = null,
    Object? supportsStreaming = null,
    Object? isDefault = null,
  }) {
    return _then(
      _value.copyWith(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                as String,
        provider: null == provider
            ? _value.provider
            : provider // ignore: cast_nullable_to_non_nullable
                as AIProvider,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                as String,
        modelId: null == modelId
            ? _value.modelId
            : modelId // ignore: cast_nullable_to_non_nullable
                as String,
        endpoint: freezed == endpoint
            ? _value.endpoint
            : endpoint // ignore: cast_nullable_to_non_nullable
                as String?,
        contextWindow: null == contextWindow
            ? _value.contextWindow
            : contextWindow // ignore: cast_nullable_to_non_nullable
                as int,
        supportsStreaming: null == supportsStreaming
            ? _value.supportsStreaming
            : supportsStreaming // ignore: cast_nullable_to_non_nullable
                as bool,
        isDefault: null == isDefault
            ? _value.isDefault
            : isDefault // ignore: cast_nullable_to_non_nullable
                as bool,
      ) as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AIModelImplCopyWith<$Res> implements $AIModelCopyWith<$Res> {
  factory _$$AIModelImplCopyWith(
    _$AIModelImpl value,
    $Res Function(_$AIModelImpl) then,
  ) = __$$AIModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    AIProvider provider,
    String name,
    String modelId,
    String? endpoint,
    int contextWindow,
    bool supportsStreaming,
    bool isDefault,
  });
}

/// @nodoc
class __$$AIModelImplCopyWithImpl<$Res>
    extends _$AIModelCopyWithImpl<$Res, _$AIModelImpl>
    implements _$$AIModelImplCopyWith<$Res> {
  __$$AIModelImplCopyWithImpl(
    _$AIModelImpl _value,
    $Res Function(_$AIModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AIModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? provider = null,
    Object? name = null,
    Object? modelId = null,
    Object? endpoint = freezed,
    Object? contextWindow = null,
    Object? supportsStreaming = null,
    Object? isDefault = null,
  }) {
    return _then(
      _$AIModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                as String,
        provider: null == provider
            ? _value.provider
            : provider // ignore: cast_nullable_to_non_nullable
                as AIProvider,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                as String,
        modelId: null == modelId
            ? _value.modelId
            : modelId // ignore: cast_nullable_to_non_nullable
                as String,
        endpoint: freezed == endpoint
            ? _value.endpoint
            : endpoint // ignore: cast_nullable_to_non_nullable
                as String?,
        contextWindow: null == contextWindow
            ? _value.contextWindow
            : contextWindow // ignore: cast_nullable_to_non_nullable
                as int,
        supportsStreaming: null == supportsStreaming
            ? _value.supportsStreaming
            : supportsStreaming // ignore: cast_nullable_to_non_nullable
                as bool,
        isDefault: null == isDefault
            ? _value.isDefault
            : isDefault // ignore: cast_nullable_to_non_nullable
                as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AIModelImpl implements _AIModel {
  const _$AIModelImpl({
    required this.id,
    required this.provider,
    required this.name,
    required this.modelId,
    this.endpoint,
    this.contextWindow = 128000,
    this.supportsStreaming = true,
    this.isDefault = false,
  });

  factory _$AIModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AIModelImplFromJson(json);

  @override
  final String id;
  @override
  final AIProvider provider;
  @override
  final String name;
  @override
  final String modelId;
  @override
  final String? endpoint;
  @override
  @JsonKey()
  final int contextWindow;
  @override
  @JsonKey()
  final bool supportsStreaming;
  @override
  @JsonKey()
  final bool isDefault;

  @override
  String toString() {
    return 'AIModel(id: $id, provider: $provider, name: $name, modelId: $modelId, endpoint: $endpoint, contextWindow: $contextWindow, supportsStreaming: $supportsStreaming, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AIModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.modelId, modelId) || other.modelId == modelId) &&
            (identical(other.endpoint, endpoint) ||
                other.endpoint == endpoint) &&
            (identical(other.contextWindow, contextWindow) ||
                other.contextWindow == contextWindow) &&
            (identical(other.supportsStreaming, supportsStreaming) ||
                other.supportsStreaming == supportsStreaming) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
        runtimeType,
        id,
        provider,
        name,
        modelId,
        endpoint,
        contextWindow,
        supportsStreaming,
        isDefault,
      );

  /// Create a copy of AIModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AIModelImplCopyWith<_$AIModelImpl> get copyWith =>
      __$$AIModelImplCopyWithImpl<_$AIModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AIModelImplToJson(this);
  }
}

abstract class _AIModel implements AIModel {
  const factory _AIModel({
    required final String id,
    required final AIProvider provider,
    required final String name,
    required final String modelId,
    final String? endpoint,
    final int contextWindow,
    final bool supportsStreaming,
    final bool isDefault,
  }) = _$AIModelImpl;

  factory _AIModel.fromJson(Map<String, dynamic> json) = _$AIModelImpl.fromJson;

  @override
  String get id;
  @override
  AIProvider get provider;
  @override
  String get name;
  @override
  String get modelId;
  @override
  String? get endpoint;
  @override
  int get contextWindow;
  @override
  bool get supportsStreaming;
  @override
  bool get isDefault;

  /// Create a copy of AIModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AIModelImplCopyWith<_$AIModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
