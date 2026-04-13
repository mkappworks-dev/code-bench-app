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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PrPreflightReady value)?  ready,TResult Function( PrPreflightFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PrPreflightReady() when ready != null:
return ready(_that);case PrPreflightFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PrPreflightReady value)  ready,required TResult Function( PrPreflightFailed value)  failed,}){
final _that = this;
switch (_that) {
case PrPreflightReady():
return ready(_that);case PrPreflightFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PrPreflightReady value)?  ready,TResult? Function( PrPreflightFailed value)?  failed,}){
final _that = this;
switch (_that) {
case PrPreflightReady() when ready != null:
return ready(_that);case PrPreflightFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String title,  String body,  List<String> branches,  String owner,  String repo,  String currentBranch)?  ready,TResult Function( String message)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PrPreflightReady() when ready != null:
return ready(_that.title,_that.body,_that.branches,_that.owner,_that.repo,_that.currentBranch);case PrPreflightFailed() when failed != null:
return failed(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String title,  String body,  List<String> branches,  String owner,  String repo,  String currentBranch)  ready,required TResult Function( String message)  failed,}) {final _that = this;
switch (_that) {
case PrPreflightReady():
return ready(_that.title,_that.body,_that.branches,_that.owner,_that.repo,_that.currentBranch);case PrPreflightFailed():
return failed(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String title,  String body,  List<String> branches,  String owner,  String repo,  String currentBranch)?  ready,TResult? Function( String message)?  failed,}) {final _that = this;
switch (_that) {
case PrPreflightReady() when ready != null:
return ready(_that.title,_that.body,_that.branches,_that.owner,_that.repo,_that.currentBranch);case PrPreflightFailed() when failed != null:
return failed(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class PrPreflightReady implements PrPreflightResult {
  const PrPreflightReady({required this.title, required this.body, required final  List<String> branches, required this.owner, required this.repo, required this.currentBranch}): _branches = branches;
  

 final  String title;
 final  String body;
 final  List<String> _branches;
 List<String> get branches {
  if (_branches is EqualUnmodifiableListView) return _branches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_branches);
}

 final  String owner;
 final  String repo;
 final  String currentBranch;

/// Create a copy of PrPreflightResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrPreflightReadyCopyWith<PrPreflightReady> get copyWith => _$PrPreflightReadyCopyWithImpl<PrPreflightReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrPreflightReady&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other._branches, _branches)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.repo, repo) || other.repo == repo)&&(identical(other.currentBranch, currentBranch) || other.currentBranch == currentBranch));
}


@override
int get hashCode => Object.hash(runtimeType,title,body,const DeepCollectionEquality().hash(_branches),owner,repo,currentBranch);

@override
String toString() {
  return 'PrPreflightResult.ready(title: $title, body: $body, branches: $branches, owner: $owner, repo: $repo, currentBranch: $currentBranch)';
}


}

/// @nodoc
abstract mixin class $PrPreflightReadyCopyWith<$Res> implements $PrPreflightResultCopyWith<$Res> {
  factory $PrPreflightReadyCopyWith(PrPreflightReady value, $Res Function(PrPreflightReady) _then) = _$PrPreflightReadyCopyWithImpl;
@useResult
$Res call({
 String title, String body, List<String> branches, String owner, String repo, String currentBranch
});




}
/// @nodoc
class _$PrPreflightReadyCopyWithImpl<$Res>
    implements $PrPreflightReadyCopyWith<$Res> {
  _$PrPreflightReadyCopyWithImpl(this._self, this._then);

  final PrPreflightReady _self;
  final $Res Function(PrPreflightReady) _then;

/// Create a copy of PrPreflightResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,Object? body = null,Object? branches = null,Object? owner = null,Object? repo = null,Object? currentBranch = null,}) {
  return _then(PrPreflightReady(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,branches: null == branches ? _self._branches : branches // ignore: cast_nullable_to_non_nullable
as List<String>,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,repo: null == repo ? _self.repo : repo // ignore: cast_nullable_to_non_nullable
as String,currentBranch: null == currentBranch ? _self.currentBranch : currentBranch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PrPreflightFailed implements PrPreflightResult {
  const PrPreflightFailed(this.message);
  

 final  String message;

/// Create a copy of PrPreflightResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrPreflightFailedCopyWith<PrPreflightFailed> get copyWith => _$PrPreflightFailedCopyWithImpl<PrPreflightFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrPreflightFailed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PrPreflightResult.failed(message: $message)';
}


}

/// @nodoc
abstract mixin class $PrPreflightFailedCopyWith<$Res> implements $PrPreflightResultCopyWith<$Res> {
  factory $PrPreflightFailedCopyWith(PrPreflightFailed value, $Res Function(PrPreflightFailed) _then) = _$PrPreflightFailedCopyWithImpl;
@useResult
$Res call({
 String message
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
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PrPreflightFailed(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
