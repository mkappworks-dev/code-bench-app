// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'branch_picker_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BranchPickerFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BranchPickerFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BranchPickerFailure()';
}


}

/// @nodoc
class $BranchPickerFailureCopyWith<$Res>  {
$BranchPickerFailureCopyWith(BranchPickerFailure _, $Res Function(BranchPickerFailure) __);
}


/// Adds pattern-matching-related methods to [BranchPickerFailure].
extension BranchPickerFailurePatterns on BranchPickerFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BranchPickerGitUnavailable value)?  gitUnavailable,TResult Function( BranchPickerInvalidName value)?  invalidName,TResult Function( BranchPickerCheckoutConflict value)?  checkoutConflict,TResult Function( BranchPickerCreateFailed value)?  createFailed,TResult Function( BranchPickerCreateWorktreeFailed value)?  createWorktreeFailed,TResult Function( BranchPickerUnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BranchPickerGitUnavailable() when gitUnavailable != null:
return gitUnavailable(_that);case BranchPickerInvalidName() when invalidName != null:
return invalidName(_that);case BranchPickerCheckoutConflict() when checkoutConflict != null:
return checkoutConflict(_that);case BranchPickerCreateFailed() when createFailed != null:
return createFailed(_that);case BranchPickerCreateWorktreeFailed() when createWorktreeFailed != null:
return createWorktreeFailed(_that);case BranchPickerUnknownError() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BranchPickerGitUnavailable value)  gitUnavailable,required TResult Function( BranchPickerInvalidName value)  invalidName,required TResult Function( BranchPickerCheckoutConflict value)  checkoutConflict,required TResult Function( BranchPickerCreateFailed value)  createFailed,required TResult Function( BranchPickerCreateWorktreeFailed value)  createWorktreeFailed,required TResult Function( BranchPickerUnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case BranchPickerGitUnavailable():
return gitUnavailable(_that);case BranchPickerInvalidName():
return invalidName(_that);case BranchPickerCheckoutConflict():
return checkoutConflict(_that);case BranchPickerCreateFailed():
return createFailed(_that);case BranchPickerCreateWorktreeFailed():
return createWorktreeFailed(_that);case BranchPickerUnknownError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BranchPickerGitUnavailable value)?  gitUnavailable,TResult? Function( BranchPickerInvalidName value)?  invalidName,TResult? Function( BranchPickerCheckoutConflict value)?  checkoutConflict,TResult? Function( BranchPickerCreateFailed value)?  createFailed,TResult? Function( BranchPickerCreateWorktreeFailed value)?  createWorktreeFailed,TResult? Function( BranchPickerUnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case BranchPickerGitUnavailable() when gitUnavailable != null:
return gitUnavailable(_that);case BranchPickerInvalidName() when invalidName != null:
return invalidName(_that);case BranchPickerCheckoutConflict() when checkoutConflict != null:
return checkoutConflict(_that);case BranchPickerCreateFailed() when createFailed != null:
return createFailed(_that);case BranchPickerCreateWorktreeFailed() when createWorktreeFailed != null:
return createWorktreeFailed(_that);case BranchPickerUnknownError() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  gitUnavailable,TResult Function( String reason)?  invalidName,TResult Function( String message)?  checkoutConflict,TResult Function( String message)?  createFailed,TResult Function( String message)?  createWorktreeFailed,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BranchPickerGitUnavailable() when gitUnavailable != null:
return gitUnavailable();case BranchPickerInvalidName() when invalidName != null:
return invalidName(_that.reason);case BranchPickerCheckoutConflict() when checkoutConflict != null:
return checkoutConflict(_that.message);case BranchPickerCreateFailed() when createFailed != null:
return createFailed(_that.message);case BranchPickerCreateWorktreeFailed() when createWorktreeFailed != null:
return createWorktreeFailed(_that.message);case BranchPickerUnknownError() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  gitUnavailable,required TResult Function( String reason)  invalidName,required TResult Function( String message)  checkoutConflict,required TResult Function( String message)  createFailed,required TResult Function( String message)  createWorktreeFailed,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case BranchPickerGitUnavailable():
return gitUnavailable();case BranchPickerInvalidName():
return invalidName(_that.reason);case BranchPickerCheckoutConflict():
return checkoutConflict(_that.message);case BranchPickerCreateFailed():
return createFailed(_that.message);case BranchPickerCreateWorktreeFailed():
return createWorktreeFailed(_that.message);case BranchPickerUnknownError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  gitUnavailable,TResult? Function( String reason)?  invalidName,TResult? Function( String message)?  checkoutConflict,TResult? Function( String message)?  createFailed,TResult? Function( String message)?  createWorktreeFailed,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case BranchPickerGitUnavailable() when gitUnavailable != null:
return gitUnavailable();case BranchPickerInvalidName() when invalidName != null:
return invalidName(_that.reason);case BranchPickerCheckoutConflict() when checkoutConflict != null:
return checkoutConflict(_that.message);case BranchPickerCreateFailed() when createFailed != null:
return createFailed(_that.message);case BranchPickerCreateWorktreeFailed() when createWorktreeFailed != null:
return createWorktreeFailed(_that.message);case BranchPickerUnknownError() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class BranchPickerGitUnavailable implements BranchPickerFailure {
  const BranchPickerGitUnavailable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BranchPickerGitUnavailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BranchPickerFailure.gitUnavailable()';
}


}




