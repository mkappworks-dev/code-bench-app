// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coding_tools_denylist_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CodingToolsDenylistFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodingToolsDenylistFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CodingToolsDenylistFailure()';
}


}

/// @nodoc
class $CodingToolsDenylistFailureCopyWith<$Res>  {
$CodingToolsDenylistFailureCopyWith(CodingToolsDenylistFailure _, $Res Function(CodingToolsDenylistFailure) __);
}


/// Adds pattern-matching-related methods to [CodingToolsDenylistFailure].
extension CodingToolsDenylistFailurePatterns on CodingToolsDenylistFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CodingToolsDenylistInvalidEntry value)?  invalidEntry,TResult Function( CodingToolsDenylistDuplicate value)?  duplicate,TResult Function( CodingToolsDenylistSaveFailed value)?  saveFailed,TResult Function( CodingToolsDenylistUnknown value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CodingToolsDenylistInvalidEntry() when invalidEntry != null:
return invalidEntry(_that);case CodingToolsDenylistDuplicate() when duplicate != null:
return duplicate(_that);case CodingToolsDenylistSaveFailed() when saveFailed != null:
return saveFailed(_that);case CodingToolsDenylistUnknown() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CodingToolsDenylistInvalidEntry value)  invalidEntry,required TResult Function( CodingToolsDenylistDuplicate value)  duplicate,required TResult Function( CodingToolsDenylistSaveFailed value)  saveFailed,required TResult Function( CodingToolsDenylistUnknown value)  unknown,}){
final _that = this;
switch (_that) {
case CodingToolsDenylistInvalidEntry():
return invalidEntry(_that);case CodingToolsDenylistDuplicate():
return duplicate(_that);case CodingToolsDenylistSaveFailed():
return saveFailed(_that);case CodingToolsDenylistUnknown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CodingToolsDenylistInvalidEntry value)?  invalidEntry,TResult? Function( CodingToolsDenylistDuplicate value)?  duplicate,TResult? Function( CodingToolsDenylistSaveFailed value)?  saveFailed,TResult? Function( CodingToolsDenylistUnknown value)?  unknown,}){
final _that = this;
switch (_that) {
case CodingToolsDenylistInvalidEntry() when invalidEntry != null:
return invalidEntry(_that);case CodingToolsDenylistDuplicate() when duplicate != null:
return duplicate(_that);case CodingToolsDenylistSaveFailed() when saveFailed != null:
return saveFailed(_that);case CodingToolsDenylistUnknown() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  invalidEntry,TResult Function()?  duplicate,TResult Function()?  saveFailed,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CodingToolsDenylistInvalidEntry() when invalidEntry != null:
return invalidEntry();case CodingToolsDenylistDuplicate() when duplicate != null:
return duplicate();case CodingToolsDenylistSaveFailed() when saveFailed != null:
return saveFailed();case CodingToolsDenylistUnknown() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  invalidEntry,required TResult Function()  duplicate,required TResult Function()  saveFailed,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case CodingToolsDenylistInvalidEntry():
return invalidEntry();case CodingToolsDenylistDuplicate():
return duplicate();case CodingToolsDenylistSaveFailed():
return saveFailed();case CodingToolsDenylistUnknown():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  invalidEntry,TResult? Function()?  duplicate,TResult? Function()?  saveFailed,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case CodingToolsDenylistInvalidEntry() when invalidEntry != null:
return invalidEntry();case CodingToolsDenylistDuplicate() when duplicate != null:
return duplicate();case CodingToolsDenylistSaveFailed() when saveFailed != null:
return saveFailed();case CodingToolsDenylistUnknown() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class CodingToolsDenylistInvalidEntry implements CodingToolsDenylistFailure {
  const CodingToolsDenylistInvalidEntry();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodingToolsDenylistInvalidEntry);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CodingToolsDenylistFailure.invalidEntry()';
}


}




/// @nodoc


class CodingToolsDenylistDuplicate implements CodingToolsDenylistFailure {
  const CodingToolsDenylistDuplicate();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodingToolsDenylistDuplicate);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CodingToolsDenylistFailure.duplicate()';
}


}




/// @nodoc


class CodingToolsDenylistSaveFailed implements CodingToolsDenylistFailure {
  const CodingToolsDenylistSaveFailed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodingToolsDenylistSaveFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CodingToolsDenylistFailure.saveFailed()';
}


}




/// @nodoc


class CodingToolsDenylistUnknown implements CodingToolsDenylistFailure {
  const CodingToolsDenylistUnknown(this.error);
  

 final  Object error;

/// Create a copy of CodingToolsDenylistFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CodingToolsDenylistUnknownCopyWith<CodingToolsDenylistUnknown> get copyWith => _$CodingToolsDenylistUnknownCopyWithImpl<CodingToolsDenylistUnknown>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodingToolsDenylistUnknown&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'CodingToolsDenylistFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $CodingToolsDenylistUnknownCopyWith<$Res> implements $CodingToolsDenylistFailureCopyWith<$Res> {
  factory $CodingToolsDenylistUnknownCopyWith(CodingToolsDenylistUnknown value, $Res Function(CodingToolsDenylistUnknown) _then) = _$CodingToolsDenylistUnknownCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$CodingToolsDenylistUnknownCopyWithImpl<$Res>
    implements $CodingToolsDenylistUnknownCopyWith<$Res> {
  _$CodingToolsDenylistUnknownCopyWithImpl(this._self, this._then);

  final CodingToolsDenylistUnknown _self;
  final $Res Function(CodingToolsDenylistUnknown) _then;

/// Create a copy of CodingToolsDenylistFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(CodingToolsDenylistUnknown(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
