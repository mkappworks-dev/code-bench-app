// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdateState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateState()';
}


}

/// @nodoc
class $UpdateStateCopyWith<$Res>  {
$UpdateStateCopyWith(UpdateState _, $Res Function(UpdateState) __);
}


/// Adds pattern-matching-related methods to [UpdateState].
extension UpdateStatePatterns on UpdateState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UpdateStateIdle value)?  idle,TResult Function( UpdateStateChecking value)?  checking,TResult Function( UpdateStateAvailable value)?  available,TResult Function( UpdateStateDownloading value)?  downloading,TResult Function( UpdateStateInstalling value)?  installing,TResult Function( UpdateStateUpToDate value)?  upToDate,TResult Function( UpdateStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UpdateStateIdle() when idle != null:
return idle(_that);case UpdateStateChecking() when checking != null:
return checking(_that);case UpdateStateAvailable() when available != null:
return available(_that);case UpdateStateDownloading() when downloading != null:
return downloading(_that);case UpdateStateInstalling() when installing != null:
return installing(_that);case UpdateStateUpToDate() when upToDate != null:
return upToDate(_that);case UpdateStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UpdateStateIdle value)  idle,required TResult Function( UpdateStateChecking value)  checking,required TResult Function( UpdateStateAvailable value)  available,required TResult Function( UpdateStateDownloading value)  downloading,required TResult Function( UpdateStateInstalling value)  installing,required TResult Function( UpdateStateUpToDate value)  upToDate,required TResult Function( UpdateStateError value)  error,}){
final _that = this;
switch (_that) {
case UpdateStateIdle():
return idle(_that);case UpdateStateChecking():
return checking(_that);case UpdateStateAvailable():
return available(_that);case UpdateStateDownloading():
return downloading(_that);case UpdateStateInstalling():
return installing(_that);case UpdateStateUpToDate():
return upToDate(_that);case UpdateStateError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UpdateStateIdle value)?  idle,TResult? Function( UpdateStateChecking value)?  checking,TResult? Function( UpdateStateAvailable value)?  available,TResult? Function( UpdateStateDownloading value)?  downloading,TResult? Function( UpdateStateInstalling value)?  installing,TResult? Function( UpdateStateUpToDate value)?  upToDate,TResult? Function( UpdateStateError value)?  error,}){
final _that = this;
switch (_that) {
case UpdateStateIdle() when idle != null:
return idle(_that);case UpdateStateChecking() when checking != null:
return checking(_that);case UpdateStateAvailable() when available != null:
return available(_that);case UpdateStateDownloading() when downloading != null:
return downloading(_that);case UpdateStateInstalling() when installing != null:
return installing(_that);case UpdateStateUpToDate() when upToDate != null:
return upToDate(_that);case UpdateStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  checking,TResult Function( UpdateInfo info)?  available,TResult Function( UpdateInfo info,  double progress)?  downloading,TResult Function( UpdateInfo info)?  installing,TResult Function()?  upToDate,TResult Function( UpdateFailure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UpdateStateIdle() when idle != null:
return idle();case UpdateStateChecking() when checking != null:
return checking();case UpdateStateAvailable() when available != null:
return available(_that.info);case UpdateStateDownloading() when downloading != null:
return downloading(_that.info,_that.progress);case UpdateStateInstalling() when installing != null:
return installing(_that.info);case UpdateStateUpToDate() when upToDate != null:
return upToDate();case UpdateStateError() when error != null:
return error(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  checking,required TResult Function( UpdateInfo info)  available,required TResult Function( UpdateInfo info,  double progress)  downloading,required TResult Function( UpdateInfo info)  installing,required TResult Function()  upToDate,required TResult Function( UpdateFailure failure)  error,}) {final _that = this;
switch (_that) {
case UpdateStateIdle():
return idle();case UpdateStateChecking():
return checking();case UpdateStateAvailable():
return available(_that.info);case UpdateStateDownloading():
return downloading(_that.info,_that.progress);case UpdateStateInstalling():
return installing(_that.info);case UpdateStateUpToDate():
return upToDate();case UpdateStateError():
return error(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  checking,TResult? Function( UpdateInfo info)?  available,TResult? Function( UpdateInfo info,  double progress)?  downloading,TResult? Function( UpdateInfo info)?  installing,TResult? Function()?  upToDate,TResult? Function( UpdateFailure failure)?  error,}) {final _that = this;
switch (_that) {
case UpdateStateIdle() when idle != null:
return idle();case UpdateStateChecking() when checking != null:
return checking();case UpdateStateAvailable() when available != null:
return available(_that.info);case UpdateStateDownloading() when downloading != null:
return downloading(_that.info,_that.progress);case UpdateStateInstalling() when installing != null:
return installing(_that.info);case UpdateStateUpToDate() when upToDate != null:
return upToDate();case UpdateStateError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class UpdateStateIdle implements UpdateState {
  const UpdateStateIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateStateIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateState.idle()';
}


}




/// @nodoc


class UpdateStateChecking implements UpdateState {
  const UpdateStateChecking();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateStateChecking);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateState.checking()';
}


}




/// @nodoc


class UpdateStateAvailable implements UpdateState {
  const UpdateStateAvailable(this.info);
  

 final  UpdateInfo info;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateStateAvailableCopyWith<UpdateStateAvailable> get copyWith => _$UpdateStateAvailableCopyWithImpl<UpdateStateAvailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateStateAvailable&&(identical(other.info, info) || other.info == info));
}


@override
int get hashCode => Object.hash(runtimeType,info);

@override
String toString() {
  return 'UpdateState.available(info: $info)';
}


}

