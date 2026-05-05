// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pr_preflight_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PrPreflightResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrPreflightResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PrPreflightResult()';
}


}

/// @nodoc
class $PrPreflightResultCopyWith<$Res>  {
$PrPreflightResultCopyWith(PrPreflightResult _, $Res Function(PrPreflightResult) __);
}


/// Adds pattern-matching-related methods to [PrPreflightResult].
extension PrPreflightResultPatterns on PrPreflightResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PrPreflightPassed value)?  passed,TResult Function( PrPreflightFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PrPreflightPassed() when passed != null:
return passed(_that);case PrPreflightFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PrPreflightPassed value)  passed,required TResult Function( PrPreflightFailed value)  failed,}){
final _that = this;
switch (_that) {
case PrPreflightPassed():
return passed(_that);case PrPreflightFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PrPreflightPassed value)?  passed,TResult? Function( PrPreflightFailed value)?  failed,}){
final _that = this;
switch (_that) {
case PrPreflightPassed() when passed != null:
return passed(_that);case PrPreflightFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String owner,  String repo,  String currentBranch)?  passed,TResult Function( String message,  String? actionUrl,  String? actionLabel)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PrPreflightPassed() when passed != null:
return passed(_that.owner,_that.repo,_that.currentBranch);case PrPreflightFailed() when failed != null:
return failed(_that.message,_that.actionUrl,_that.actionLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String owner,  String repo,  String currentBranch)  passed,required TResult Function( String message,  String? actionUrl,  String? actionLabel)  failed,}) {final _that = this;
switch (_that) {
case PrPreflightPassed():
return passed(_that.owner,_that.repo,_that.currentBranch);case PrPreflightFailed():
return failed(_that.message,_that.actionUrl,_that.actionLabel);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String owner,  String repo,  String currentBranch)?  passed,TResult? Function( String message,  String? actionUrl,  String? actionLabel)?  failed,}) {final _that = this;
switch (_that) {
case PrPreflightPassed() when passed != null:
return passed(_that.owner,_that.repo,_that.currentBranch);case PrPreflightFailed() when failed != null:
return failed(_that.message,_that.actionUrl,_that.actionLabel);case _:
  return null;

}
}

}

/// @nodoc


class PrPreflightPassed implements PrPreflightResult {
  const PrPreflightPassed({required this.owner, required this.repo, required this.currentBranch});
  

 final  String owner;
 final  String repo;
 final  String currentBranch;

/// Create a copy of PrPreflightResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrPreflightPassedCopyWith<PrPreflightPassed> get copyWith => _$PrPreflightPassedCopyWithImpl<PrPreflightPassed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrPreflightPassed&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.repo, repo) || other.repo == repo)&&(identical(other.currentBranch, currentBranch) || other.currentBranch == currentBranch));
}


@override
int get hashCode => Object.hash(runtimeType,owner,repo,currentBranch);

@override
String toString() {
  return 'PrPreflightResult.passed(owner: $owner, repo: $repo, currentBranch: $currentBranch)';
}


}

/// @nodoc
abstract mixin class $PrPreflightPassedCopyWith<$Res> implements $PrPreflightResultCopyWith<$Res> {
  factory $PrPreflightPassedCopyWith(PrPreflightPassed value, $Res Function(PrPreflightPassed) _then) = _$PrPreflightPassedCopyWithImpl;
@useResult
$Res call({
 String owner, String repo, String currentBranch
});




}
/// @nodoc
class _$PrPreflightPassedCopyWithImpl<$Res>
    implements $PrPreflightPassedCopyWith<$Res> {
  _$PrPreflightPassedCopyWithImpl(this._self, this._then);

  final PrPreflightPassed _self;
  final $Res Function(PrPreflightPassed) _then;

/// Create a copy of PrPreflightResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? repo = null,Object? currentBranch = null,}) {
  return _then(PrPreflightPassed(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,repo: null == repo ? _self.repo : repo // ignore: cast_nullable_to_non_nullable
as String,currentBranch: null == currentBranch ? _self.currentBranch : currentBranch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PrPreflightFailed implements PrPreflightResult {
  const PrPreflightFailed(this.message, {this.actionUrl, this.actionLabel});
  

 final  String message;
 final  String? actionUrl;
 final  String? actionLabel;

/// Create a copy of PrPreflightResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrPreflightFailedCopyWith<PrPreflightFailed> get copyWith => _$PrPreflightFailedCopyWithImpl<PrPreflightFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrPreflightFailed&&(identical(other.message, message) || other.message == message)&&(identical(other.actionUrl, actionUrl) || other.actionUrl == actionUrl)&&(identical(other.actionLabel, actionLabel) || other.actionLabel == actionLabel));
}


@override
int get hashCode => Object.hash(runtimeType,message,actionUrl,actionLabel);

@override
String toString() {
  return 'PrPreflightResult.failed(message: $message, actionUrl: $actionUrl, actionLabel: $actionLabel)';
}


}

/// @nodoc
abstract mixin class $PrPreflightFailedCopyWith<$Res> implements $PrPreflightResultCopyWith<$Res> {
  factory $PrPreflightFailedCopyWith(PrPreflightFailed value, $Res Function(PrPreflightFailed) _then) = _$PrPreflightFailedCopyWithImpl;
@useResult
$Res call({
 String message, String? actionUrl, String? actionLabel
});




}
/// @nodoc
class _$PrPreflightFailedCopyWithImpl<$Res>
    implements $PrPreflightFailedCopyWith<$Res> {
  _$PrPreflightFailedCopyWithImpl(this._self, this._then);

  final PrPreflightFailed _self;
  final $Res Function(PrPreflightFailed) _then;

/// Create a copy of PrPreflightResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? actionUrl = freezed,Object? actionLabel = freezed,}) {
  return _then(PrPreflightFailed(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,actionUrl: freezed == actionUrl ? _self.actionUrl : actionUrl // ignore: cast_nullable_to_non_nullable
as String?,actionLabel: freezed == actionLabel ? _self.actionLabel : actionLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
