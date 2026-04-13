// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commit_push_button_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommitPushButtonState {

 bool get canCommit; bool get canPush; bool get canPull; bool get canPr; bool get canDropdown; bool get hasUnknownProbe; String get badgeLabel; List<GitRemote> get remotes; String get selectedRemote;
/// Create a copy of CommitPushButtonState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommitPushButtonStateCopyWith<CommitPushButtonState> get copyWith => _$CommitPushButtonStateCopyWithImpl<CommitPushButtonState>(this as CommitPushButtonState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommitPushButtonState&&(identical(other.canCommit, canCommit) || other.canCommit == canCommit)&&(identical(other.canPush, canPush) || other.canPush == canPush)&&(identical(other.canPull, canPull) || other.canPull == canPull)&&(identical(other.canPr, canPr) || other.canPr == canPr)&&(identical(other.canDropdown, canDropdown) || other.canDropdown == canDropdown)&&(identical(other.hasUnknownProbe, hasUnknownProbe) || other.hasUnknownProbe == hasUnknownProbe)&&(identical(other.badgeLabel, badgeLabel) || other.badgeLabel == badgeLabel)&&const DeepCollectionEquality().equals(other.remotes, remotes)&&(identical(other.selectedRemote, selectedRemote) || other.selectedRemote == selectedRemote));
}


@override
int get hashCode => Object.hash(runtimeType,canCommit,canPush,canPull,canPr,canDropdown,hasUnknownProbe,badgeLabel,const DeepCollectionEquality().hash(remotes),selectedRemote);

@override
String toString() {
  return 'CommitPushButtonState(canCommit: $canCommit, canPush: $canPush, canPull: $canPull, canPr: $canPr, canDropdown: $canDropdown, hasUnknownProbe: $hasUnknownProbe, badgeLabel: $badgeLabel, remotes: $remotes, selectedRemote: $selectedRemote)';
}


}

/// @nodoc
abstract mixin class $CommitPushButtonStateCopyWith<$Res>  {
  factory $CommitPushButtonStateCopyWith(CommitPushButtonState value, $Res Function(CommitPushButtonState) _then) = _$CommitPushButtonStateCopyWithImpl;
@useResult
$Res call({
 bool canCommit, bool canPush, bool canPull, bool canPr, bool canDropdown, bool hasUnknownProbe, String badgeLabel, List<GitRemote> remotes, String selectedRemote
});




}
/// @nodoc
class _$CommitPushButtonStateCopyWithImpl<$Res>
    implements $CommitPushButtonStateCopyWith<$Res> {
  _$CommitPushButtonStateCopyWithImpl(this._self, this._then);

  final CommitPushButtonState _self;
  final $Res Function(CommitPushButtonState) _then;

/// Create a copy of CommitPushButtonState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? canCommit = null,Object? canPush = null,Object? canPull = null,Object? canPr = null,Object? canDropdown = null,Object? hasUnknownProbe = null,Object? badgeLabel = null,Object? remotes = null,Object? selectedRemote = null,}) {
  return _then(_self.copyWith(
canCommit: null == canCommit ? _self.canCommit : canCommit // ignore: cast_nullable_to_non_nullable
as bool,canPush: null == canPush ? _self.canPush : canPush // ignore: cast_nullable_to_non_nullable
as bool,canPull: null == canPull ? _self.canPull : canPull // ignore: cast_nullable_to_non_nullable
as bool,canPr: null == canPr ? _self.canPr : canPr // ignore: cast_nullable_to_non_nullable
as bool,canDropdown: null == canDropdown ? _self.canDropdown : canDropdown // ignore: cast_nullable_to_non_nullable
as bool,hasUnknownProbe: null == hasUnknownProbe ? _self.hasUnknownProbe : hasUnknownProbe // ignore: cast_nullable_to_non_nullable
as bool,badgeLabel: null == badgeLabel ? _self.badgeLabel : badgeLabel // ignore: cast_nullable_to_non_nullable
as String,remotes: null == remotes ? _self.remotes : remotes // ignore: cast_nullable_to_non_nullable
as List<GitRemote>,selectedRemote: null == selectedRemote ? _self.selectedRemote : selectedRemote // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CommitPushButtonState].
extension CommitPushButtonStatePatterns on CommitPushButtonState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommitPushButtonState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommitPushButtonState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommitPushButtonState value)  $default,){
final _that = this;
switch (_that) {
case _CommitPushButtonState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommitPushButtonState value)?  $default,){
final _that = this;
switch (_that) {
case _CommitPushButtonState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool canCommit,  bool canPush,  bool canPull,  bool canPr,  bool canDropdown,  bool hasUnknownProbe,  String badgeLabel,  List<GitRemote> remotes,  String selectedRemote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommitPushButtonState() when $default != null:
return $default(_that.canCommit,_that.canPush,_that.canPull,_that.canPr,_that.canDropdown,_that.hasUnknownProbe,_that.badgeLabel,_that.remotes,_that.selectedRemote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool canCommit,  bool canPush,  bool canPull,  bool canPr,  bool canDropdown,  bool hasUnknownProbe,  String badgeLabel,  List<GitRemote> remotes,  String selectedRemote)  $default,) {final _that = this;
switch (_that) {
case _CommitPushButtonState():
return $default(_that.canCommit,_that.canPush,_that.canPull,_that.canPr,_that.canDropdown,_that.hasUnknownProbe,_that.badgeLabel,_that.remotes,_that.selectedRemote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool canCommit,  bool canPush,  bool canPull,  bool canPr,  bool canDropdown,  bool hasUnknownProbe,  String badgeLabel,  List<GitRemote> remotes,  String selectedRemote)?  $default,) {final _that = this;
switch (_that) {
case _CommitPushButtonState() when $default != null:
return $default(_that.canCommit,_that.canPush,_that.canPull,_that.canPr,_that.canDropdown,_that.hasUnknownProbe,_that.badgeLabel,_that.remotes,_that.selectedRemote);case _:
  return null;

}
}

}

/// @nodoc


class _CommitPushButtonState implements CommitPushButtonState {
  const _CommitPushButtonState({required this.canCommit, required this.canPush, required this.canPull, required this.canPr, required this.canDropdown, required this.hasUnknownProbe, required this.badgeLabel, required final  List<GitRemote> remotes, required this.selectedRemote}): _remotes = remotes;
  

@override final  bool canCommit;
@override final  bool canPush;
@override final  bool canPull;
@override final  bool canPr;
@override final  bool canDropdown;
@override final  bool hasUnknownProbe;
@override final  String badgeLabel;
 final  List<GitRemote> _remotes;
@override List<GitRemote> get remotes {
  if (_remotes is EqualUnmodifiableListView) return _remotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_remotes);
}

@override final  String selectedRemote;

/// Create a copy of CommitPushButtonState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommitPushButtonStateCopyWith<_CommitPushButtonState> get copyWith => __$CommitPushButtonStateCopyWithImpl<_CommitPushButtonState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommitPushButtonState&&(identical(other.canCommit, canCommit) || other.canCommit == canCommit)&&(identical(other.canPush, canPush) || other.canPush == canPush)&&(identical(other.canPull, canPull) || other.canPull == canPull)&&(identical(other.canPr, canPr) || other.canPr == canPr)&&(identical(other.canDropdown, canDropdown) || other.canDropdown == canDropdown)&&(identical(other.hasUnknownProbe, hasUnknownProbe) || other.hasUnknownProbe == hasUnknownProbe)&&(identical(other.badgeLabel, badgeLabel) || other.badgeLabel == badgeLabel)&&const DeepCollectionEquality().equals(other._remotes, _remotes)&&(identical(other.selectedRemote, selectedRemote) || other.selectedRemote == selectedRemote));
}


@override
int get hashCode => Object.hash(runtimeType,canCommit,canPush,canPull,canPr,canDropdown,hasUnknownProbe,badgeLabel,const DeepCollectionEquality().hash(_remotes),selectedRemote);

@override
String toString() {
  return 'CommitPushButtonState(canCommit: $canCommit, canPush: $canPush, canPull: $canPull, canPr: $canPr, canDropdown: $canDropdown, hasUnknownProbe: $hasUnknownProbe, badgeLabel: $badgeLabel, remotes: $remotes, selectedRemote: $selectedRemote)';
}


}

