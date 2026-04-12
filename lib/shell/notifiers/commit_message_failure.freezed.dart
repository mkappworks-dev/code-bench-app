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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CommitMessageUnavailable value)?  commitMessageUnavailable,TResult Function( PrContentUnavailable value)?  prContentUnavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CommitMessageUnavailable() when commitMessageUnavailable != null:
return commitMessageUnavailable(_that);case PrContentUnavailable() when prContentUnavailable != null:
return prContentUnavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CommitMessageUnavailable value)  commitMessageUnavailable,required TResult Function( PrContentUnavailable value)  prContentUnavailable,}){
final _that = this;
switch (_that) {
case CommitMessageUnavailable():
return commitMessageUnavailable(_that);case PrContentUnavailable():
return prContentUnavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CommitMessageUnavailable value)?  commitMessageUnavailable,TResult? Function( PrContentUnavailable value)?  prContentUnavailable,}){
final _that = this;
switch (_that) {
case CommitMessageUnavailable() when commitMessageUnavailable != null:
return commitMessageUnavailable(_that);case PrContentUnavailable() when prContentUnavailable != null:
return prContentUnavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  commitMessageUnavailable,TResult Function()?  prContentUnavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CommitMessageUnavailable() when commitMessageUnavailable != null:
return commitMessageUnavailable();case PrContentUnavailable() when prContentUnavailable != null:
return prContentUnavailable();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  commitMessageUnavailable,required TResult Function()  prContentUnavailable,}) {final _that = this;
switch (_that) {
case CommitMessageUnavailable():
return commitMessageUnavailable();case PrContentUnavailable():
return prContentUnavailable();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  commitMessageUnavailable,TResult? Function()?  prContentUnavailable,}) {final _that = this;
switch (_that) {
case CommitMessageUnavailable() when commitMessageUnavailable != null:
return commitMessageUnavailable();case PrContentUnavailable() when prContentUnavailable != null:
return prContentUnavailable();case _:
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


class PrContentUnavailable implements CommitMessageFailure {
  const PrContentUnavailable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrContentUnavailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommitMessageFailure.prContentUnavailable()';
}


}




// dart format on
