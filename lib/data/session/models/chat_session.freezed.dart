// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatSession {

 String get sessionId; String get title; String get modelId; String get providerId; String? get projectId; DateTime get createdAt; DateTime get updatedAt; bool get isPinned; bool get isArchived;
/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSessionCopyWith<ChatSession> get copyWith => _$ChatSessionCopyWithImpl<ChatSession>(this as ChatSession, _$identity);

  /// Serializes this ChatSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,title,modelId,providerId,projectId,createdAt,updatedAt,isPinned,isArchived);

@override
String toString() {
  return 'ChatSession(sessionId: $sessionId, title: $title, modelId: $modelId, providerId: $providerId, projectId: $projectId, createdAt: $createdAt, updatedAt: $updatedAt, isPinned: $isPinned, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class $ChatSessionCopyWith<$Res>  {
  factory $ChatSessionCopyWith(ChatSession value, $Res Function(ChatSession) _then) = _$ChatSessionCopyWithImpl;
@useResult
$Res call({
 String sessionId, String title, String modelId, String providerId, String? projectId, DateTime createdAt, DateTime updatedAt, bool isPinned, bool isArchived
});




}
/// @nodoc
class _$ChatSessionCopyWithImpl<$Res>
    implements $ChatSessionCopyWith<$Res> {
  _$ChatSessionCopyWithImpl(this._self, this._then);

  final ChatSession _self;
  final $Res Function(ChatSession) _then;

/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? title = null,Object? modelId = null,Object? providerId = null,Object? projectId = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isPinned = null,Object? isArchived = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,projectId: freezed == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatSession].
extension ChatSessionPatterns on ChatSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatSession value)  $default,){
final _that = this;
switch (_that) {
case _ChatSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatSession value)?  $default,){
final _that = this;
switch (_that) {
case _ChatSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String title,  String modelId,  String providerId,  String? projectId,  DateTime createdAt,  DateTime updatedAt,  bool isPinned,  bool isArchived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatSession() when $default != null:
return $default(_that.sessionId,_that.title,_that.modelId,_that.providerId,_that.projectId,_that.createdAt,_that.updatedAt,_that.isPinned,_that.isArchived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String title,  String modelId,  String providerId,  String? projectId,  DateTime createdAt,  DateTime updatedAt,  bool isPinned,  bool isArchived)  $default,) {final _that = this;
switch (_that) {
case _ChatSession():
return $default(_that.sessionId,_that.title,_that.modelId,_that.providerId,_that.projectId,_that.createdAt,_that.updatedAt,_that.isPinned,_that.isArchived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String title,  String modelId,  String providerId,  String? projectId,  DateTime createdAt,  DateTime updatedAt,  bool isPinned,  bool isArchived)?  $default,) {final _that = this;
switch (_that) {
case _ChatSession() when $default != null:
return $default(_that.sessionId,_that.title,_that.modelId,_that.providerId,_that.projectId,_that.createdAt,_that.updatedAt,_that.isPinned,_that.isArchived);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatSession implements ChatSession {
  const _ChatSession({required this.sessionId, required this.title, required this.modelId, required this.providerId, this.projectId, required this.createdAt, required this.updatedAt, this.isPinned = false, this.isArchived = false});
  factory _ChatSession.fromJson(Map<String, dynamic> json) => _$ChatSessionFromJson(json);

@override final  String sessionId;
@override final  String title;
@override final  String modelId;
@override final  String providerId;
@override final  String? projectId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  bool isPinned;
@override@JsonKey() final  bool isArchived;

/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatSessionCopyWith<_ChatSession> get copyWith => __$ChatSessionCopyWithImpl<_ChatSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,title,modelId,providerId,projectId,createdAt,updatedAt,isPinned,isArchived);

@override
String toString() {
  return 'ChatSession(sessionId: $sessionId, title: $title, modelId: $modelId, providerId: $providerId, projectId: $projectId, createdAt: $createdAt, updatedAt: $updatedAt, isPinned: $isPinned, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class _$ChatSessionCopyWith<$Res> implements $ChatSessionCopyWith<$Res> {
  factory _$ChatSessionCopyWith(_ChatSession value, $Res Function(_ChatSession) _then) = __$ChatSessionCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String title, String modelId, String providerId, String? projectId, DateTime createdAt, DateTime updatedAt, bool isPinned, bool isArchived
});




}
/// @nodoc
class __$ChatSessionCopyWithImpl<$Res>
    implements _$ChatSessionCopyWith<$Res> {
  __$ChatSessionCopyWithImpl(this._self, this._then);

  final _ChatSession _self;
  final $Res Function(_ChatSession) _then;

/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? title = null,Object? modelId = null,Object? providerId = null,Object? projectId = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isPinned = null,Object? isArchived = null,}) {
  return _then(_ChatSession(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,projectId: freezed == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
