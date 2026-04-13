// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Repository {

 int get id; String get name; String get owner; String get defaultBranch; bool get isPrivate; String? get language; int get starCount; String? get description; String? get htmlUrl; DateTime? get updatedAt;
/// Create a copy of Repository
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepositoryCopyWith<Repository> get copyWith => _$RepositoryCopyWithImpl<Repository>(this as Repository, _$identity);

  /// Serializes this Repository to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Repository&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.language, language) || other.language == language)&&(identical(other.starCount, starCount) || other.starCount == starCount)&&(identical(other.description, description) || other.description == description)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,owner,defaultBranch,isPrivate,language,starCount,description,htmlUrl,updatedAt);

@override
String toString() {
  return 'Repository(id: $id, name: $name, owner: $owner, defaultBranch: $defaultBranch, isPrivate: $isPrivate, language: $language, starCount: $starCount, description: $description, htmlUrl: $htmlUrl, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RepositoryCopyWith<$Res>  {
  factory $RepositoryCopyWith(Repository value, $Res Function(Repository) _then) = _$RepositoryCopyWithImpl;
@useResult
$Res call({
 int id, String name, String owner, String defaultBranch, bool isPrivate, String? language, int starCount, String? description, String? htmlUrl, DateTime? updatedAt
});




}
/// @nodoc
class _$RepositoryCopyWithImpl<$Res>
    implements $RepositoryCopyWith<$Res> {
  _$RepositoryCopyWithImpl(this._self, this._then);

  final Repository _self;
  final $Res Function(Repository) _then;

/// Create a copy of Repository
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? owner = null,Object? defaultBranch = null,Object? isPrivate = null,Object? language = freezed,Object? starCount = null,Object? description = freezed,Object? htmlUrl = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,defaultBranch: null == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,starCount: null == starCount ? _self.starCount : starCount // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Repository].
extension RepositoryPatterns on Repository {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Repository value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Repository() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Repository value)  $default,){
final _that = this;
switch (_that) {
case _Repository():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Repository value)?  $default,){
final _that = this;
switch (_that) {
case _Repository() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String owner,  String defaultBranch,  bool isPrivate,  String? language,  int starCount,  String? description,  String? htmlUrl,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Repository() when $default != null:
return $default(_that.id,_that.name,_that.owner,_that.defaultBranch,_that.isPrivate,_that.language,_that.starCount,_that.description,_that.htmlUrl,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String owner,  String defaultBranch,  bool isPrivate,  String? language,  int starCount,  String? description,  String? htmlUrl,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Repository():
return $default(_that.id,_that.name,_that.owner,_that.defaultBranch,_that.isPrivate,_that.language,_that.starCount,_that.description,_that.htmlUrl,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String owner,  String defaultBranch,  bool isPrivate,  String? language,  int starCount,  String? description,  String? htmlUrl,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Repository() when $default != null:
return $default(_that.id,_that.name,_that.owner,_that.defaultBranch,_that.isPrivate,_that.language,_that.starCount,_that.description,_that.htmlUrl,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Repository implements Repository {
  const _Repository({required this.id, required this.name, required this.owner, required this.defaultBranch, this.isPrivate = false, this.language, this.starCount = 0, this.description, this.htmlUrl, this.updatedAt});
  factory _Repository.fromJson(Map<String, dynamic> json) => _$RepositoryFromJson(json);

@override final  int id;
@override final  String name;
@override final  String owner;
@override final  String defaultBranch;
@override@JsonKey() final  bool isPrivate;
@override final  String? language;
@override@JsonKey() final  int starCount;
@override final  String? description;
@override final  String? htmlUrl;
@override final  DateTime? updatedAt;

/// Create a copy of Repository
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepositoryCopyWith<_Repository> get copyWith => __$RepositoryCopyWithImpl<_Repository>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RepositoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Repository&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.language, language) || other.language == language)&&(identical(other.starCount, starCount) || other.starCount == starCount)&&(identical(other.description, description) || other.description == description)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,owner,defaultBranch,isPrivate,language,starCount,description,htmlUrl,updatedAt);

@override
String toString() {
  return 'Repository(id: $id, name: $name, owner: $owner, defaultBranch: $defaultBranch, isPrivate: $isPrivate, language: $language, starCount: $starCount, description: $description, htmlUrl: $htmlUrl, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RepositoryCopyWith<$Res> implements $RepositoryCopyWith<$Res> {
  factory _$RepositoryCopyWith(_Repository value, $Res Function(_Repository) _then) = __$RepositoryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String owner, String defaultBranch, bool isPrivate, String? language, int starCount, String? description, String? htmlUrl, DateTime? updatedAt
});




}
/// @nodoc
class __$RepositoryCopyWithImpl<$Res>
    implements _$RepositoryCopyWith<$Res> {
  __$RepositoryCopyWithImpl(this._self, this._then);

  final _Repository _self;
  final $Res Function(_Repository) _then;

/// Create a copy of Repository
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? owner = null,Object? defaultBranch = null,Object? isPrivate = null,Object? language = freezed,Object? starCount = null,Object? description = freezed,Object? htmlUrl = freezed,Object? updatedAt = freezed,}) {
  return _then(_Repository(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,defaultBranch: null == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,starCount: null == starCount ? _self.starCount : starCount // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$GitHubAccount {

 String get username; String get avatarUrl; String? get email; List<String> get scopes; String? get name;
/// Create a copy of GitHubAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubAccountCopyWith<GitHubAccount> get copyWith => _$GitHubAccountCopyWithImpl<GitHubAccount>(this as GitHubAccount, _$identity);

  /// Serializes this GitHubAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubAccount&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other.scopes, scopes)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,avatarUrl,email,const DeepCollectionEquality().hash(scopes),name);

@override
String toString() {
  return 'GitHubAccount(username: $username, avatarUrl: $avatarUrl, email: $email, scopes: $scopes, name: $name)';
}


}

/// @nodoc
abstract mixin class $GitHubAccountCopyWith<$Res>  {
  factory $GitHubAccountCopyWith(GitHubAccount value, $Res Function(GitHubAccount) _then) = _$GitHubAccountCopyWithImpl;
@useResult
$Res call({
 String username, String avatarUrl, String? email, List<String> scopes, String? name
});




}
/// @nodoc
class _$GitHubAccountCopyWithImpl<$Res>
    implements $GitHubAccountCopyWith<$Res> {
  _$GitHubAccountCopyWithImpl(this._self, this._then);

  final GitHubAccount _self;
  final $Res Function(GitHubAccount) _then;

/// Create a copy of GitHubAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? avatarUrl = null,Object? email = freezed,Object? scopes = null,Object? name = freezed,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,scopes: null == scopes ? _self.scopes : scopes // ignore: cast_nullable_to_non_nullable
as List<String>,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubAccount].
extension GitHubAccountPatterns on GitHubAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubAccount value)  $default,){
final _that = this;
switch (_that) {
case _GitHubAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubAccount value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  String avatarUrl,  String? email,  List<String> scopes,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubAccount() when $default != null:
return $default(_that.username,_that.avatarUrl,_that.email,_that.scopes,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  String avatarUrl,  String? email,  List<String> scopes,  String? name)  $default,) {final _that = this;
switch (_that) {
case _GitHubAccount():
return $default(_that.username,_that.avatarUrl,_that.email,_that.scopes,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  String avatarUrl,  String? email,  List<String> scopes,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _GitHubAccount() when $default != null:
return $default(_that.username,_that.avatarUrl,_that.email,_that.scopes,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubAccount implements GitHubAccount {
  const _GitHubAccount({required this.username, required this.avatarUrl, this.email, final  List<String> scopes = const [], this.name}): _scopes = scopes;
  factory _GitHubAccount.fromJson(Map<String, dynamic> json) => _$GitHubAccountFromJson(json);

@override final  String username;
@override final  String avatarUrl;
@override final  String? email;
 final  List<String> _scopes;
@override@JsonKey() List<String> get scopes {
  if (_scopes is EqualUnmodifiableListView) return _scopes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scopes);
}

@override final  String? name;

/// Create a copy of GitHubAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubAccountCopyWith<_GitHubAccount> get copyWith => __$GitHubAccountCopyWithImpl<_GitHubAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubAccount&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other._scopes, _scopes)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,avatarUrl,email,const DeepCollectionEquality().hash(_scopes),name);

@override
String toString() {
  return 'GitHubAccount(username: $username, avatarUrl: $avatarUrl, email: $email, scopes: $scopes, name: $name)';
}


}

/// @nodoc
abstract mixin class _$GitHubAccountCopyWith<$Res> implements $GitHubAccountCopyWith<$Res> {
  factory _$GitHubAccountCopyWith(_GitHubAccount value, $Res Function(_GitHubAccount) _then) = __$GitHubAccountCopyWithImpl;
@override @useResult
$Res call({
 String username, String avatarUrl, String? email, List<String> scopes, String? name
});




}
/// @nodoc
class __$GitHubAccountCopyWithImpl<$Res>
    implements _$GitHubAccountCopyWith<$Res> {
  __$GitHubAccountCopyWithImpl(this._self, this._then);

  final _GitHubAccount _self;
  final $Res Function(_GitHubAccount) _then;

/// Create a copy of GitHubAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? avatarUrl = null,Object? email = freezed,Object? scopes = null,Object? name = freezed,}) {
  return _then(_GitHubAccount(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,scopes: null == scopes ? _self._scopes : scopes // ignore: cast_nullable_to_non_nullable
as List<String>,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GitTreeItem {

 String get path; String get type;// blob | tree
 String get sha; int? get size;
/// Create a copy of GitTreeItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitTreeItemCopyWith<GitTreeItem> get copyWith => _$GitTreeItemCopyWithImpl<GitTreeItem>(this as GitTreeItem, _$identity);

  /// Serializes this GitTreeItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitTreeItem&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,type,sha,size);

@override
String toString() {
  return 'GitTreeItem(path: $path, type: $type, sha: $sha, size: $size)';
}


}

/// @nodoc
abstract mixin class $GitTreeItemCopyWith<$Res>  {
  factory $GitTreeItemCopyWith(GitTreeItem value, $Res Function(GitTreeItem) _then) = _$GitTreeItemCopyWithImpl;
@useResult
$Res call({
 String path, String type, String sha, int? size
});




}
/// @nodoc
class _$GitTreeItemCopyWithImpl<$Res>
    implements $GitTreeItemCopyWith<$Res> {
  _$GitTreeItemCopyWithImpl(this._self, this._then);

  final GitTreeItem _self;
  final $Res Function(GitTreeItem) _then;

/// Create a copy of GitTreeItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? type = null,Object? sha = null,Object? size = freezed,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,sha: null == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [GitTreeItem].
extension GitTreeItemPatterns on GitTreeItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitTreeItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitTreeItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitTreeItem value)  $default,){
final _that = this;
switch (_that) {
case _GitTreeItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitTreeItem value)?  $default,){
final _that = this;
switch (_that) {
case _GitTreeItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String type,  String sha,  int? size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitTreeItem() when $default != null:
return $default(_that.path,_that.type,_that.sha,_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String type,  String sha,  int? size)  $default,) {final _that = this;
switch (_that) {
case _GitTreeItem():
return $default(_that.path,_that.type,_that.sha,_that.size);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String type,  String sha,  int? size)?  $default,) {final _that = this;
switch (_that) {
case _GitTreeItem() when $default != null:
return $default(_that.path,_that.type,_that.sha,_that.size);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitTreeItem implements GitTreeItem {
  const _GitTreeItem({required this.path, required this.type, required this.sha, this.size});
  factory _GitTreeItem.fromJson(Map<String, dynamic> json) => _$GitTreeItemFromJson(json);

@override final  String path;
@override final  String type;
// blob | tree
@override final  String sha;
@override final  int? size;

/// Create a copy of GitTreeItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitTreeItemCopyWith<_GitTreeItem> get copyWith => __$GitTreeItemCopyWithImpl<_GitTreeItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitTreeItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitTreeItem&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,type,sha,size);

@override
String toString() {
  return 'GitTreeItem(path: $path, type: $type, sha: $sha, size: $size)';
}


}

/// @nodoc
abstract mixin class _$GitTreeItemCopyWith<$Res> implements $GitTreeItemCopyWith<$Res> {
  factory _$GitTreeItemCopyWith(_GitTreeItem value, $Res Function(_GitTreeItem) _then) = __$GitTreeItemCopyWithImpl;
@override @useResult
$Res call({
 String path, String type, String sha, int? size
});




}
/// @nodoc
class __$GitTreeItemCopyWithImpl<$Res>
    implements _$GitTreeItemCopyWith<$Res> {
  __$GitTreeItemCopyWithImpl(this._self, this._then);

  final _GitTreeItem _self;
  final $Res Function(_GitTreeItem) _then;

/// Create a copy of GitTreeItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? type = null,Object? sha = null,Object? size = freezed,}) {
  return _then(_GitTreeItem(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,sha: null == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
