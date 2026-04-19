// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'archive_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ArchiveFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ArchiveFailure()';
}


}

/// @nodoc
class $ArchiveFailureCopyWith<$Res>  {
$ArchiveFailureCopyWith(ArchiveFailure _, $Res Function(ArchiveFailure) __);
}


/// Adds pattern-matching-related methods to [ArchiveFailure].
extension ArchiveFailurePatterns on ArchiveFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ArchiveStorageError value)?  storage,TResult Function( ArchiveUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ArchiveStorageError() when storage != null:
return storage(_that);case ArchiveUnknownError() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ArchiveStorageError value)  storage,required TResult Function( ArchiveUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case ArchiveStorageError():
return storage(_that);case ArchiveUnknownError():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ArchiveStorageError value)?  storage,TResult? Function( ArchiveUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case ArchiveStorageError() when storage != null:
return storage(_that);case ArchiveUnknownError() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? detail)?  storage,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ArchiveStorageError() when storage != null:
return storage(_that.detail);case ArchiveUnknownError() when unknown != null:
return unknown(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? detail)  storage,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case ArchiveStorageError():
return storage(_that.detail);case ArchiveUnknownError():
return unknown(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? detail)?  storage,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case ArchiveStorageError() when storage != null:
return storage(_that.detail);case ArchiveUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class ArchiveStorageError implements ArchiveFailure {
  const ArchiveStorageError([this.detail]);
  

 final  String? detail;

/// Create a copy of ArchiveFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArchiveStorageErrorCopyWith<ArchiveStorageError> get copyWith => _$ArchiveStorageErrorCopyWithImpl<ArchiveStorageError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveStorageError&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'ArchiveFailure.storage(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $ArchiveStorageErrorCopyWith<$Res> implements $ArchiveFailureCopyWith<$Res> {
  factory $ArchiveStorageErrorCopyWith(ArchiveStorageError value, $Res Function(ArchiveStorageError) _then) = _$ArchiveStorageErrorCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$ArchiveStorageErrorCopyWithImpl<$Res>
    implements $ArchiveStorageErrorCopyWith<$Res> {
  _$ArchiveStorageErrorCopyWithImpl(this._self, this._then);

  final ArchiveStorageError _self;
  final $Res Function(ArchiveStorageError) _then;

/// Create a copy of ArchiveFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(ArchiveStorageError(
freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ArchiveUnknownError implements ArchiveFailure {
  const ArchiveUnknownError(this.error);
  

 final  Object error;

/// Create a copy of ArchiveFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArchiveUnknownErrorCopyWith<ArchiveUnknownError> get copyWith => _$ArchiveUnknownErrorCopyWithImpl<ArchiveUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ArchiveFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $ArchiveUnknownErrorCopyWith<$Res> implements $ArchiveFailureCopyWith<$Res> {
  factory $ArchiveUnknownErrorCopyWith(ArchiveUnknownError value, $Res Function(ArchiveUnknownError) _then) = _$ArchiveUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$ArchiveUnknownErrorCopyWithImpl<$Res>
    implements $ArchiveUnknownErrorCopyWith<$Res> {
  _$ArchiveUnknownErrorCopyWithImpl(this._self, this._then);

  final ArchiveUnknownError _self;
  final $Res Function(ArchiveUnknownError) _then;

/// Create a copy of ArchiveFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(ArchiveUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
