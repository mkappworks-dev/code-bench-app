// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AIModel {

 String get id; AIProvider get provider; String get name; String get modelId; String? get endpoint; int get contextWindow; bool get supportsStreaming; bool get isDefault;
/// Create a copy of AIModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AIModelCopyWith<AIModel> get copyWith => _$AIModelCopyWithImpl<AIModel>(this as AIModel, _$identity);

  /// Serializes this AIModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AIModel&&(identical(other.id, id) || other.id == id)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.name, name) || other.name == name)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.contextWindow, contextWindow) || other.contextWindow == contextWindow)&&(identical(other.supportsStreaming, supportsStreaming) || other.supportsStreaming == supportsStreaming)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,provider,name,modelId,endpoint,contextWindow,supportsStreaming,isDefault);

@override
String toString() {
  return 'AIModel(id: $id, provider: $provider, name: $name, modelId: $modelId, endpoint: $endpoint, contextWindow: $contextWindow, supportsStreaming: $supportsStreaming, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class $AIModelCopyWith<$Res>  {
  factory $AIModelCopyWith(AIModel value, $Res Function(AIModel) _then) = _$AIModelCopyWithImpl;
@useResult
$Res call({
 String id, AIProvider provider, String name, String modelId, String? endpoint, int contextWindow, bool supportsStreaming, bool isDefault
});




}
/// @nodoc
class _$AIModelCopyWithImpl<$Res>
    implements $AIModelCopyWith<$Res> {
  _$AIModelCopyWithImpl(this._self, this._then);

  final AIModel _self;
  final $Res Function(AIModel) _then;

/// Create a copy of AIModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? provider = null,Object? name = null,Object? modelId = null,Object? endpoint = freezed,Object? contextWindow = null,Object? supportsStreaming = null,Object? isDefault = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AIProvider,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,endpoint: freezed == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String?,contextWindow: null == contextWindow ? _self.contextWindow : contextWindow // ignore: cast_nullable_to_non_nullable
as int,supportsStreaming: null == supportsStreaming ? _self.supportsStreaming : supportsStreaming // ignore: cast_nullable_to_non_nullable
as bool,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AIModel].
extension AIModelPatterns on AIModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AIModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AIModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AIModel value)  $default,){
final _that = this;
switch (_that) {
case _AIModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AIModel value)?  $default,){
final _that = this;
switch (_that) {
case _AIModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AIProvider provider,  String name,  String modelId,  String? endpoint,  int contextWindow,  bool supportsStreaming,  bool isDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AIModel() when $default != null:
return $default(_that.id,_that.provider,_that.name,_that.modelId,_that.endpoint,_that.contextWindow,_that.supportsStreaming,_that.isDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AIProvider provider,  String name,  String modelId,  String? endpoint,  int contextWindow,  bool supportsStreaming,  bool isDefault)  $default,) {final _that = this;
switch (_that) {
case _AIModel():
return $default(_that.id,_that.provider,_that.name,_that.modelId,_that.endpoint,_that.contextWindow,_that.supportsStreaming,_that.isDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AIProvider provider,  String name,  String modelId,  String? endpoint,  int contextWindow,  bool supportsStreaming,  bool isDefault)?  $default,) {final _that = this;
switch (_that) {
case _AIModel() when $default != null:
return $default(_that.id,_that.provider,_that.name,_that.modelId,_that.endpoint,_that.contextWindow,_that.supportsStreaming,_that.isDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AIModel implements AIModel {
  const _AIModel({required this.id, required this.provider, required this.name, required this.modelId, this.endpoint, this.contextWindow = 128000, this.supportsStreaming = true, this.isDefault = false});
  factory _AIModel.fromJson(Map<String, dynamic> json) => _$AIModelFromJson(json);

@override final  String id;
@override final  AIProvider provider;
@override final  String name;
@override final  String modelId;
@override final  String? endpoint;
@override@JsonKey() final  int contextWindow;
@override@JsonKey() final  bool supportsStreaming;
@override@JsonKey() final  bool isDefault;

/// Create a copy of AIModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AIModelCopyWith<_AIModel> get copyWith => __$AIModelCopyWithImpl<_AIModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AIModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AIModel&&(identical(other.id, id) || other.id == id)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.name, name) || other.name == name)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.contextWindow, contextWindow) || other.contextWindow == contextWindow)&&(identical(other.supportsStreaming, supportsStreaming) || other.supportsStreaming == supportsStreaming)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,provider,name,modelId,endpoint,contextWindow,supportsStreaming,isDefault);

@override
String toString() {
  return 'AIModel(id: $id, provider: $provider, name: $name, modelId: $modelId, endpoint: $endpoint, contextWindow: $contextWindow, supportsStreaming: $supportsStreaming, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class _$AIModelCopyWith<$Res> implements $AIModelCopyWith<$Res> {
  factory _$AIModelCopyWith(_AIModel value, $Res Function(_AIModel) _then) = __$AIModelCopyWithImpl;
@override @useResult
$Res call({
 String id, AIProvider provider, String name, String modelId, String? endpoint, int contextWindow, bool supportsStreaming, bool isDefault
});




}
/// @nodoc
class __$AIModelCopyWithImpl<$Res>
    implements _$AIModelCopyWith<$Res> {
  __$AIModelCopyWithImpl(this._self, this._then);

  final _AIModel _self;
  final $Res Function(_AIModel) _then;

/// Create a copy of AIModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? provider = null,Object? name = null,Object? modelId = null,Object? endpoint = freezed,Object? contextWindow = null,Object? supportsStreaming = null,Object? isDefault = null,}) {
  return _then(_AIModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AIProvider,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,endpoint: freezed == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String?,contextWindow: null == contextWindow ? _self.contextWindow : contextWindow // ignore: cast_nullable_to_non_nullable
as int,supportsStreaming: null == supportsStreaming ? _self.supportsStreaming : supportsStreaming // ignore: cast_nullable_to_non_nullable
as bool,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
