// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'action_runner_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ActionOutputState {
  ActionStatus get status => throw _privateConstructorUsedError;
  List<String> get lines => throw _privateConstructorUsedError;
  String? get actionName => throw _privateConstructorUsedError;
  int? get exitCode => throw _privateConstructorUsedError;

  /// Create a copy of ActionOutputState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActionOutputStateCopyWith<ActionOutputState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActionOutputStateCopyWith<$Res> {
  factory $ActionOutputStateCopyWith(
          ActionOutputState value, $Res Function(ActionOutputState) then) =
      _$ActionOutputStateCopyWithImpl<$Res, ActionOutputState>;
  @useResult
  $Res call(
      {ActionStatus status,
      List<String> lines,
      String? actionName,
      int? exitCode});
}

/// @nodoc
class _$ActionOutputStateCopyWithImpl<$Res, $Val extends ActionOutputState>
    implements $ActionOutputStateCopyWith<$Res> {
  _$ActionOutputStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActionOutputState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? lines = null,
    Object? actionName = freezed,
    Object? exitCode = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ActionStatus,
      lines: null == lines
          ? _value.lines
          : lines // ignore: cast_nullable_to_non_nullable
              as List<String>,
      actionName: freezed == actionName
          ? _value.actionName
          : actionName // ignore: cast_nullable_to_non_nullable
              as String?,
      exitCode: freezed == exitCode
          ? _value.exitCode
          : exitCode // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActionOutputStateImplCopyWith<$Res>
    implements $ActionOutputStateCopyWith<$Res> {
  factory _$$ActionOutputStateImplCopyWith(_$ActionOutputStateImpl value,
          $Res Function(_$ActionOutputStateImpl) then) =
      __$$ActionOutputStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ActionStatus status,
      List<String> lines,
      String? actionName,
      int? exitCode});
}

/// @nodoc
class __$$ActionOutputStateImplCopyWithImpl<$Res>
    extends _$ActionOutputStateCopyWithImpl<$Res, _$ActionOutputStateImpl>
    implements _$$ActionOutputStateImplCopyWith<$Res> {
  __$$ActionOutputStateImplCopyWithImpl(_$ActionOutputStateImpl _value,
      $Res Function(_$ActionOutputStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ActionOutputState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? lines = null,
    Object? actionName = freezed,
    Object? exitCode = freezed,
  }) {
    return _then(_$ActionOutputStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ActionStatus,
      lines: null == lines
          ? _value._lines
          : lines // ignore: cast_nullable_to_non_nullable
              as List<String>,
      actionName: freezed == actionName
          ? _value.actionName
          : actionName // ignore: cast_nullable_to_non_nullable
              as String?,
      exitCode: freezed == exitCode
          ? _value.exitCode
          : exitCode // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$ActionOutputStateImpl implements _ActionOutputState {
  const _$ActionOutputStateImpl(
      {this.status = ActionStatus.idle,
      final List<String> lines = const [],
      this.actionName,
      this.exitCode})
      : _lines = lines;

  @override
  @JsonKey()
  final ActionStatus status;
  final List<String> _lines;
  @override
  @JsonKey()
  List<String> get lines {
    if (_lines is EqualUnmodifiableListView) return _lines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lines);
  }

  @override
  final String? actionName;
  @override
  final int? exitCode;

  @override
  String toString() {
    return 'ActionOutputState(status: $status, lines: $lines, actionName: $actionName, exitCode: $exitCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActionOutputStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._lines, _lines) &&
            (identical(other.actionName, actionName) ||
                other.actionName == actionName) &&
            (identical(other.exitCode, exitCode) ||
                other.exitCode == exitCode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status,
      const DeepCollectionEquality().hash(_lines), actionName, exitCode);

  /// Create a copy of ActionOutputState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActionOutputStateImplCopyWith<_$ActionOutputStateImpl> get copyWith =>
      __$$ActionOutputStateImplCopyWithImpl<_$ActionOutputStateImpl>(
          this, _$identity);
}

abstract class _ActionOutputState implements ActionOutputState {
  const factory _ActionOutputState(
      {final ActionStatus status,
      final List<String> lines,
      final String? actionName,
      final int? exitCode}) = _$ActionOutputStateImpl;

  @override
  ActionStatus get status;
  @override
  List<String> get lines;
  @override
  String? get actionName;
  @override
  int? get exitCode;

  /// Create a copy of ActionOutputState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActionOutputStateImplCopyWith<_$ActionOutputStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
