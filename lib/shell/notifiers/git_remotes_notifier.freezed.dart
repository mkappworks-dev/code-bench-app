// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'git_remotes_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GitRemotesState {

 List<GitRemote> get remotes; String get selectedRemote;
/// Create a copy of GitRemotesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitRemotesStateCopyWith<GitRemotesState> get copyWith => _$GitRemotesStateCopyWithImpl<GitRemotesState>(this as GitRemotesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitRemotesState&&const DeepCollectionEquality().equals(other.remotes, remotes)&&(identical(other.selectedRemote, selectedRemote) || other.selectedRemote == selectedRemote));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(remotes),selectedRemote);

@override
String toString() {
  return 'GitRemotesState(remotes: $remotes, selectedRemote: $selectedRemote)';
}


}

/// @nodoc
abstract mixin class $GitRemotesStateCopyWith<$Res>  {
  factory $GitRemotesStateCopyWith(GitRemotesState value, $Res Function(GitRemotesState) _then) = _$GitRemotesStateCopyWithImpl;
@useResult
$Res call({
 List<GitRemote> remotes, String selectedRemote
});




}
/// @nodoc
class _$GitRemotesStateCopyWithImpl<$Res>
    implements $GitRemotesStateCopyWith<$Res> {
  _$GitRemotesStateCopyWithImpl(this._self, this._then);

  final GitRemotesState _self;
  final $Res Function(GitRemotesState) _then;

/// Create a copy of GitRemotesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? remotes = null,Object? selectedRemote = null,}) {
  return _then(_self.copyWith(
remotes: null == remotes ? _self.remotes : remotes // ignore: cast_nullable_to_non_nullable
as List<GitRemote>,selectedRemote: null == selectedRemote ? _self.selectedRemote : selectedRemote // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GitRemotesState].
extension GitRemotesStatePatterns on GitRemotesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitRemotesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitRemotesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitRemotesState value)  $default,){
final _that = this;
switch (_that) {
case _GitRemotesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitRemotesState value)?  $default,){
final _that = this;
switch (_that) {
case _GitRemotesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<GitRemote> remotes,  String selectedRemote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitRemotesState() when $default != null:
return $default(_that.remotes,_that.selectedRemote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<GitRemote> remotes,  String selectedRemote)  $default,) {final _that = this;
switch (_that) {
case _GitRemotesState():
return $default(_that.remotes,_that.selectedRemote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<GitRemote> remotes,  String selectedRemote)?  $default,) {final _that = this;
switch (_that) {
case _GitRemotesState() when $default != null:
return $default(_that.remotes,_that.selectedRemote);case _:
  return null;

}
}

}

/// @nodoc


class _GitRemotesState implements GitRemotesState {
  const _GitRemotesState({required final  List<GitRemote> remotes, required this.selectedRemote}): _remotes = remotes;
  

 final  List<GitRemote> _remotes;
@override List<GitRemote> get remotes {
  if (_remotes is EqualUnmodifiableListView) return _remotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_remotes);
}

@override final  String selectedRemote;

/// Create a copy of GitRemotesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitRemotesStateCopyWith<_GitRemotesState> get copyWith => __$GitRemotesStateCopyWithImpl<_GitRemotesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitRemotesState&&const DeepCollectionEquality().equals(other._remotes, _remotes)&&(identical(other.selectedRemote, selectedRemote) || other.selectedRemote == selectedRemote));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_remotes),selectedRemote);

@override
String toString() {
  return 'GitRemotesState(remotes: $remotes, selectedRemote: $selectedRemote)';
}


}

/// @nodoc
abstract mixin class _$GitRemotesStateCopyWith<$Res> implements $GitRemotesStateCopyWith<$Res> {
  factory _$GitRemotesStateCopyWith(_GitRemotesState value, $Res Function(_GitRemotesState) _then) = __$GitRemotesStateCopyWithImpl;
@override @useResult
$Res call({
 List<GitRemote> remotes, String selectedRemote
});




}
/// @nodoc
class __$GitRemotesStateCopyWithImpl<$Res>
    implements _$GitRemotesStateCopyWith<$Res> {
  __$GitRemotesStateCopyWithImpl(this._self, this._then);

  final _GitRemotesState _self;
  final $Res Function(_GitRemotesState) _then;

/// Create a copy of GitRemotesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? remotes = null,Object? selectedRemote = null,}) {
  return _then(_GitRemotesState(
remotes: null == remotes ? _self._remotes : remotes // ignore: cast_nullable_to_non_nullable
as List<GitRemote>,selectedRemote: null == selectedRemote ? _self.selectedRemote : selectedRemote // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
