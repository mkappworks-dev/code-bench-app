// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProjectAction _$ProjectActionFromJson(Map<String, dynamic> json) {
  return _ProjectAction.fromJson(json);
}

/// @nodoc
mixin _$ProjectAction {
  String get name => throw _privateConstructorUsedError;
  String get command => throw _privateConstructorUsedError;

  /// Serializes this ProjectAction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectActionCopyWith<ProjectAction> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectActionCopyWith<$Res> {
  factory $ProjectActionCopyWith(ProjectAction value, $Res Function(ProjectAction) then) =
      _$ProjectActionCopyWithImpl<$Res, ProjectAction>;
  @useResult
  $Res call({String name, String command});
}

/// @nodoc
class _$ProjectActionCopyWithImpl<$Res, $Val extends ProjectAction> implements $ProjectActionCopyWith<$Res> {
  _$ProjectActionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? command = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectActionImplCopyWith<$Res> implements $ProjectActionCopyWith<$Res> {
  factory _$$ProjectActionImplCopyWith(_$ProjectActionImpl value, $Res Function(_$ProjectActionImpl) then) =
      __$$ProjectActionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String command});
}

/// @nodoc
class __$$ProjectActionImplCopyWithImpl<$Res> extends _$ProjectActionCopyWithImpl<$Res, _$ProjectActionImpl>
    implements _$$ProjectActionImplCopyWith<$Res> {
  __$$ProjectActionImplCopyWithImpl(_$ProjectActionImpl _value, $Res Function(_$ProjectActionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? command = null,
  }) {
    return _then(_$ProjectActionImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectActionImpl implements _ProjectAction {
  const _$ProjectActionImpl({required this.name, required this.command});

  factory _$ProjectActionImpl.fromJson(Map<String, dynamic> json) => _$$ProjectActionImplFromJson(json);

  @override
  final String name;
  @override
  final String command;

  @override
  String toString() {
    return 'ProjectAction(name: $name, command: $command)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectActionImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.command, command) || other.command == command));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, command);

  /// Create a copy of ProjectAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectActionImplCopyWith<_$ProjectActionImpl> get copyWith =>
      __$$ProjectActionImplCopyWithImpl<_$ProjectActionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectActionImplToJson(
      this,
    );
  }
}

abstract class _ProjectAction implements ProjectAction {
  const factory _ProjectAction({required final String name, required final String command}) = _$ProjectActionImpl;

  factory _ProjectAction.fromJson(Map<String, dynamic> json) = _$ProjectActionImpl.fromJson;

  @override
  String get name;
  @override
  String get command;

  /// Create a copy of ProjectAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectActionImplCopyWith<_$ProjectActionImpl> get copyWith => throw _privateConstructorUsedError;
}
