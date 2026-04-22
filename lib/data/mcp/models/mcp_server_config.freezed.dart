// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mcp_server_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$McpServerConfig {

 String get id; String get name; McpTransport get transport; String? get command; List<String> get args; Map<String, String> get env; String? get url; bool get enabled;
/// Create a copy of McpServerConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServerConfigCopyWith<McpServerConfig> get copyWith => _$McpServerConfigCopyWithImpl<McpServerConfig>(this as McpServerConfig, _$identity);

  /// Serializes this McpServerConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.command, command) || other.command == command)&&const DeepCollectionEquality().equals(other.args, args)&&const DeepCollectionEquality().equals(other.env, env)&&(identical(other.url, url) || other.url == url)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,transport,command,const DeepCollectionEquality().hash(args),const DeepCollectionEquality().hash(env),url,enabled);

@override
String toString() {
  return 'McpServerConfig(id: $id, name: $name, transport: $transport, command: $command, args: $args, env: $env, url: $url, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $McpServerConfigCopyWith<$Res>  {
  factory $McpServerConfigCopyWith(McpServerConfig value, $Res Function(McpServerConfig) _then) = _$McpServerConfigCopyWithImpl;
@useResult
$Res call({
 String id, String name, McpTransport transport, String? command, List<String> args, Map<String, String> env, String? url, bool enabled
});




}
/// @nodoc
class _$McpServerConfigCopyWithImpl<$Res>
    implements $McpServerConfigCopyWith<$Res> {
  _$McpServerConfigCopyWithImpl(this._self, this._then);

  final McpServerConfig _self;
  final $Res Function(McpServerConfig) _then;

/// Create a copy of McpServerConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? transport = null,Object? command = freezed,Object? args = null,Object? env = null,Object? url = freezed,Object? enabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransport,command: freezed == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String?,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as List<String>,env: null == env ? _self.env : env // ignore: cast_nullable_to_non_nullable
as Map<String, String>,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [McpServerConfig].
extension McpServerConfigPatterns on McpServerConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpServerConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpServerConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpServerConfig value)  $default,){
final _that = this;
switch (_that) {
case _McpServerConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpServerConfig value)?  $default,){
final _that = this;
switch (_that) {
case _McpServerConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  McpTransport transport,  String? command,  List<String> args,  Map<String, String> env,  String? url,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpServerConfig() when $default != null:
return $default(_that.id,_that.name,_that.transport,_that.command,_that.args,_that.env,_that.url,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  McpTransport transport,  String? command,  List<String> args,  Map<String, String> env,  String? url,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _McpServerConfig():
return $default(_that.id,_that.name,_that.transport,_that.command,_that.args,_that.env,_that.url,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  McpTransport transport,  String? command,  List<String> args,  Map<String, String> env,  String? url,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _McpServerConfig() when $default != null:
return $default(_that.id,_that.name,_that.transport,_that.command,_that.args,_that.env,_that.url,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _McpServerConfig implements McpServerConfig {
  const _McpServerConfig({required this.id, required this.name, required this.transport, this.command, final  List<String> args = const [], final  Map<String, String> env = const {}, this.url, this.enabled = true}): _args = args,_env = env;
  factory _McpServerConfig.fromJson(Map<String, dynamic> json) => _$McpServerConfigFromJson(json);

@override final  String id;
@override final  String name;
@override final  McpTransport transport;
@override final  String? command;
 final  List<String> _args;
@override@JsonKey() List<String> get args {
  if (_args is EqualUnmodifiableListView) return _args;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_args);
}

 final  Map<String, String> _env;
@override@JsonKey() Map<String, String> get env {
  if (_env is EqualUnmodifiableMapView) return _env;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_env);
}

@override final  String? url;
@override@JsonKey() final  bool enabled;

/// Create a copy of McpServerConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpServerConfigCopyWith<_McpServerConfig> get copyWith => __$McpServerConfigCopyWithImpl<_McpServerConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$McpServerConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpServerConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.command, command) || other.command == command)&&const DeepCollectionEquality().equals(other._args, _args)&&const DeepCollectionEquality().equals(other._env, _env)&&(identical(other.url, url) || other.url == url)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,transport,command,const DeepCollectionEquality().hash(_args),const DeepCollectionEquality().hash(_env),url,enabled);

@override
String toString() {
  return 'McpServerConfig(id: $id, name: $name, transport: $transport, command: $command, args: $args, env: $env, url: $url, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$McpServerConfigCopyWith<$Res> implements $McpServerConfigCopyWith<$Res> {
  factory _$McpServerConfigCopyWith(_McpServerConfig value, $Res Function(_McpServerConfig) _then) = __$McpServerConfigCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, McpTransport transport, String? command, List<String> args, Map<String, String> env, String? url, bool enabled
});




}
/// @nodoc
class __$McpServerConfigCopyWithImpl<$Res>
    implements _$McpServerConfigCopyWith<$Res> {
  __$McpServerConfigCopyWithImpl(this._self, this._then);

  final _McpServerConfig _self;
  final $Res Function(_McpServerConfig) _then;

/// Create a copy of McpServerConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? transport = null,Object? command = freezed,Object? args = null,Object? env = null,Object? url = freezed,Object? enabled = null,}) {
  return _then(_McpServerConfig(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransport,command: freezed == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String?,args: null == args ? _self._args : args // ignore: cast_nullable_to_non_nullable
as List<String>,env: null == env ? _self._env : env // ignore: cast_nullable_to_non_nullable
as Map<String, String>,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
