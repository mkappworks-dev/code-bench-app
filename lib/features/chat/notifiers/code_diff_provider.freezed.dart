// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'code_diff_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiffResult {

 String? get originalContent; List<Diff> get diffs;
/// Create a copy of DiffResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiffResultCopyWith<DiffResult> get copyWith => _$DiffResultCopyWithImpl<DiffResult>(this as DiffResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiffResult&&(identical(other.originalContent, originalContent) || other.originalContent == originalContent)&&const DeepCollectionEquality().equals(other.diffs, diffs));
}


@override
int get hashCode => Object.hash(runtimeType,originalContent,const DeepCollectionEquality().hash(diffs));

@override
String toString() {
  return 'DiffResult(originalContent: $originalContent, diffs: $diffs)';
}


}

/// @nodoc
abstract mixin class $DiffResultCopyWith<$Res>  {
  factory $DiffResultCopyWith(DiffResult value, $Res Function(DiffResult) _then) = _$DiffResultCopyWithImpl;
@useResult
$Res call({
 String? originalContent, List<Diff> diffs
});




}
/// @nodoc
class _$DiffResultCopyWithImpl<$Res>
    implements $DiffResultCopyWith<$Res> {
  _$DiffResultCopyWithImpl(this._self, this._then);

  final DiffResult _self;
  final $Res Function(DiffResult) _then;

/// Create a copy of DiffResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? originalContent = freezed,Object? diffs = null,}) {
  return _then(_self.copyWith(
originalContent: freezed == originalContent ? _self.originalContent : originalContent // ignore: cast_nullable_to_non_nullable
as String?,diffs: null == diffs ? _self.diffs : diffs // ignore: cast_nullable_to_non_nullable
as List<Diff>,
  ));
}

}


/// Adds pattern-matching-related methods to [DiffResult].
extension DiffResultPatterns on DiffResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiffResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiffResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiffResult value)  $default,){
final _that = this;
switch (_that) {
case _DiffResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiffResult value)?  $default,){
final _that = this;
switch (_that) {
case _DiffResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? originalContent,  List<Diff> diffs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiffResult() when $default != null:
return $default(_that.originalContent,_that.diffs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? originalContent,  List<Diff> diffs)  $default,) {final _that = this;
switch (_that) {
case _DiffResult():
return $default(_that.originalContent,_that.diffs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? originalContent,  List<Diff> diffs)?  $default,) {final _that = this;
switch (_that) {
case _DiffResult() when $default != null:
return $default(_that.originalContent,_that.diffs);case _:
  return null;

}
}

}

/// @nodoc


class _DiffResult implements DiffResult {
  const _DiffResult({required this.originalContent, required final  List<Diff> diffs}): _diffs = diffs;
  

@override final  String? originalContent;
 final  List<Diff> _diffs;
@override List<Diff> get diffs {
  if (_diffs is EqualUnmodifiableListView) return _diffs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diffs);
}


/// Create a copy of DiffResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiffResultCopyWith<_DiffResult> get copyWith => __$DiffResultCopyWithImpl<_DiffResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiffResult&&(identical(other.originalContent, originalContent) || other.originalContent == originalContent)&&const DeepCollectionEquality().equals(other._diffs, _diffs));
}


@override
int get hashCode => Object.hash(runtimeType,originalContent,const DeepCollectionEquality().hash(_diffs));

@override
String toString() {
  return 'DiffResult(originalContent: $originalContent, diffs: $diffs)';
}


}

/// @nodoc
abstract mixin class _$DiffResultCopyWith<$Res> implements $DiffResultCopyWith<$Res> {
  factory _$DiffResultCopyWith(_DiffResult value, $Res Function(_DiffResult) _then) = __$DiffResultCopyWithImpl;
@override @useResult
$Res call({
 String? originalContent, List<Diff> diffs
});




}
/// @nodoc
class __$DiffResultCopyWithImpl<$Res>
    implements _$DiffResultCopyWith<$Res> {
  __$DiffResultCopyWithImpl(this._self, this._then);

  final _DiffResult _self;
  final $Res Function(_DiffResult) _then;

/// Create a copy of DiffResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? originalContent = freezed,Object? diffs = null,}) {
  return _then(_DiffResult(
originalContent: freezed == originalContent ? _self.originalContent : originalContent // ignore: cast_nullable_to_non_nullable
as String?,diffs: null == diffs ? _self._diffs : diffs // ignore: cast_nullable_to_non_nullable
as List<Diff>,
  ));
}


}

// dart format on
