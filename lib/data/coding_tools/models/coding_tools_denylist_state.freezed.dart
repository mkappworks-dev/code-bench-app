// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coding_tools_denylist_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CodingToolsDenylistState {

 Map<DenylistCategory, Set<String>> get userAdded; Map<DenylistCategory, Set<String>> get suppressedDefaults;
/// Create a copy of CodingToolsDenylistState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CodingToolsDenylistStateCopyWith<CodingToolsDenylistState> get copyWith => _$CodingToolsDenylistStateCopyWithImpl<CodingToolsDenylistState>(this as CodingToolsDenylistState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodingToolsDenylistState&&const DeepCollectionEquality().equals(other.userAdded, userAdded)&&const DeepCollectionEquality().equals(other.suppressedDefaults, suppressedDefaults));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(userAdded),const DeepCollectionEquality().hash(suppressedDefaults));

@override
String toString() {
  return 'CodingToolsDenylistState(userAdded: $userAdded, suppressedDefaults: $suppressedDefaults)';
}


}

/// @nodoc
abstract mixin class $CodingToolsDenylistStateCopyWith<$Res>  {
  factory $CodingToolsDenylistStateCopyWith(CodingToolsDenylistState value, $Res Function(CodingToolsDenylistState) _then) = _$CodingToolsDenylistStateCopyWithImpl;
@useResult
$Res call({
 Map<DenylistCategory, Set<String>> userAdded, Map<DenylistCategory, Set<String>> suppressedDefaults
});




}
/// @nodoc
class _$CodingToolsDenylistStateCopyWithImpl<$Res>
    implements $CodingToolsDenylistStateCopyWith<$Res> {
  _$CodingToolsDenylistStateCopyWithImpl(this._self, this._then);

  final CodingToolsDenylistState _self;
  final $Res Function(CodingToolsDenylistState) _then;

/// Create a copy of CodingToolsDenylistState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userAdded = null,Object? suppressedDefaults = null,}) {
  return _then(_self.copyWith(
userAdded: null == userAdded ? _self.userAdded : userAdded // ignore: cast_nullable_to_non_nullable
as Map<DenylistCategory, Set<String>>,suppressedDefaults: null == suppressedDefaults ? _self.suppressedDefaults : suppressedDefaults // ignore: cast_nullable_to_non_nullable
as Map<DenylistCategory, Set<String>>,
  ));
}

}


/// Adds pattern-matching-related methods to [CodingToolsDenylistState].
extension CodingToolsDenylistStatePatterns on CodingToolsDenylistState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CodingToolsDenylistState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CodingToolsDenylistState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CodingToolsDenylistState value)  $default,){
final _that = this;
switch (_that) {
case _CodingToolsDenylistState():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CodingToolsDenylistState value)?  $default,){
final _that = this;
switch (_that) {
case _CodingToolsDenylistState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<DenylistCategory, Set<String>> userAdded,  Map<DenylistCategory, Set<String>> suppressedDefaults)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CodingToolsDenylistState() when $default != null:
return $default(_that.userAdded,_that.suppressedDefaults);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<DenylistCategory, Set<String>> userAdded,  Map<DenylistCategory, Set<String>> suppressedDefaults)  $default,) {final _that = this;
switch (_that) {
case _CodingToolsDenylistState():
return $default(_that.userAdded,_that.suppressedDefaults);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<DenylistCategory, Set<String>> userAdded,  Map<DenylistCategory, Set<String>> suppressedDefaults)?  $default,) {final _that = this;
switch (_that) {
case _CodingToolsDenylistState() when $default != null:
return $default(_that.userAdded,_that.suppressedDefaults);case _:
  return null;

}
}

}

/// @nodoc


class _CodingToolsDenylistState extends CodingToolsDenylistState {
  const _CodingToolsDenylistState({required final  Map<DenylistCategory, Set<String>> userAdded, required final  Map<DenylistCategory, Set<String>> suppressedDefaults}): _userAdded = userAdded,_suppressedDefaults = suppressedDefaults,super._();
  

 final  Map<DenylistCategory, Set<String>> _userAdded;
@override Map<DenylistCategory, Set<String>> get userAdded {
  if (_userAdded is EqualUnmodifiableMapView) return _userAdded;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_userAdded);
}

 final  Map<DenylistCategory, Set<String>> _suppressedDefaults;
@override Map<DenylistCategory, Set<String>> get suppressedDefaults {
  if (_suppressedDefaults is EqualUnmodifiableMapView) return _suppressedDefaults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_suppressedDefaults);
}


/// Create a copy of CodingToolsDenylistState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CodingToolsDenylistStateCopyWith<_CodingToolsDenylistState> get copyWith => __$CodingToolsDenylistStateCopyWithImpl<_CodingToolsDenylistState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CodingToolsDenylistState&&const DeepCollectionEquality().equals(other._userAdded, _userAdded)&&const DeepCollectionEquality().equals(other._suppressedDefaults, _suppressedDefaults));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_userAdded),const DeepCollectionEquality().hash(_suppressedDefaults));

@override
String toString() {
  return 'CodingToolsDenylistState(userAdded: $userAdded, suppressedDefaults: $suppressedDefaults)';
}


}

/// @nodoc
abstract mixin class _$CodingToolsDenylistStateCopyWith<$Res> implements $CodingToolsDenylistStateCopyWith<$Res> {
  factory _$CodingToolsDenylistStateCopyWith(_CodingToolsDenylistState value, $Res Function(_CodingToolsDenylistState) _then) = __$CodingToolsDenylistStateCopyWithImpl;
@override @useResult
$Res call({
 Map<DenylistCategory, Set<String>> userAdded, Map<DenylistCategory, Set<String>> suppressedDefaults
});




}
/// @nodoc
class __$CodingToolsDenylistStateCopyWithImpl<$Res>
    implements _$CodingToolsDenylistStateCopyWith<$Res> {
  __$CodingToolsDenylistStateCopyWithImpl(this._self, this._then);

  final _CodingToolsDenylistState _self;
  final $Res Function(_CodingToolsDenylistState) _then;

/// Create a copy of CodingToolsDenylistState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userAdded = null,Object? suppressedDefaults = null,}) {
  return _then(_CodingToolsDenylistState(
userAdded: null == userAdded ? _self._userAdded : userAdded // ignore: cast_nullable_to_non_nullable
as Map<DenylistCategory, Set<String>>,suppressedDefaults: null == suppressedDefaults ? _self._suppressedDefaults : suppressedDefaults // ignore: cast_nullable_to_non_nullable
as Map<DenylistCategory, Set<String>>,
  ));
}


}

// dart format on
