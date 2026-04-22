// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'code_apply_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CodeApplyFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodeApplyFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CodeApplyFailure()';
}


}

/// @nodoc
class $CodeApplyFailureCopyWith<$Res>  {
$CodeApplyFailureCopyWith(CodeApplyFailure _, $Res Function(CodeApplyFailure) __);
}


/// Adds pattern-matching-related methods to [CodeApplyFailure].
extension CodeApplyFailurePatterns on CodeApplyFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CodeApplyProjectMissing value)?  projectMissing,TResult Function( CodeApplyOutsideProject value)?  outsideProject,TResult Function( CodeApplyTooLarge value)?  tooLarge,TResult Function( CodeApplyDiskWrite value)?  diskWrite,TResult Function( CodeApplyContentChanged value)?  contentChanged,TResult Function( CodeApplyUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CodeApplyProjectMissing() when projectMissing != null:
return projectMissing(_that);case CodeApplyOutsideProject() when outsideProject != null:
return outsideProject(_that);case CodeApplyTooLarge() when tooLarge != null:
return tooLarge(_that);case CodeApplyDiskWrite() when diskWrite != null:
return diskWrite(_that);case CodeApplyContentChanged() when contentChanged != null:
return contentChanged(_that);case CodeApplyUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CodeApplyProjectMissing value)  projectMissing,required TResult Function( CodeApplyOutsideProject value)  outsideProject,required TResult Function( CodeApplyTooLarge value)  tooLarge,required TResult Function( CodeApplyDiskWrite value)  diskWrite,required TResult Function( CodeApplyContentChanged value)  contentChanged,required TResult Function( CodeApplyUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case CodeApplyProjectMissing():
return projectMissing(_that);case CodeApplyOutsideProject():
return outsideProject(_that);case CodeApplyTooLarge():
return tooLarge(_that);case CodeApplyDiskWrite():
return diskWrite(_that);case CodeApplyContentChanged():
return contentChanged(_that);case CodeApplyUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CodeApplyProjectMissing value)?  projectMissing,TResult? Function( CodeApplyOutsideProject value)?  outsideProject,TResult? Function( CodeApplyTooLarge value)?  tooLarge,TResult? Function( CodeApplyDiskWrite value)?  diskWrite,TResult? Function( CodeApplyContentChanged value)?  contentChanged,TResult? Function( CodeApplyUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case CodeApplyProjectMissing() when projectMissing != null:
return projectMissing(_that);case CodeApplyOutsideProject() when outsideProject != null:
return outsideProject(_that);case CodeApplyTooLarge() when tooLarge != null:
return tooLarge(_that);case CodeApplyDiskWrite() when diskWrite != null:
return diskWrite(_that);case CodeApplyContentChanged() when contentChanged != null:
return contentChanged(_that);case CodeApplyUnknownError() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  projectMissing,TResult Function()?  outsideProject,TResult Function( int bytes)?  tooLarge,TResult Function( String message)?  diskWrite,TResult Function()?  contentChanged,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CodeApplyProjectMissing() when projectMissing != null:
return projectMissing();case CodeApplyOutsideProject() when outsideProject != null:
return outsideProject();case CodeApplyTooLarge() when tooLarge != null:
return tooLarge(_that.bytes);case CodeApplyDiskWrite() when diskWrite != null:
return diskWrite(_that.message);case CodeApplyContentChanged() when contentChanged != null:
return contentChanged();case CodeApplyUnknownError() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  projectMissing,required TResult Function()  outsideProject,required TResult Function( int bytes)  tooLarge,required TResult Function( String message)  diskWrite,required TResult Function()  contentChanged,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case CodeApplyProjectMissing():
return projectMissing();case CodeApplyOutsideProject():
return outsideProject();case CodeApplyTooLarge():
return tooLarge(_that.bytes);case CodeApplyDiskWrite():
return diskWrite(_that.message);case CodeApplyContentChanged():
return contentChanged();case CodeApplyUnknownError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  projectMissing,TResult? Function()?  outsideProject,TResult? Function( int bytes)?  tooLarge,TResult? Function( String message)?  diskWrite,TResult? Function()?  contentChanged,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case CodeApplyProjectMissing() when projectMissing != null:
return projectMissing();case CodeApplyOutsideProject() when outsideProject != null:
return outsideProject();case CodeApplyTooLarge() when tooLarge != null:
return tooLarge(_that.bytes);case CodeApplyDiskWrite() when diskWrite != null:
return diskWrite(_that.message);case CodeApplyContentChanged() when contentChanged != null:
return contentChanged();case CodeApplyUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class CodeApplyProjectMissing implements CodeApplyFailure {
  const CodeApplyProjectMissing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodeApplyProjectMissing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CodeApplyFailure.projectMissing()';
}


}




