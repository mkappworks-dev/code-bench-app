// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkspaceProject {

 String get id; String get name; String? get localPath; String? get repositoryId; String? get activeBranch; List<String> get sessionIds; DateTime? get lastOpenedAt;
/// Create a copy of WorkspaceProject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceProjectCopyWith<WorkspaceProject> get copyWith => _$WorkspaceProjectCopyWithImpl<WorkspaceProject>(this as WorkspaceProject, _$identity);

  /// Serializes this WorkspaceProject to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceProject&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.repositoryId, repositoryId) || other.repositoryId == repositoryId)&&(identical(other.activeBranch, activeBranch) || other.activeBranch == activeBranch)&&const DeepCollectionEquality().equals(other.sessionIds, sessionIds)&&(identical(other.lastOpenedAt, lastOpenedAt) || other.lastOpenedAt == lastOpenedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,localPath,repositoryId,activeBranch,const DeepCollectionEquality().hash(sessionIds),lastOpenedAt);

@override
String toString() {
  return 'WorkspaceProject(id: $id, name: $name, localPath: $localPath, repositoryId: $repositoryId, activeBranch: $activeBranch, sessionIds: $sessionIds, lastOpenedAt: $lastOpenedAt)';
}


}

/// @nodoc
abstract mixin class $WorkspaceProjectCopyWith<$Res>  {
  factory $WorkspaceProjectCopyWith(WorkspaceProject value, $Res Function(WorkspaceProject) _then) = _$WorkspaceProjectCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? localPath, String? repositoryId, String? activeBranch, List<String> sessionIds, DateTime? lastOpenedAt
});




}
/// @nodoc
class _$WorkspaceProjectCopyWithImpl<$Res>
    implements $WorkspaceProjectCopyWith<$Res> {
  _$WorkspaceProjectCopyWithImpl(this._self, this._then);

  final WorkspaceProject _self;
  final $Res Function(WorkspaceProject) _then;

/// Create a copy of WorkspaceProject
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? localPath = freezed,Object? repositoryId = freezed,Object? activeBranch = freezed,Object? sessionIds = null,Object? lastOpenedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,repositoryId: freezed == repositoryId ? _self.repositoryId : repositoryId // ignore: cast_nullable_to_non_nullable
as String?,activeBranch: freezed == activeBranch ? _self.activeBranch : activeBranch // ignore: cast_nullable_to_non_nullable
as String?,sessionIds: null == sessionIds ? _self.sessionIds : sessionIds // ignore: cast_nullable_to_non_nullable
as List<String>,lastOpenedAt: freezed == lastOpenedAt ? _self.lastOpenedAt : lastOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceProject].
extension WorkspaceProjectPatterns on WorkspaceProject {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceProject value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceProject() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceProject value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceProject():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceProject value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceProject() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? localPath,  String? repositoryId,  String? activeBranch,  List<String> sessionIds,  DateTime? lastOpenedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceProject() when $default != null:
return $default(_that.id,_that.name,_that.localPath,_that.repositoryId,_that.activeBranch,_that.sessionIds,_that.lastOpenedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? localPath,  String? repositoryId,  String? activeBranch,  List<String> sessionIds,  DateTime? lastOpenedAt)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceProject():
return $default(_that.id,_that.name,_that.localPath,_that.repositoryId,_that.activeBranch,_that.sessionIds,_that.lastOpenedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? localPath,  String? repositoryId,  String? activeBranch,  List<String> sessionIds,  DateTime? lastOpenedAt)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceProject() when $default != null:
return $default(_that.id,_that.name,_that.localPath,_that.repositoryId,_that.activeBranch,_that.sessionIds,_that.lastOpenedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkspaceProject implements WorkspaceProject {
  const _WorkspaceProject({required this.id, required this.name, this.localPath, this.repositoryId, this.activeBranch, final  List<String> sessionIds = const [], this.lastOpenedAt}): _sessionIds = sessionIds;
  factory _WorkspaceProject.fromJson(Map<String, dynamic> json) => _$WorkspaceProjectFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? localPath;
@override final  String? repositoryId;
@override final  String? activeBranch;
 final  List<String> _sessionIds;
@override@JsonKey() List<String> get sessionIds {
  if (_sessionIds is EqualUnmodifiableListView) return _sessionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sessionIds);
}

@override final  DateTime? lastOpenedAt;

/// Create a copy of WorkspaceProject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceProjectCopyWith<_WorkspaceProject> get copyWith => __$WorkspaceProjectCopyWithImpl<_WorkspaceProject>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkspaceProjectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceProject&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.repositoryId, repositoryId) || other.repositoryId == repositoryId)&&(identical(other.activeBranch, activeBranch) || other.activeBranch == activeBranch)&&const DeepCollectionEquality().equals(other._sessionIds, _sessionIds)&&(identical(other.lastOpenedAt, lastOpenedAt) || other.lastOpenedAt == lastOpenedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,localPath,repositoryId,activeBranch,const DeepCollectionEquality().hash(_sessionIds),lastOpenedAt);

@override
String toString() {
  return 'WorkspaceProject(id: $id, name: $name, localPath: $localPath, repositoryId: $repositoryId, activeBranch: $activeBranch, sessionIds: $sessionIds, lastOpenedAt: $lastOpenedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceProjectCopyWith<$Res> implements $WorkspaceProjectCopyWith<$Res> {
  factory _$WorkspaceProjectCopyWith(_WorkspaceProject value, $Res Function(_WorkspaceProject) _then) = __$WorkspaceProjectCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? localPath, String? repositoryId, String? activeBranch, List<String> sessionIds, DateTime? lastOpenedAt
});




}
/// @nodoc
class __$WorkspaceProjectCopyWithImpl<$Res>
    implements _$WorkspaceProjectCopyWith<$Res> {
  __$WorkspaceProjectCopyWithImpl(this._self, this._then);

  final _WorkspaceProject _self;
  final $Res Function(_WorkspaceProject) _then;

/// Create a copy of WorkspaceProject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? localPath = freezed,Object? repositoryId = freezed,Object? activeBranch = freezed,Object? sessionIds = null,Object? lastOpenedAt = freezed,}) {
  return _then(_WorkspaceProject(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,repositoryId: freezed == repositoryId ? _self.repositoryId : repositoryId // ignore: cast_nullable_to_non_nullable
as String?,activeBranch: freezed == activeBranch ? _self.activeBranch : activeBranch // ignore: cast_nullable_to_non_nullable
as String?,sessionIds: null == sessionIds ? _self._sessionIds : sessionIds // ignore: cast_nullable_to_non_nullable
as List<String>,lastOpenedAt: freezed == lastOpenedAt ? _self.lastOpenedAt : lastOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
