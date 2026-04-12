// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'branch_picker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BranchPickerState {

 List<String> get branches; Set<String> get worktreeBranches;
/// Create a copy of BranchPickerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BranchPickerStateCopyWith<BranchPickerState> get copyWith => _$BranchPickerStateCopyWithImpl<BranchPickerState>(this as BranchPickerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BranchPickerState&&const DeepCollectionEquality().equals(other.branches, branches)&&const DeepCollectionEquality().equals(other.worktreeBranches, worktreeBranches));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(branches),const DeepCollectionEquality().hash(worktreeBranches));

@override
String toString() {
  return 'BranchPickerState(branches: $branches, worktreeBranches: $worktreeBranches)';
}


}

/// @nodoc
abstract mixin class $BranchPickerStateCopyWith<$Res>  {
  factory $BranchPickerStateCopyWith(BranchPickerState value, $Res Function(BranchPickerState) _then) = _$BranchPickerStateCopyWithImpl;
@useResult
$Res call({
 List<String> branches, Set<String> worktreeBranches
});




}
/// @nodoc
class _$BranchPickerStateCopyWithImpl<$Res>
    implements $BranchPickerStateCopyWith<$Res> {
  _$BranchPickerStateCopyWithImpl(this._self, this._then);

  final BranchPickerState _self;
  final $Res Function(BranchPickerState) _then;

/// Create a copy of BranchPickerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? branches = null,Object? worktreeBranches = null,}) {
  return _then(_self.copyWith(
branches: null == branches ? _self.branches : branches // ignore: cast_nullable_to_non_nullable
as List<String>,worktreeBranches: null == worktreeBranches ? _self.worktreeBranches : worktreeBranches // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [BranchPickerState].
extension BranchPickerStatePatterns on BranchPickerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BranchPickerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BranchPickerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BranchPickerState value)  $default,){
final _that = this;
switch (_that) {
case _BranchPickerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BranchPickerState value)?  $default,){
final _that = this;
switch (_that) {
case _BranchPickerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> branches,  Set<String> worktreeBranches)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BranchPickerState() when $default != null:
return $default(_that.branches,_that.worktreeBranches);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> branches,  Set<String> worktreeBranches)  $default,) {final _that = this;
switch (_that) {
case _BranchPickerState():
return $default(_that.branches,_that.worktreeBranches);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> branches,  Set<String> worktreeBranches)?  $default,) {final _that = this;
switch (_that) {
case _BranchPickerState() when $default != null:
return $default(_that.branches,_that.worktreeBranches);case _:
  return null;

}
}

}

/// @nodoc


class _BranchPickerState implements BranchPickerState {
  const _BranchPickerState({final  List<String> branches = const [], final  Set<String> worktreeBranches = const {}}): _branches = branches,_worktreeBranches = worktreeBranches;
  

 final  List<String> _branches;
@override@JsonKey() List<String> get branches {
  if (_branches is EqualUnmodifiableListView) return _branches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_branches);
}

 final  Set<String> _worktreeBranches;
@override@JsonKey() Set<String> get worktreeBranches {
  if (_worktreeBranches is EqualUnmodifiableSetView) return _worktreeBranches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_worktreeBranches);
}


/// Create a copy of BranchPickerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BranchPickerStateCopyWith<_BranchPickerState> get copyWith => __$BranchPickerStateCopyWithImpl<_BranchPickerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BranchPickerState&&const DeepCollectionEquality().equals(other._branches, _branches)&&const DeepCollectionEquality().equals(other._worktreeBranches, _worktreeBranches));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_branches),const DeepCollectionEquality().hash(_worktreeBranches));

@override
String toString() {
  return 'BranchPickerState(branches: $branches, worktreeBranches: $worktreeBranches)';
}


}

/// @nodoc
abstract mixin class _$BranchPickerStateCopyWith<$Res> implements $BranchPickerStateCopyWith<$Res> {
  factory _$BranchPickerStateCopyWith(_BranchPickerState value, $Res Function(_BranchPickerState) _then) = __$BranchPickerStateCopyWithImpl;
@override @useResult
$Res call({
 List<String> branches, Set<String> worktreeBranches
});




}
/// @nodoc
class __$BranchPickerStateCopyWithImpl<$Res>
    implements _$BranchPickerStateCopyWith<$Res> {
  __$BranchPickerStateCopyWithImpl(this._self, this._then);

  final _BranchPickerState _self;
  final $Res Function(_BranchPickerState) _then;

/// Create a copy of BranchPickerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? branches = null,Object? worktreeBranches = null,}) {
  return _then(_BranchPickerState(
branches: null == branches ? _self._branches : branches // ignore: cast_nullable_to_non_nullable
as List<String>,worktreeBranches: null == worktreeBranches ? _self._worktreeBranches : worktreeBranches // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
