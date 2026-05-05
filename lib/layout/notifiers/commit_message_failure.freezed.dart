// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commit_message_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommitMessageFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommitMessageFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommitMessageFailure()';
}


}

/// @nodoc
class $CommitMessageFailureCopyWith<$Res>  {
$CommitMessageFailureCopyWith(CommitMessageFailure _, $Res Function(CommitMessageFailure) __);
}


/// Adds pattern-matching-related methods to [CommitMessageFailure].
extension CommitMessageFailurePatterns on CommitMessageFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CommitMessageUnavailable value)?  commitMessageUnavailable,TResult Function( CommitMessageUnknown value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CommitMessageUnavailable() when commitMessageUnavailable != null:
return commitMessageUnavailable(_that);case CommitMessageUnknown() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CommitMessageUnavailable value)  commitMessageUnavailable,required TResult Function( CommitMessageUnknown value)  unknown,}){
final _that = this;
switch (_that) {
case CommitMessageUnavailable():
return commitMessageUnavailable(_that);case CommitMessageUnknown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CommitMessageUnavailable value)?  commitMessageUnavailable,TResult? Function( CommitMessageUnknown value)?  unknown,}){
final _that = this;
switch (_that) {
case CommitMessageUnavailable() when commitMessageUnavailable != null:
return commitMessageUnavailable(_that);case CommitMessageUnknown() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  commitMessageUnavailable,TResult Function( Object error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CommitMessageUnavailable() when commitMessageUnavailable != null:
return commitMessageUnavailable();case CommitMessageUnknown() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  commitMessageUnavailable,required TResult Function( Object error)  unknown,}) {final _that = this;
switch (_that) {
case CommitMessageUnavailable():
return commitMessageUnavailable();case CommitMessageUnknown():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  commitMessageUnavailable,TResult? Function( Object error)?  unknown,}) {final _that = this;
switch (_that) {
case CommitMessageUnavailable() when commitMessageUnavailable != null:
return commitMessageUnavailable();case CommitMessageUnknown() when unknown != null:
return unknown(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class CommitMessageUnavailable implements CommitMessageFailure {
  const CommitMessageUnavailable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommitMessageUnavailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommitMessageFailure.commitMessageUnavailable()';
}


}




/// @nodoc


class CommitMessageUnknown implements CommitMessageFailure {
  const CommitMessageUnknown(this.error);
  

 final  Object error;

/// Create a copy of CommitMessageFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommitMessageUnknownCopyWith<CommitMessageUnknown> get copyWith => _$CommitMessageUnknownCopyWithImpl<CommitMessageUnknown>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommitMessageUnknown&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'CommitMessageFailure.unknown(error: $error)';
}


}

/// @nodoc
abstract mixin class $CommitMessageUnknownCopyWith<$Res> implements $CommitMessageFailureCopyWith<$Res> {
  factory $CommitMessageUnknownCopyWith(CommitMessageUnknown value, $Res Function(CommitMessageUnknown) _then) = _$CommitMessageUnknownCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$CommitMessageUnknownCopyWithImpl<$Res>
    implements $CommitMessageUnknownCopyWith<$Res> {
  _$CommitMessageUnknownCopyWithImpl(this._self, this._then);

  final CommitMessageUnknown _self;
  final $Res Function(CommitMessageUnknown) _then;

/// Create a copy of CommitMessageFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(CommitMessageUnknown(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
