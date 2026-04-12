// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status_bar_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StatusBarState {

 Project? get activeProject; int get changeCount; GitLiveState? get liveState;
/// Create a copy of StatusBarState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusBarStateCopyWith<StatusBarState> get copyWith => _$StatusBarStateCopyWithImpl<StatusBarState>(this as StatusBarState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusBarState&&(identical(other.activeProject, activeProject) || other.activeProject == activeProject)&&(identical(other.changeCount, changeCount) || other.changeCount == changeCount)&&(identical(other.liveState, liveState) || other.liveState == liveState));
}


@override
int get hashCode => Object.hash(runtimeType,activeProject,changeCount,liveState);

@override
String toString() {
  return 'StatusBarState(activeProject: $activeProject, changeCount: $changeCount, liveState: $liveState)';
}


}

/// @nodoc
abstract mixin class $StatusBarStateCopyWith<$Res>  {
  factory $StatusBarStateCopyWith(StatusBarState value, $Res Function(StatusBarState) _then) = _$StatusBarStateCopyWithImpl;
@useResult
$Res call({
 Project? activeProject, int changeCount, GitLiveState? liveState
});


$ProjectCopyWith<$Res>? get activeProject;

}
/// @nodoc
class _$StatusBarStateCopyWithImpl<$Res>
    implements $StatusBarStateCopyWith<$Res> {
  _$StatusBarStateCopyWithImpl(this._self, this._then);

  final StatusBarState _self;
  final $Res Function(StatusBarState) _then;

/// Create a copy of StatusBarState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeProject = freezed,Object? changeCount = null,Object? liveState = freezed,}) {
  return _then(_self.copyWith(
activeProject: freezed == activeProject ? _self.activeProject : activeProject // ignore: cast_nullable_to_non_nullable
as Project?,changeCount: null == changeCount ? _self.changeCount : changeCount // ignore: cast_nullable_to_non_nullable
as int,liveState: freezed == liveState ? _self.liveState : liveState // ignore: cast_nullable_to_non_nullable
as GitLiveState?,
  ));
}
/// Create a copy of StatusBarState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectCopyWith<$Res>? get activeProject {
    if (_self.activeProject == null) {
    return null;
  }

  return $ProjectCopyWith<$Res>(_self.activeProject!, (value) {
    return _then(_self.copyWith(activeProject: value));
  });
}
}


/// Adds pattern-matching-related methods to [StatusBarState].
extension StatusBarStatePatterns on StatusBarState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatusBarState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatusBarState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatusBarState value)  $default,){
final _that = this;
switch (_that) {
case _StatusBarState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatusBarState value)?  $default,){
final _that = this;
switch (_that) {
case _StatusBarState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Project? activeProject,  int changeCount,  GitLiveState? liveState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatusBarState() when $default != null:
return $default(_that.activeProject,_that.changeCount,_that.liveState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Project? activeProject,  int changeCount,  GitLiveState? liveState)  $default,) {final _that = this;
switch (_that) {
case _StatusBarState():
return $default(_that.activeProject,_that.changeCount,_that.liveState);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Project? activeProject,  int changeCount,  GitLiveState? liveState)?  $default,) {final _that = this;
switch (_that) {
case _StatusBarState() when $default != null:
return $default(_that.activeProject,_that.changeCount,_that.liveState);case _:
  return null;

}
}

}

/// @nodoc


class _StatusBarState implements StatusBarState {
  const _StatusBarState({required this.activeProject, required this.changeCount, required this.liveState});
  

@override final  Project? activeProject;
@override final  int changeCount;
@override final  GitLiveState? liveState;

/// Create a copy of StatusBarState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatusBarStateCopyWith<_StatusBarState> get copyWith => __$StatusBarStateCopyWithImpl<_StatusBarState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatusBarState&&(identical(other.activeProject, activeProject) || other.activeProject == activeProject)&&(identical(other.changeCount, changeCount) || other.changeCount == changeCount)&&(identical(other.liveState, liveState) || other.liveState == liveState));
}


@override
int get hashCode => Object.hash(runtimeType,activeProject,changeCount,liveState);

@override
String toString() {
  return 'StatusBarState(activeProject: $activeProject, changeCount: $changeCount, liveState: $liveState)';
}


}

/// @nodoc
abstract mixin class _$StatusBarStateCopyWith<$Res> implements $StatusBarStateCopyWith<$Res> {
  factory _$StatusBarStateCopyWith(_StatusBarState value, $Res Function(_StatusBarState) _then) = __$StatusBarStateCopyWithImpl;
@override @useResult
$Res call({
 Project? activeProject, int changeCount, GitLiveState? liveState
});


@override $ProjectCopyWith<$Res>? get activeProject;

}
/// @nodoc
class __$StatusBarStateCopyWithImpl<$Res>
    implements _$StatusBarStateCopyWith<$Res> {
  __$StatusBarStateCopyWithImpl(this._self, this._then);

  final _StatusBarState _self;
  final $Res Function(_StatusBarState) _then;

/// Create a copy of StatusBarState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeProject = freezed,Object? changeCount = null,Object? liveState = freezed,}) {
  return _then(_StatusBarState(
activeProject: freezed == activeProject ? _self.activeProject : activeProject // ignore: cast_nullable_to_non_nullable
as Project?,changeCount: null == changeCount ? _self.changeCount : changeCount // ignore: cast_nullable_to_non_nullable
as int,liveState: freezed == liveState ? _self.liveState : liveState // ignore: cast_nullable_to_non_nullable
as GitLiveState?,
  ));
}

/// Create a copy of StatusBarState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectCopyWith<$Res>? get activeProject {
    if (_self.activeProject == null) {
    return null;
  }

  return $ProjectCopyWith<$Res>(_self.activeProject!, (value) {
    return _then(_self.copyWith(activeProject: value));
  });
}
}

// dart format on