/// @nodoc


class BranchPickerInvalidName implements BranchPickerFailure {
  const BranchPickerInvalidName(this.reason);
  

 final  String reason;

/// Create a copy of BranchPickerFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BranchPickerInvalidNameCopyWith<BranchPickerInvalidName> get copyWith => _$BranchPickerInvalidNameCopyWithImpl<BranchPickerInvalidName>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BranchPickerInvalidName&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'BranchPickerFailure.invalidName(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $BranchPickerInvalidNameCopyWith<$Res> implements $BranchPickerFailureCopyWith<$Res> {
  factory $BranchPickerInvalidNameCopyWith(BranchPickerInvalidName value, $Res Function(BranchPickerInvalidName) _then) = _$BranchPickerInvalidNameCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$BranchPickerInvalidNameCopyWithImpl<$Res>
    implements $BranchPickerInvalidNameCopyWith<$Res> {
  _$BranchPickerInvalidNameCopyWithImpl(this._self, this._then);

  final BranchPickerInvalidName _self;
  final $Res Function(BranchPickerInvalidName) _then;

/// Create a copy of BranchPickerFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(BranchPickerInvalidName(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class BranchPickerCheckoutConflict implements BranchPickerFailure {
  const BranchPickerCheckoutConflict(this.message);
  

 final  String message;

/// Create a copy of BranchPickerFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BranchPickerCheckoutConflictCopyWith<BranchPickerCheckoutConflict> get copyWith => _$BranchPickerCheckoutConflictCopyWithImpl<BranchPickerCheckoutConflict>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BranchPickerCheckoutConflict&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'BranchPickerFailure.checkoutConflict(message: $message)';
}


}

/// @nodoc
abstract mixin class $BranchPickerCheckoutConflictCopyWith<$Res> implements $BranchPickerFailureCopyWith<$Res> {
  factory $BranchPickerCheckoutConflictCopyWith(BranchPickerCheckoutConflict value, $Res Function(BranchPickerCheckoutConflict) _then) = _$BranchPickerCheckoutConflictCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$BranchPickerCheckoutConflictCopyWithImpl<$Res>
    implements $BranchPickerCheckoutConflictCopyWith<$Res> {
  _$BranchPickerCheckoutConflictCopyWithImpl(this._self, this._then);

  final BranchPickerCheckoutConflict _self;
  final $Res Function(BranchPickerCheckoutConflict) _then;

/// Create a copy of BranchPickerFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(BranchPickerCheckoutConflict(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class BranchPickerCreateFailed implements BranchPickerFailure {
  const BranchPickerCreateFailed(this.message);
  

 final  String message;

/// Create a copy of BranchPickerFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BranchPickerCreateFailedCopyWith<BranchPickerCreateFailed> get copyWith => _$BranchPickerCreateFailedCopyWithImpl<BranchPickerCreateFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BranchPickerCreateFailed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'BranchPickerFailure.createFailed(message: $message)';
}


}

