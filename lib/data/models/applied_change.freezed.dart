// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'applied_change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AppliedChange {
  String get id => throw _privateConstructorUsedError; // uuid
  String get sessionId => throw _privateConstructorUsedError;
  String get messageId => throw _privateConstructorUsedError; // ChatMessage that contained the code block
  String get filePath => throw _privateConstructorUsedError; // absolute path on disk
  String? get originalContent => throw _privateConstructorUsedError; // null = file didn't exist before Apply
  String get newContent => throw _privateConstructorUsedError; // content that was written to disk
  DateTime get appliedAt =>
      throw _privateConstructorUsedError; // Line counts derived at apply-time from a char-level diff so the
// changes-panel indicator reflects real additions/deletions instead of
// a signed line delta. 0 when no diff was computed (e.g. legacy rows).
  int get additions => throw _privateConstructorUsedError;
  int get deletions => throw _privateConstructorUsedError;

  /// Create a copy of AppliedChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppliedChangeCopyWith<AppliedChange> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppliedChangeCopyWith<$Res> {
  factory $AppliedChangeCopyWith(AppliedChange value, $Res Function(AppliedChange) then) =
      _$AppliedChangeCopyWithImpl<$Res, AppliedChange>;
  @useResult
  $Res call(
      {String id,
      String sessionId,
      String messageId,
      String filePath,
      String? originalContent,
      String newContent,
      DateTime appliedAt,
      int additions,
      int deletions});
}

/// @nodoc
class _$AppliedChangeCopyWithImpl<$Res, $Val extends AppliedChange> implements $AppliedChangeCopyWith<$Res> {
  _$AppliedChangeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppliedChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? messageId = null,
    Object? filePath = null,
    Object? originalContent = freezed,
    Object? newContent = null,
    Object? appliedAt = null,
    Object? additions = null,
    Object? deletions = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      originalContent: freezed == originalContent
          ? _value.originalContent
          : originalContent // ignore: cast_nullable_to_non_nullable
              as String?,
      newContent: null == newContent
          ? _value.newContent
          : newContent // ignore: cast_nullable_to_non_nullable
              as String,
      appliedAt: null == appliedAt
          ? _value.appliedAt
          : appliedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      additions: null == additions
          ? _value.additions
          : additions // ignore: cast_nullable_to_non_nullable
              as int,
      deletions: null == deletions
          ? _value.deletions
          : deletions // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppliedChangeImplCopyWith<$Res> implements $AppliedChangeCopyWith<$Res> {
  factory _$$AppliedChangeImplCopyWith(_$AppliedChangeImpl value, $Res Function(_$AppliedChangeImpl) then) =
      __$$AppliedChangeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String sessionId,
      String messageId,
      String filePath,
      String? originalContent,
      String newContent,
      DateTime appliedAt,
      int additions,
      int deletions});
}

/// @nodoc
class __$$AppliedChangeImplCopyWithImpl<$Res> extends _$AppliedChangeCopyWithImpl<$Res, _$AppliedChangeImpl>
    implements _$$AppliedChangeImplCopyWith<$Res> {
  __$$AppliedChangeImplCopyWithImpl(_$AppliedChangeImpl _value, $Res Function(_$AppliedChangeImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppliedChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? messageId = null,
    Object? filePath = null,
    Object? originalContent = freezed,
    Object? newContent = null,
    Object? appliedAt = null,
    Object? additions = null,
    Object? deletions = null,
  }) {
    return _then(_$AppliedChangeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      originalContent: freezed == originalContent
          ? _value.originalContent
          : originalContent // ignore: cast_nullable_to_non_nullable
              as String?,
      newContent: null == newContent
          ? _value.newContent
          : newContent // ignore: cast_nullable_to_non_nullable
              as String,
      appliedAt: null == appliedAt
          ? _value.appliedAt
          : appliedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      additions: null == additions
          ? _value.additions
          : additions // ignore: cast_nullable_to_non_nullable
              as int,
      deletions: null == deletions
          ? _value.deletions
          : deletions // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$AppliedChangeImpl implements _AppliedChange {
  const _$AppliedChangeImpl(
      {required this.id,
      required this.sessionId,
      required this.messageId,
      required this.filePath,
      this.originalContent,
      required this.newContent,
      required this.appliedAt,
      this.additions = 0,
      this.deletions = 0});

  @override
  final String id;
// uuid
  @override
  final String sessionId;
  @override
  final String messageId;
// ChatMessage that contained the code block
  @override
  final String filePath;
// absolute path on disk
  @override
  final String? originalContent;
// null = file didn't exist before Apply
  @override
  final String newContent;
// content that was written to disk
  @override
  final DateTime appliedAt;
// Line counts derived at apply-time from a char-level diff so the
// changes-panel indicator reflects real additions/deletions instead of
// a signed line delta. 0 when no diff was computed (e.g. legacy rows).
  @override
  @JsonKey()
  final int additions;
  @override
  @JsonKey()
  final int deletions;

  @override
  String toString() {
    return 'AppliedChange(id: $id, sessionId: $sessionId, messageId: $messageId, filePath: $filePath, originalContent: $originalContent, newContent: $newContent, appliedAt: $appliedAt, additions: $additions, deletions: $deletions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppliedChangeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sessionId, sessionId) || other.sessionId == sessionId) &&
            (identical(other.messageId, messageId) || other.messageId == messageId) &&
            (identical(other.filePath, filePath) || other.filePath == filePath) &&
            (identical(other.originalContent, originalContent) || other.originalContent == originalContent) &&
            (identical(other.newContent, newContent) || other.newContent == newContent) &&
            (identical(other.appliedAt, appliedAt) || other.appliedAt == appliedAt) &&
            (identical(other.additions, additions) || other.additions == additions) &&
            (identical(other.deletions, deletions) || other.deletions == deletions));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, sessionId, messageId, filePath, originalContent, newContent, appliedAt, additions, deletions);

  /// Create a copy of AppliedChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppliedChangeImplCopyWith<_$AppliedChangeImpl> get copyWith =>
      __$$AppliedChangeImplCopyWithImpl<_$AppliedChangeImpl>(this, _$identity);
}

abstract class _AppliedChange implements AppliedChange {
  const factory _AppliedChange(
      {required final String id,
      required final String sessionId,
      required final String messageId,
      required final String filePath,
      final String? originalContent,
      required final String newContent,
      required final DateTime appliedAt,
      final int additions,
      final int deletions}) = _$AppliedChangeImpl;

  @override
  String get id; // uuid
  @override
  String get sessionId;
  @override
  String get messageId; // ChatMessage that contained the code block
  @override
  String get filePath; // absolute path on disk
  @override
  String? get originalContent; // null = file didn't exist before Apply
  @override
  String get newContent; // content that was written to disk
  @override
  DateTime get appliedAt; // Line counts derived at apply-time from a char-level diff so the
// changes-panel indicator reflects real additions/deletions instead of
// a signed line delta. 0 when no diff was computed (e.g. legacy rows).
  @override
  int get additions;
  @override
  int get deletions;

  /// Create a copy of AppliedChange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppliedChangeImplCopyWith<_$AppliedChangeImpl> get copyWith => throw _privateConstructorUsedError;
}
