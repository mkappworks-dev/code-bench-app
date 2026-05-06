// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transport_readiness.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransportReadiness {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransportReadiness);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransportReadiness()';
}


}

/// @nodoc
class $TransportReadinessCopyWith<$Res>  {
$TransportReadinessCopyWith(TransportReadiness _, $Res Function(TransportReadiness) __);
}


/// Adds pattern-matching-related methods to [TransportReadiness].
extension TransportReadinessPatterns on TransportReadiness {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TransportReady value)?  ready,TResult Function( TransportNotInstalled value)?  notInstalled,TResult Function( TransportSignedOut value)?  signedOut,TResult Function( TransportHttpKeyMissing value)?  httpKeyMissing,TResult Function( TransportUnknown value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TransportReady() when ready != null:
return ready(_that);case TransportNotInstalled() when notInstalled != null:
return notInstalled(_that);case TransportSignedOut() when signedOut != null:
return signedOut(_that);case TransportHttpKeyMissing() when httpKeyMissing != null:
return httpKeyMissing(_that);case TransportUnknown() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TransportReady value)  ready,required TResult Function( TransportNotInstalled value)  notInstalled,required TResult Function( TransportSignedOut value)  signedOut,required TResult Function( TransportHttpKeyMissing value)  httpKeyMissing,required TResult Function( TransportUnknown value)  unknown,}){
final _that = this;
switch (_that) {
case TransportReady():
return ready(_that);case TransportNotInstalled():
return notInstalled(_that);case TransportSignedOut():
return signedOut(_that);case TransportHttpKeyMissing():
return httpKeyMissing(_that);case TransportUnknown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TransportReady value)?  ready,TResult? Function( TransportNotInstalled value)?  notInstalled,TResult? Function( TransportSignedOut value)?  signedOut,TResult? Function( TransportHttpKeyMissing value)?  httpKeyMissing,TResult? Function( TransportUnknown value)?  unknown,}){
final _that = this;
switch (_that) {
case TransportReady() when ready != null:
return ready(_that);case TransportNotInstalled() when notInstalled != null:
return notInstalled(_that);case TransportSignedOut() when signedOut != null:
return signedOut(_that);case TransportHttpKeyMissing() when httpKeyMissing != null:
return httpKeyMissing(_that);case TransportUnknown() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ready,TResult Function( String provider)?  notInstalled,TResult Function( String provider,  String signInCommand)?  signedOut,TResult Function( String provider)?  httpKeyMissing,TResult Function()?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TransportReady() when ready != null:
return ready();case TransportNotInstalled() when notInstalled != null:
return notInstalled(_that.provider);case TransportSignedOut() when signedOut != null:
return signedOut(_that.provider,_that.signInCommand);case TransportHttpKeyMissing() when httpKeyMissing != null:
return httpKeyMissing(_that.provider);case TransportUnknown() when unknown != null:
return unknown();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ready,required TResult Function( String provider)  notInstalled,required TResult Function( String provider,  String signInCommand)  signedOut,required TResult Function( String provider)  httpKeyMissing,required TResult Function()  unknown,}) {final _that = this;
switch (_that) {
case TransportReady():
return ready();case TransportNotInstalled():
return notInstalled(_that.provider);case TransportSignedOut():
return signedOut(_that.provider,_that.signInCommand);case TransportHttpKeyMissing():
return httpKeyMissing(_that.provider);case TransportUnknown():
return unknown();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ready,TResult? Function( String provider)?  notInstalled,TResult? Function( String provider,  String signInCommand)?  signedOut,TResult? Function( String provider)?  httpKeyMissing,TResult? Function()?  unknown,}) {final _that = this;
switch (_that) {
case TransportReady() when ready != null:
return ready();case TransportNotInstalled() when notInstalled != null:
return notInstalled(_that.provider);case TransportSignedOut() when signedOut != null:
return signedOut(_that.provider,_that.signInCommand);case TransportHttpKeyMissing() when httpKeyMissing != null:
return httpKeyMissing(_that.provider);case TransportUnknown() when unknown != null:
return unknown();case _:
  return null;

}
}

}

/// @nodoc


class TransportReady implements TransportReadiness {
  const TransportReady();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransportReady);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransportReadiness.ready()';
}


}




/// @nodoc


class TransportNotInstalled implements TransportReadiness {
  const TransportNotInstalled({required this.provider});
  