/// @nodoc
abstract mixin class _$CommitPushButtonStateCopyWith<$Res> implements $CommitPushButtonStateCopyWith<$Res> {
  factory _$CommitPushButtonStateCopyWith(_CommitPushButtonState value, $Res Function(_CommitPushButtonState) _then) = __$CommitPushButtonStateCopyWithImpl;
@override @useResult
$Res call({
 bool canCommit, bool canPush, bool canPull, bool canPr, bool canDropdown, bool hasUnknownProbe, String badgeLabel, List<GitRemote> remotes, String selectedRemote
});




}
/// @nodoc
class __$CommitPushButtonStateCopyWithImpl<$Res>
    implements _$CommitPushButtonStateCopyWith<$Res> {
  __$CommitPushButtonStateCopyWithImpl(this._self, this._then);

  final _CommitPushButtonState _self;
  final $Res Function(_CommitPushButtonState) _then;

/// Create a copy of CommitPushButtonState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? canCommit = null,Object? canPush = null,Object? canPull = null,Object? canPr = null,Object? canDropdown = null,Object? hasUnknownProbe = null,Object? badgeLabel = null,Object? remotes = null,Object? selectedRemote = null,}) {
  return _then(_CommitPushButtonState(
canCommit: null == canCommit ? _self.canCommit : canCommit // ignore: cast_nullable_to_non_nullable
as bool,canPush: null == canPush ? _self.canPush : canPush // ignore: cast_nullable_to_non_nullable
as bool,canPull: null == canPull ? _self.canPull : canPull // ignore: cast_nullable_to_non_nullable
as bool,canPr: null == canPr ? _self.canPr : canPr // ignore: cast_nullable_to_non_nullable
as bool,canDropdown: null == canDropdown ? _self.canDropdown : canDropdown // ignore: cast_nullable_to_non_nullable
as bool,hasUnknownProbe: null == hasUnknownProbe ? _self.hasUnknownProbe : hasUnknownProbe // ignore: cast_nullable_to_non_nullable
as bool,badgeLabel: null == badgeLabel ? _self.badgeLabel : badgeLabel // ignore: cast_nullable_to_non_nullable
as String,remotes: null == remotes ? _self._remotes : remotes // ignore: cast_nullable_to_non_nullable
as List<GitRemote>,selectedRemote: null == selectedRemote ? _self.selectedRemote : selectedRemote // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
