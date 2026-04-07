// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WorkspaceProject _$WorkspaceProjectFromJson(Map<String, dynamic> json) {
  return _WorkspaceProject.fromJson(json);
}

/// @nodoc
mixin _$WorkspaceProject {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get localPath => throw _privateConstructorUsedError;
  String? get repositoryId => throw _privateConstructorUsedError;
  String? get activeBranch => throw _privateConstructorUsedError;
  List<String> get sessionIds => throw _privateConstructorUsedError;
  DateTime? get lastOpenedAt => throw _privateConstructorUsedError;

  /// Serializes this WorkspaceProject to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkspaceProject
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkspaceProjectCopyWith<WorkspaceProject> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkspaceProjectCopyWith<$Res> {
  factory $WorkspaceProjectCopyWith(
    WorkspaceProject value,
    $Res Function(WorkspaceProject) then,
  ) = _$WorkspaceProjectCopyWithImpl<$Res, WorkspaceProject>;
  @useResult
  $Res call({
    String id,
    String name,
    String? localPath,
    String? repositoryId,
    String? activeBranch,
    List<String> sessionIds,
    DateTime? lastOpenedAt,
  });
}

/// @nodoc
class _$WorkspaceProjectCopyWithImpl<$Res, $Val extends WorkspaceProject>
    implements $WorkspaceProjectCopyWith<$Res> {
  _$WorkspaceProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkspaceProject
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? localPath = freezed,
    Object? repositoryId = freezed,
    Object? activeBranch = freezed,
    Object? sessionIds = null,
    Object? lastOpenedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                as String,
        localPath: freezed == localPath
            ? _value.localPath
            : localPath // ignore: cast_nullable_to_non_nullable
                as String?,
        repositoryId: freezed == repositoryId
            ? _value.repositoryId
            : repositoryId // ignore: cast_nullable_to_non_nullable
                as String?,
        activeBranch: freezed == activeBranch
            ? _value.activeBranch
            : activeBranch // ignore: cast_nullable_to_non_nullable
                as String?,
        sessionIds: null == sessionIds
            ? _value.sessionIds
            : sessionIds // ignore: cast_nullable_to_non_nullable
                as List<String>,
        lastOpenedAt: freezed == lastOpenedAt
            ? _value.lastOpenedAt
            : lastOpenedAt // ignore: cast_nullable_to_non_nullable
                as DateTime?,
      ) as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkspaceProjectImplCopyWith<$Res>
    implements $WorkspaceProjectCopyWith<$Res> {
  factory _$$WorkspaceProjectImplCopyWith(
    _$WorkspaceProjectImpl value,
    $Res Function(_$WorkspaceProjectImpl) then,
  ) = __$$WorkspaceProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? localPath,
    String? repositoryId,
    String? activeBranch,
    List<String> sessionIds,
    DateTime? lastOpenedAt,
  });
}

/// @nodoc
class __$$WorkspaceProjectImplCopyWithImpl<$Res>
    extends _$WorkspaceProjectCopyWithImpl<$Res, _$WorkspaceProjectImpl>
    implements _$$WorkspaceProjectImplCopyWith<$Res> {
  __$$WorkspaceProjectImplCopyWithImpl(
    _$WorkspaceProjectImpl _value,
    $Res Function(_$WorkspaceProjectImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkspaceProject
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? localPath = freezed,
    Object? repositoryId = freezed,
    Object? activeBranch = freezed,
    Object? sessionIds = null,
    Object? lastOpenedAt = freezed,
  }) {
    return _then(
      _$WorkspaceProjectImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                as String,
        localPath: freezed == localPath
            ? _value.localPath
            : localPath // ignore: cast_nullable_to_non_nullable
                as String?,
        repositoryId: freezed == repositoryId
            ? _value.repositoryId
            : repositoryId // ignore: cast_nullable_to_non_nullable
                as String?,
        activeBranch: freezed == activeBranch
            ? _value.activeBranch
            : activeBranch // ignore: cast_nullable_to_non_nullable
                as String?,
        sessionIds: null == sessionIds
            ? _value._sessionIds
            : sessionIds // ignore: cast_nullable_to_non_nullable
                as List<String>,
        lastOpenedAt: freezed == lastOpenedAt
            ? _value.lastOpenedAt
            : lastOpenedAt // ignore: cast_nullable_to_non_nullable
                as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkspaceProjectImpl implements _WorkspaceProject {
  const _$WorkspaceProjectImpl({
    required this.id,
    required this.name,
    this.localPath,
    this.repositoryId,
    this.activeBranch,
    final List<String> sessionIds = const [],
    this.lastOpenedAt,
  }) : _sessionIds = sessionIds;

  factory _$WorkspaceProjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkspaceProjectImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? localPath;
  @override
  final String? repositoryId;
  @override
  final String? activeBranch;
  final List<String> _sessionIds;
  @override
  @JsonKey()
  List<String> get sessionIds {
    if (_sessionIds is EqualUnmodifiableListView) return _sessionIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sessionIds);
  }

  @override
  final DateTime? lastOpenedAt;

  @override
  String toString() {
    return 'WorkspaceProject(id: $id, name: $name, localPath: $localPath, repositoryId: $repositoryId, activeBranch: $activeBranch, sessionIds: $sessionIds, lastOpenedAt: $lastOpenedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkspaceProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath) &&
            (identical(other.repositoryId, repositoryId) ||
                other.repositoryId == repositoryId) &&
            (identical(other.activeBranch, activeBranch) ||
                other.activeBranch == activeBranch) &&
            const DeepCollectionEquality().equals(
              other._sessionIds,
              _sessionIds,
            ) &&
            (identical(other.lastOpenedAt, lastOpenedAt) ||
                other.lastOpenedAt == lastOpenedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
        runtimeType,
        id,
        name,
        localPath,
        repositoryId,
        activeBranch,
        const DeepCollectionEquality().hash(_sessionIds),
        lastOpenedAt,
      );

  /// Create a copy of WorkspaceProject
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkspaceProjectImplCopyWith<_$WorkspaceProjectImpl> get copyWith =>
      __$$WorkspaceProjectImplCopyWithImpl<_$WorkspaceProjectImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkspaceProjectImplToJson(this);
  }
}

abstract class _WorkspaceProject implements WorkspaceProject {
  const factory _WorkspaceProject({
    required final String id,
    required final String name,
    final String? localPath,
    final String? repositoryId,
    final String? activeBranch,
    final List<String> sessionIds,
    final DateTime? lastOpenedAt,
  }) = _$WorkspaceProjectImpl;

  factory _WorkspaceProject.fromJson(Map<String, dynamic> json) =
      _$WorkspaceProjectImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get localPath;
  @override
  String? get repositoryId;
  @override
  String? get activeBranch;
  @override
  List<String> get sessionIds;
  @override
  DateTime? get lastOpenedAt;

  /// Create a copy of WorkspaceProject
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkspaceProjectImplCopyWith<_$WorkspaceProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