/// @nodoc


class CodeApplyOutsideProject implements CodeApplyFailure {
  const CodeApplyOutsideProject();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodeApplyOutsideProject);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CodeApplyFailure.outsideProject()';
}


}




/// @nodoc


class CodeApplyTooLarge implements CodeApplyFailure {
  const CodeApplyTooLarge(this.bytes);
  

 final  int bytes;

/// Create a copy of CodeApplyFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CodeApplyTooLargeCopyWith<CodeApplyTooLarge> get copyWith => _$CodeApplyTooLargeCopyWithImpl<CodeApplyTooLarge>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodeApplyTooLarge&&(identical(other.bytes, bytes) || other.bytes == bytes));
}


@override
int get hashCode => Object.hash(runtimeType,bytes);

@override
String toString() {
  return 'CodeApplyFailure.tooLarge(bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class $CodeApplyTooLargeCopyWith<$Res> implements $CodeApplyFailureCopyWith<$Res> {
  factory $CodeApplyTooLargeCopyWith(CodeApplyTooLarge value, $Res Function(CodeApplyTooLarge) _then) = _$CodeApplyTooLargeCopyWithImpl;
@useResult
$Res call({
 int bytes
});




}
/// @nodoc
class _$CodeApplyTooLargeCopyWithImpl<$Res>
    implements $CodeApplyTooLargeCopyWith<$Res> {
  _$CodeApplyTooLargeCopyWithImpl(this._self, this._then);

  final CodeApplyTooLarge _self;
  final $Res Function(CodeApplyTooLarge) _then;

/// Create a copy of CodeApplyFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bytes = null,}) {
  return _then(CodeApplyTooLarge(
null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class CodeApplyDiskWrite implements CodeApplyFailure {
  const CodeApplyDiskWrite(this.message);
  

 final  String message;

/// Create a copy of CodeApplyFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CodeApplyDiskWriteCopyWith<CodeApplyDiskWrite> get copyWith => _$CodeApplyDiskWriteCopyWithImpl<CodeApplyDiskWrite>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodeApplyDiskWrite&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'CodeApplyFailure.diskWrite(message: $message)';
}


}

/// @nodoc
abstract mixin class $CodeApplyDiskWriteCopyWith<$Res> implements $CodeApplyFailureCopyWith<$Res> {
  factory $CodeApplyDiskWriteCopyWith(CodeApplyDiskWrite value, $Res Function(CodeApplyDiskWrite) _then) = _$CodeApplyDiskWriteCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$CodeApplyDiskWriteCopyWithImpl<$Res>
    implements $CodeApplyDiskWriteCopyWith<$Res> {
  _$CodeApplyDiskWriteCopyWithImpl(this._self, this._then);

  final CodeApplyDiskWrite _self;
  final $Res Function(CodeApplyDiskWrite) _then;

/// Create a copy of CodeApplyFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(CodeApplyDiskWrite(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CodeApplyContentChanged implements CodeApplyFailure {
  const CodeApplyContentChanged();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodeApplyContentChanged);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CodeApplyFailure.contentChanged()';
}


}




/// @nodoc


class CodeApplyUnknownError implements CodeApplyFailure {
  const CodeApplyUnknownError(this.error);
  

 final  Object error;

/// Create a copy of CodeApplyFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CodeApplyUnknownErrorCopyWith<CodeApplyUnknownError> get copyWith => _$CodeApplyUnknownErrorCopyWithImpl<CodeApplyUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodeApplyUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'CodeApplyFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $CodeApplyUnknownErrorCopyWith<$Res> implements $CodeApplyFailureCopyWith<$Res> {
  factory $CodeApplyUnknownErrorCopyWith(CodeApplyUnknownError value, $Res Function(CodeApplyUnknownError) _then) = _$CodeApplyUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$CodeApplyUnknownErrorCopyWithImpl<$Res>
    implements $CodeApplyUnknownErrorCopyWith<$Res> {
  _$CodeApplyUnknownErrorCopyWithImpl(this._self, this._then);

  final CodeApplyUnknownError _self;
  final $Res Function(CodeApplyUnknownError) _then;

/// Create a copy of CodeApplyFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(CodeApplyUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
