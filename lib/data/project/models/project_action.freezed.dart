// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectAction {

 String get name; String get command;
/// Create a copy of ProjectAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectActionCopyWith<ProjectAction> get copyWith => _$ProjectActionCopyWithImpl<ProjectAction>(this as ProjectAction, _$identity);

  /// Serializes this ProjectAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectAction&&(identical(other.name, name) || other.name == name)&&(identical(other.command, command) || other.command == command));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,command);

@override
String toString() {
  return 'ProjectAction(name: $name, command: $command)';
}


}

/// @nodoc
abstract mixin class $ProjectActionCopyWith<$Res>  {
  factory $ProjectActionCopyWith(ProjectAction value, $Res Function(ProjectAction) _then) = _$ProjectActionCopyWithImpl;
@useResult
$Res call({
 String name, String command
});




}
/// @nodoc
class _$ProjectActionCopyWithImpl<$Res>
    implements $ProjectActionCopyWith<$Res> {
  _$ProjectActionCopyWithImpl(this._self, this._then);

  final ProjectAction _self;
  final $Res Function(ProjectAction) _then;

/// Create a copy of ProjectAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? command = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectAction].
extension ProjectActionPatterns on ProjectAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectAction() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectAction value)  $default,){
final _that = this;
switch (_that) {
case _ProjectAction():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectAction value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectAction() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String command)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectAction() when $default != null:
return $default(_that.name,_that.command);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String command)  $default,) {final _that = this;
switch (_that) {
case _ProjectAction():
return $default(_that.name,_that.command);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String command)?  $default,) {final _that = this;
switch (_that) {
case _ProjectAction() when $default != null:
return $default(_that.name,_that.command);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectAction implements ProjectAction {
  const _ProjectAction({required this.name, required this.command});
  factory _ProjectAction.fromJson(Map<String, dynamic> json) => _$ProjectActionFromJson(json);

@override final  String name;
@override final  String command;

/// Create a copy of ProjectAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectActionCopyWith<_ProjectAction> get copyWith => __$ProjectActionCopyWithImpl<_ProjectAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectAction&&(identical(other.name, name) || other.name == name)&&(identical(other.command, command) || other.command == command));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,command);

@override
String toString() {
  return 'ProjectAction(name: $name, command: $command)';
}


}

/// @nodoc
abstract mixin class _$ProjectActionCopyWith<$Res> implements $ProjectActionCopyWith<$Res> {
  factory _$ProjectActionCopyWith(_ProjectAction value, $Res Function(_ProjectAction) _then) = __$ProjectActionCopyWithImpl;
@override @useResult
$Res call({
 String name, String command
});




}
/// @nodoc
class __$ProjectActionCopyWithImpl<$Res>
    implements _$ProjectActionCopyWith<$Res> {
  __$ProjectActionCopyWithImpl(this._self, this._then);

  final _ProjectAction _self;
  final $Res Function(_ProjectAction) _then;

/// Create a copy of ProjectAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? command = null,}) {
  return _then(_ProjectAction(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
