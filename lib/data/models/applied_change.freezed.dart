// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'applied_change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppliedChange {

 String get id;// uuid
 String get sessionId; String get messageId;// ChatMessage that contained the code block
 String get filePath;// absolute path on disk
 String? get originalContent;// null = file didn't exist before Apply
 String get newContent;// content that was written to disk
 DateTime get appliedAt;// Line counts derived at apply-time from a char-level diff so the
// changes-panel indicator reflects real additions/deletions instead of
// a signed line delta. 0 when no diff was computed (e.g. legacy rows).
 int get additions; int get deletions;
/// Create a copy of AppliedChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppliedChangeCopyWith<AppliedChange> get copyWith => _$AppliedChangeCopyWithImpl<AppliedChange>(this as AppliedChange, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppliedChange&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.originalContent, originalContent) || other.originalContent == originalContent)&&(identical(other.newContent, newContent) || other.newContent == newContent)&&(identical(other.appliedAt, appliedAt) || other.appliedAt == appliedAt)&&(identical(other.additions, additions) || other.additions == additions)&&(identical(other.deletions, deletions) || other.deletions == deletions));
}


@override
int get hashCode => Object.hash(runtimeType,id,sessionId,messageId,filePath,originalContent,newContent,appliedAt,additions,deletions);

@override
String toString() {
  return 'AppliedChange(id: $id, sessionId: $sessionId, messageId: $messageId, filePath: $filePath, originalContent: $originalContent, newContent: $newContent, appliedAt: $appliedAt, additions: $additions, deletions: $deletions)';
}


}

/// @nodoc
abstract mixin class $AppliedChangeCopyWith<$Res>  {
  factory $AppliedChangeCopyWith(AppliedChange value, $Res Function(AppliedChange) _then) = _$AppliedChangeCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, String messageId, String filePath, String? originalContent, String newContent, DateTime appliedAt, int additions, int deletions
});




}
/// @nodoc
class _$AppliedChangeCopyWithImpl<$Res>
    implements $AppliedChangeCopyWith<$Res> {
  _$AppliedChangeCopyWithImpl(this._self, this._then);

  final AppliedChange _self;
  final $Res Function(AppliedChange) _then;

/// Create a copy of AppliedChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? messageId = null,Object? filePath = null,Object? originalContent = freezed,Object? newContent = null,Object? appliedAt = null,Object? additions = null,Object? deletions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,originalContent: freezed == originalContent ? _self.originalContent : originalContent // ignore: cast_nullable_to_non_nullable
as String?,newContent: null == newContent ? _self.newContent : newContent // ignore: cast_nullable_to_non_nullable
as String,appliedAt: null == appliedAt ? _self.appliedAt : appliedAt // ignore: cast_nullable_to_non_nullable
as DateTime,additions: null == additions ? _self.additions : additions // ignore: cast_nullable_to_non_nullable
as int,deletions: null == deletions ? _self.deletions : deletions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AppliedChange].
extension AppliedChangePatterns on AppliedChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppliedChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppliedChange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppliedChange value)  $default,){
final _that = this;
switch (_that) {
case _AppliedChange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppliedChange value)?  $default,){
final _that = this;
switch (_that) {
case _AppliedChange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  String messageId,  String filePath,  String? originalContent,  String newContent,  DateTime appliedAt,  int additions,  int deletions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppliedChange() when $default != null:
return $default(_that.id,_that.sessionId,_that.messageId,_that.filePath,_that.originalContent,_that.newContent,_that.appliedAt,_that.additions,_that.deletions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  String messageId,  String filePath,  String? originalContent,  String newContent,  DateTime appliedAt,  int additions,  int deletions)  $default,) {final _that = this;
switch (_that) {
case _AppliedChange():
return $default(_that.id,_that.sessionId,_that.messageId,_that.filePath,_that.originalContent,_that.newContent,_that.appliedAt,_that.additions,_that.deletions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  String messageId,  String filePath,  String? originalContent,  String newContent,  DateTime appliedAt,  int additions,  int deletions)?  $default,) {final _that = this;
switch (_that) {
case _AppliedChange() when $default != null:
return $default(_that.id,_that.sessionId,_that.messageId,_that.filePath,_that.originalContent,_that.newContent,_that.appliedAt,_that.additions,_that.deletions);case _:
  return null;

}
}

}

/// @nodoc


class _AppliedChange implements AppliedChange {
  const _AppliedChange({required this.id, required this.sessionId, required this.messageId, required this.filePath, this.originalContent, required this.newContent, required this.appliedAt, this.additions = 0, this.deletions = 0});
  

@override final  String id;
// uuid
@override final  String sessionId;
@override final  String messageId;
// ChatMessage that contained the code block
@override final  String filePath;
// absolute path on disk
@override final  String? originalContent;
// null = file didn't exist before Apply
@override final  String newContent;
// content that was written to disk
@override final  DateTime appliedAt;
// Line counts derived at apply-time from a char-level diff so the
// changes-panel indicator reflects real additions/deletions instead of
// a signed line delta. 0 when no diff was computed (e.g. legacy rows).
@override@JsonKey() final  int additions;
@override@JsonKey() final  int deletions;

/// Create a copy of AppliedChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppliedChangeCopyWith<_AppliedChange> get copyWith => __$AppliedChangeCopyWithImpl<_AppliedChange>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppliedChange&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.originalContent, originalContent) || other.originalContent == originalContent)&&(identical(other.newContent, newContent) || other.newContent == newContent)&&(identical(other.appliedAt, appliedAt) || other.appliedAt == appliedAt)&&(identical(other.additions, additions) || other.additions == additions)&&(identical(other.deletions, deletions) || other.deletions == deletions));
}


@override
int get hashCode => Object.hash(runtimeType,id,sessionId,messageId,filePath,originalContent,newContent,appliedAt,additions,deletions);

@override
String toString() {
  return 'AppliedChange(id: $id, sessionId: $sessionId, messageId: $messageId, filePath: $filePath, originalContent: $originalContent, newContent: $newContent, appliedAt: $appliedAt, additions: $additions, deletions: $deletions)';
}


}

/// @nodoc
abstract mixin class _$AppliedChangeCopyWith<$Res> implements $AppliedChangeCopyWith<$Res> {
  factory _$AppliedChangeCopyWith(_AppliedChange value, $Res Function(_AppliedChange) _then) = __$AppliedChangeCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, String messageId, String filePath, String? originalContent, String newContent, DateTime appliedAt, int additions, int deletions
});




}
/// @nodoc
class __$AppliedChangeCopyWithImpl<$Res>
    implements _$AppliedChangeCopyWith<$Res> {
  __$AppliedChangeCopyWithImpl(this._self, this._then);

  final _AppliedChange _self;
  final $Res Function(_AppliedChange) _then;

/// Create a copy of AppliedChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? messageId = null,Object? filePath = null,Object? originalContent = freezed,Object? newContent = null,Object? appliedAt = null,Object? additions = null,Object? deletions = null,}) {
  return _then(_AppliedChange(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,originalContent: freezed == originalContent ? _self.originalContent : originalContent // ignore: cast_nullable_to_non_nullable
as String?,newContent: null == newContent ? _self.newContent : newContent // ignore: cast_nullable_to_non_nullable
as String,appliedAt: null == appliedAt ? _self.appliedAt : appliedAt // ignore: cast_nullable_to_non_nullable
as DateTime,additions: null == additions ? _self.additions : additions // ignore: cast_nullable_to_non_nullable
as int,deletions: null == deletions ? _self.deletions : deletions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