/// @nodoc
abstract mixin class $BranchPickerCreateFailedCopyWith<$Res> implements $BranchPickerFailureCopyWith<$Res> {
  factory $BranchPickerCreateFailedCopyWith(BranchPickerCreateFailed value, $Res Function(BranchPickerCreateFailed) _then) = _$BranchPickerCreateFailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$BranchPickerCreateFailedCopyWithImpl<$Res>
    implements $BranchPickerCreateFailedCopyWith<$Res> {
  _$BranchPickerCreateFailedCopyWithImpl(this._self, this._then);

  final BranchPickerCreateFailed _self;
  final $Res Function(BranchPickerCreateFailed) _then;

/// Create a copy of BranchPickerFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(BranchPickerCreateFailed(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class BranchPickerCreateWorktreeFailed implements BranchPickerFailure {
  const BranchPickerCreateWorktreeFailed(this.message);
  

 final  String message;

/// Create a copy of BranchPickerFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BranchPickerCreateWorktreeFailedCopyWith<BranchPickerCreateWorktreeFailed> get copyWith => _$BranchPickerCreateWorktreeFailedCopyWithImpl<BranchPickerCreateWorktreeFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BranchPickerCreateWorktreeFailed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'BranchPickerFailure.createWorktreeFailed(message: $message)';
}


}

/// @nodoc
abstract mixin class $BranchPickerCreateWorktreeFailedCopyWith<$Res> implements $BranchPickerFailureCopyWith<$Res> {
  factory $BranchPickerCreateWorktreeFailedCopyWith(BranchPickerCreateWorktreeFailed value, $Res Function(BranchPickerCreateWorktreeFailed) _then) = _$BranchPickerCreateWorktreeFailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$BranchPickerCreateWorktreeFailedCopyWithImpl<$Res>
    implements $BranchPickerCreateWorktreeFailedCopyWith<$Res> {
  _$BranchPickerCreateWorktreeFailedCopyWithImpl(this._self, this._then);

  final BranchPickerCreateWorktreeFailed _self;
  final $Res Function(BranchPickerCreateWorktreeFailed) _then;

/// Create a copy of BranchPickerFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(BranchPickerCreateWorktreeFailed(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class BranchPickerUnknownError implements BranchPickerFailure {
  const BranchPickerUnknownError(this.error);
  

 final  Object error;

/// Create a copy of BranchPickerFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BranchPickerUnknownErrorCopyWith<BranchPickerUnknownError> get copyWith => _$BranchPickerUnknownErrorCopyWithImpl<BranchPickerUnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BranchPickerUnknownError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'BranchPickerFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $BranchPickerUnknownErrorCopyWith<$Res> implements $BranchPickerFailureCopyWith<$Res> {
  factory $BranchPickerUnknownErrorCopyWith(BranchPickerUnknownError value, $Res Function(BranchPickerUnknownError) _then) = _$BranchPickerUnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$BranchPickerUnknownErrorCopyWithImpl<$Res>
    implements $BranchPickerUnknownErrorCopyWith<$Res> {
  _$BranchPickerUnknownErrorCopyWithImpl(this._self, this._then);

  final BranchPickerUnknownError _self;
  final $Res Function(BranchPickerUnknownError) _then;

/// Create a copy of BranchPickerFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(BranchPickerUnknownError(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