 final  String provider;

/// Create a copy of TransportReadiness
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransportNotInstalledCopyWith<TransportNotInstalled> get copyWith => _$TransportNotInstalledCopyWithImpl<TransportNotInstalled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransportNotInstalled&&(identical(other.provider, provider) || other.provider == provider));
}


@override
int get hashCode => Object.hash(runtimeType,provider);

@override
String toString() {
  return 'TransportReadiness.notInstalled(provider: $provider)';
}


}

/// @nodoc
abstract mixin class $TransportNotInstalledCopyWith<$Res> implements $TransportReadinessCopyWith<$Res> {
  factory $TransportNotInstalledCopyWith(TransportNotInstalled value, $Res Function(TransportNotInstalled) _then) = _$TransportNotInstalledCopyWithImpl;
@useResult
$Res call({
 String provider
});




}
/// @nodoc
class _$TransportNotInstalledCopyWithImpl<$Res>
    implements $TransportNotInstalledCopyWith<$Res> {
  _$TransportNotInstalledCopyWithImpl(this._self, this._then);

  final TransportNotInstalled _self;
  final $Res Function(TransportNotInstalled) _then;

/// Create a copy of TransportReadiness
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? provider = null,}) {
  return _then(TransportNotInstalled(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TransportSignedOut implements TransportReadiness {
  const TransportSignedOut({required this.provider, required this.signInCommand});
  

 final  String provider;
 final  String signInCommand;

/// Create a copy of TransportReadiness
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransportSignedOutCopyWith<TransportSignedOut> get copyWith => _$TransportSignedOutCopyWithImpl<TransportSignedOut>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransportSignedOut&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.signInCommand, signInCommand) || other.signInCommand == signInCommand));
}


@override
int get hashCode => Object.hash(runtimeType,provider,signInCommand);

@override
String toString() {
  return 'TransportReadiness.signedOut(provider: $provider, signInCommand: $signInCommand)';
}


}

/// @nodoc
abstract mixin class $TransportSignedOutCopyWith<$Res> implements $TransportReadinessCopyWith<$Res> {
  factory $TransportSignedOutCopyWith(TransportSignedOut value, $Res Function(TransportSignedOut) _then) = _$TransportSignedOutCopyWithImpl;
@useResult
$Res call({
 String provider, String signInCommand
});




}
/// @nodoc
class _$TransportSignedOutCopyWithImpl<$Res>
    implements $TransportSignedOutCopyWith<$Res> {
  _$TransportSignedOutCopyWithImpl(this._self, this._then);

  final TransportSignedOut _self;
  final $Res Function(TransportSignedOut) _then;

/// Create a copy of TransportReadiness
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? signInCommand = null,}) {
  return _then(TransportSignedOut(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,signInCommand: null == signInCommand ? _self.signInCommand : signInCommand // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TransportHttpKeyMissing implements TransportReadiness {
  const TransportHttpKeyMissing({required this.provider});
  

 final  String provider;

/// Create a copy of TransportReadiness
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransportHttpKeyMissingCopyWith<TransportHttpKeyMissing> get copyWith => _$TransportHttpKeyMissingCopyWithImpl<TransportHttpKeyMissing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransportHttpKeyMissing&&(identical(other.provider, provider) || other.provider == provider));
}


@override
int get hashCode => Object.hash(runtimeType,provider);

@override
String toString() {
  return 'TransportReadiness.httpKeyMissing(provider: $provider)';
}


}

/// @nodoc
abstract mixin class $TransportHttpKeyMissingCopyWith<$Res> implements $TransportReadinessCopyWith<$Res> {
  factory $TransportHttpKeyMissingCopyWith(TransportHttpKeyMissing value, $Res Function(TransportHttpKeyMissing) _then) = _$TransportHttpKeyMissingCopyWithImpl;
@useResult
$Res call({
 String provider
});




}
/// @nodoc
class _$TransportHttpKeyMissingCopyWithImpl<$Res>
    implements $TransportHttpKeyMissingCopyWith<$Res> {
  _$TransportHttpKeyMissingCopyWithImpl(this._self, this._then);

  final TransportHttpKeyMissing _self;
  final $Res Function(TransportHttpKeyMissing) _then;

/// Create a copy of TransportReadiness
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? provider = null,}) {
  return _then(TransportHttpKeyMissing(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TransportUnknown implements TransportReadiness {
  const TransportUnknown();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransportUnknown);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransportReadiness.unknown()';
}


}




// dart format on