/// @nodoc
abstract mixin class $UpdateStateAvailableCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateStateAvailableCopyWith(UpdateStateAvailable value, $Res Function(UpdateStateAvailable) _then) = _$UpdateStateAvailableCopyWithImpl;
@useResult
$Res call({
 UpdateInfo info
});


$UpdateInfoCopyWith<$Res> get info;

}
/// @nodoc
class _$UpdateStateAvailableCopyWithImpl<$Res>
    implements $UpdateStateAvailableCopyWith<$Res> {
  _$UpdateStateAvailableCopyWithImpl(this._self, this._then);

  final UpdateStateAvailable _self;
  final $Res Function(UpdateStateAvailable) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? info = null,}) {
  return _then(UpdateStateAvailable(
null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as UpdateInfo,
  ));
}

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UpdateInfoCopyWith<$Res> get info {
  
  return $UpdateInfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}

/// @nodoc


class UpdateStateDownloading implements UpdateState {
  const UpdateStateDownloading(this.info, this.progress);
  

 final  UpdateInfo info;
 final  double progress;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateStateDownloadingCopyWith<UpdateStateDownloading> get copyWith => _$UpdateStateDownloadingCopyWithImpl<UpdateStateDownloading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateStateDownloading&&(identical(other.info, info) || other.info == info)&&(identical(other.progress, progress) || other.progress == progress));
}


@override
int get hashCode => Object.hash(runtimeType,info,progress);

@override
String toString() {
  return 'UpdateState.downloading(info: $info, progress: $progress)';
}


}

/// @nodoc
abstract mixin class $UpdateStateDownloadingCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateStateDownloadingCopyWith(UpdateStateDownloading value, $Res Function(UpdateStateDownloading) _then) = _$UpdateStateDownloadingCopyWithImpl;
@useResult
$Res call({
 UpdateInfo info, double progress
});


$UpdateInfoCopyWith<$Res> get info;

}
/// @nodoc
class _$UpdateStateDownloadingCopyWithImpl<$Res>
    implements $UpdateStateDownloadingCopyWith<$Res> {
  _$UpdateStateDownloadingCopyWithImpl(this._self, this._then);

  final UpdateStateDownloading _self;
  final $Res Function(UpdateStateDownloading) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? info = null,Object? progress = null,}) {
  return _then(UpdateStateDownloading(
null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as UpdateInfo,null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UpdateInfoCopyWith<$Res> get info {
  
  return $UpdateInfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}

/// @nodoc


class UpdateStateInstalling implements UpdateState {
  const UpdateStateInstalling(this.info);
  

 final  UpdateInfo info;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateStateInstallingCopyWith<UpdateStateInstalling> get copyWith => _$UpdateStateInstallingCopyWithImpl<UpdateStateInstalling>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateStateInstalling&&(identical(other.info, info) || other.info == info));
}


@override
int get hashCode => Object.hash(runtimeType,info);

@override
String toString() {
  return 'UpdateState.installing(info: $info)';
}


}

/// @nodoc
abstract mixin class $UpdateStateInstallingCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateStateInstallingCopyWith(UpdateStateInstalling value, $Res Function(UpdateStateInstalling) _then) = _$UpdateStateInstallingCopyWithImpl;
@useResult
$Res call({
 UpdateInfo info
});


$UpdateInfoCopyWith<$Res> get info;

}
/// @nodoc
class _$UpdateStateInstallingCopyWithImpl<$Res>
    implements $UpdateStateInstallingCopyWith<$Res> {
  _$UpdateStateInstallingCopyWithImpl(this._self, this._then);

  final UpdateStateInstalling _self;
  final $Res Function(UpdateStateInstalling) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? info = null,}) {
  return _then(UpdateStateInstalling(
null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as UpdateInfo,
  ));
}

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UpdateInfoCopyWith<$Res> get info {
  
  return $UpdateInfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}

/// @nodoc


class UpdateStateUpToDate implements UpdateState {
  const UpdateStateUpToDate();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateStateUpToDate);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateState.upToDate()';
}


}




/// @nodoc


class UpdateStateError implements UpdateState {
  const UpdateStateError(this.failure);
  

 final  UpdateFailure failure;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateStateErrorCopyWith<UpdateStateError> get copyWith => _$UpdateStateErrorCopyWithImpl<UpdateStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateStateError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'UpdateState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $UpdateStateErrorCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateStateErrorCopyWith(UpdateStateError value, $Res Function(UpdateStateError) _then) = _$UpdateStateErrorCopyWithImpl;
@useResult
$Res call({
 UpdateFailure failure
});


$UpdateFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$UpdateStateErrorCopyWithImpl<$Res>
    implements $UpdateStateErrorCopyWith<$Res> {
  _$UpdateStateErrorCopyWithImpl(this._self, this._then);

  final UpdateStateError _self;
  final $Res Function(UpdateStateError) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(UpdateStateError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as UpdateFailure,
  ));
}

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UpdateFailureCopyWith<$Res> get failure {
  
  return $UpdateFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
