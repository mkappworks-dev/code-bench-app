// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'general_prefs_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GeneralPrefsFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeneralPrefsFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GeneralPrefsFailure()';
}


}

/// @nodoc
class $GeneralPrefsFailureCopyWith<$Res>  {
$GeneralPrefsFailureCopyWith(GeneralPrefsFailure _, $Res Function(GeneralPrefsFailure) __);
}


/// Adds pattern-matching-related methods to [GeneralPrefsFailure].
extension GeneralPrefsFailurePatterns on GeneralPrefsFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GeneralPrefsSaveFailed value)?  saveFailed,TResult Function( GeneralPrefsUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GeneralPrefsSaveFailed() when saveFailed != null:
return saveFailed(_that);case GeneralPrefsUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GeneralPrefsSaveFailed value)  saveFailed,required TResult Function( GeneralPrefsUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case GeneralPrefsSaveFailed():
return saveFailed(_that);case GeneralPrefsUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GeneralPrefsSaveFailed value)?  saveFailed,TResult? Function( GeneralPrefsUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case GeneralPrefsSaveFailed() when saveFailed != null:
return saveFailed(_that);case GeneralPrefsUnknownError() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  saveFailed,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GeneralPrefsSaveFailed() when saveFailed != null:
return saveFailed();case GeneralPrefsUnknownError() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  saveFailed,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case GeneralPrefsSaveFailed():
return saveFailed();case GeneralPrefsUnknownError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  saveFailed,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case GeneralPrefsSaveFailed() when saveFailed != null:
return saveFailed();case GeneralPrefsUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class GeneralPrefsSaveFailed implements GeneralPrefsFailure {
  const GeneralPrefsSaveFailed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeneralPrefsSaveFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GeneralPrefsFailure.saveFailed()';
}


}




/// @nodoc


class GeneralPrefsUnknownError implements GeneralPrefsFailure {
  const GeneralPrefsUnknownError(this.error);
  

 final  Object error;

/// Create a copy of GeneralPrefsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeneralPrefsUnknownErrorCopyWith<GeneralPrefsUnknownError> get copyWith => _$GeneralPrefsUnknownErrorCopyWithImpl<GeneralPrefsUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeneralPrefsUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'GeneralPrefsFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $GeneralPrefsUnknownErrorCopyWith<$Res> implements $GeneralPrefsFailureCopyWith<$Res> {
  factory $GeneralPrefsUnknownErrorCopyWith(GeneralPrefsUnknownError value, $Res Function(GeneralPrefsUnknownError) _then) = _$GeneralPrefsUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$GeneralPrefsUnknownErrorCopyWithImpl<$Res>
    implements $GeneralPrefsUnknownErrorCopyWith<$Res> {
  _$GeneralPrefsUnknownErrorCopyWithImpl(this._self, this._then);

  final GeneralPrefsUnknownError _self;
  final $Res Function(GeneralPrefsUnknownError) _then;

/// Create a copy of GeneralPrefsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(GeneralPrefsUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
