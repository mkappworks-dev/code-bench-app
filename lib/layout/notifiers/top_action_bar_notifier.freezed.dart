// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'top_action_bar_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TopActionBarState {

 String get sessionTitle; Project? get project;/// Tri-state: `true` = confirmed git repo, `false` = confirmed non-git,
/// `null` = loading or error. Widgets only show "No Git" badge or
/// "Init Git" button for the confirmed `false` case — never while loading,
/// so the bar doesn't flicker on every refocus.
 bool? get isGit;
/// Create a copy of TopActionBarState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopActionBarStateCopyWith<TopActionBarState> get copyWith => _$TopActionBarStateCopyWithImpl<TopActionBarState>(this as TopActionBarState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopActionBarState&&(identical(other.sessionTitle, sessionTitle) || other.sessionTitle == sessionTitle)&&(identical(other.project, project) || other.project == project)&&(identical(other.isGit, isGit) || other.isGit == isGit));
}


@override
int get hashCode => Object.hash(runtimeType,sessionTitle,project,isGit);

@override
String toString() {
  return 'TopActionBarState(sessionTitle: $sessionTitle, project: $project, isGit: $isGit)';
}


}

/// @nodoc
abstract mixin class $TopActionBarStateCopyWith<$Res>  {
  factory $TopActionBarStateCopyWith(TopActionBarState value, $Res Function(TopActionBarState) _then) = _$TopActionBarStateCopyWithImpl;
@useResult
$Res call({
 String sessionTitle, Project? project, bool? isGit
});


$ProjectCopyWith<$Res>? get project;

}
/// @nodoc
class _$TopActionBarStateCopyWithImpl<$Res>
    implements $TopActionBarStateCopyWith<$Res> {
  _$TopActionBarStateCopyWithImpl(this._self, this._then);

  final TopActionBarState _self;
  final $Res Function(TopActionBarState) _then;

/// Create a copy of TopActionBarState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionTitle = null,Object? project = freezed,Object? isGit = freezed,}) {
  return _then(_self.copyWith(
sessionTitle: null == sessionTitle ? _self.sessionTitle : sessionTitle // ignore: cast_nullable_to_non_nullable
as String,project: freezed == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as Project?,isGit: freezed == isGit ? _self.isGit : isGit // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of TopActionBarState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectCopyWith<$Res>? get project {
    if (_self.project == null) {
    return null;
  }

  return $ProjectCopyWith<$Res>(_self.project!, (value) {
    return _then(_self.copyWith(project: value));
  });
}
}


/// Adds pattern-matching-related methods to [TopActionBarState].
extension TopActionBarStatePatterns on TopActionBarState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopActionBarState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopActionBarState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopActionBarState value)  $default,){
final _that = this;
switch (_that) {
case _TopActionBarState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopActionBarState value)?  $default,){
final _that = this;
switch (_that) {
case _TopActionBarState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionTitle,  Project? project,  bool? isGit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopActionBarState() when $default != null:
return $default(_that.sessionTitle,_that.project,_that.isGit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionTitle,  Project? project,  bool? isGit)  $default,) {final _that = this;
switch (_that) {
case _TopActionBarState():
return $default(_that.sessionTitle,_that.project,_that.isGit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionTitle,  Project? project,  bool? isGit)?  $default,) {final _that = this;
switch (_that) {
case _TopActionBarState() when $default != null:
return $default(_that.sessionTitle,_that.project,_that.isGit);case _:
  return null;

}
}

}

/// @nodoc


class _TopActionBarState implements TopActionBarState {
  const _TopActionBarState({required this.sessionTitle, required this.project, required this.isGit});
  

@override final  String sessionTitle;
@override final  Project? project;
/// Tri-state: `true` = confirmed git repo, `false` = confirmed non-git,
/// `null` = loading or error. Widgets only show "No Git" badge or
/// "Init Git" button for the confirmed `false` case — never while loading,
/// so the bar doesn't flicker on every refocus.
@override final  bool? isGit;

/// Create a copy of TopActionBarState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopActionBarStateCopyWith<_TopActionBarState> get copyWith => __$TopActionBarStateCopyWithImpl<_TopActionBarState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopActionBarState&&(identical(other.sessionTitle, sessionTitle) || other.sessionTitle == sessionTitle)&&(identical(other.project, project) || other.project == project)&&(identical(other.isGit, isGit) || other.isGit == isGit));
}


@override
int get hashCode => Object.hash(runtimeType,sessionTitle,project,isGit);

@override
String toString() {
  return 'TopActionBarState(sessionTitle: $sessionTitle, project: $project, isGit: $isGit)';
}


}

/// @nodoc
abstract mixin class _$TopActionBarStateCopyWith<$Res> implements $TopActionBarStateCopyWith<$Res> {
  factory _$TopActionBarStateCopyWith(_TopActionBarState value, $Res Function(_TopActionBarState) _then) = __$TopActionBarStateCopyWithImpl;
@override @useResult
$Res call({
 String sessionTitle, Project? project, bool? isGit
});


@override $ProjectCopyWith<$Res>? get project;

}
/// @nodoc
class __$TopActionBarStateCopyWithImpl<$Res>
    implements _$TopActionBarStateCopyWith<$Res> {
  __$TopActionBarStateCopyWithImpl(this._self, this._then);

  final _TopActionBarState _self;
  final $Res Function(_TopActionBarState) _then;

/// Create a copy of TopActionBarState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionTitle = null,Object? project = freezed,Object? isGit = freezed,}) {
  return _then(_TopActionBarState(
sessionTitle: null == sessionTitle ? _self.sessionTitle : sessionTitle // ignore: cast_nullable_to_non_nullable
as String,project: freezed == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as Project?,isGit: freezed == isGit ? _self.isGit : isGit // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of TopActionBarState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectCopyWith<$Res>? get project {
    if (_self.project == null) {
    return null;
  }

  return $ProjectCopyWith<$Res>(_self.project!, (value) {
    return _then(_self.copyWith(project: value));
  });
}
}

// dart format on
