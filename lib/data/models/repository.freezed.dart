// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Repository _$RepositoryFromJson(Map<String, dynamic> json) {
  return _Repository.fromJson(json);
}

/// @nodoc
mixin _$Repository {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get owner => throw _privateConstructorUsedError;
  String get defaultBranch => throw _privateConstructorUsedError;
  bool get isPrivate => throw _privateConstructorUsedError;
  String? get language => throw _privateConstructorUsedError;
  int get starCount => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get htmlUrl => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Repository to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Repository
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RepositoryCopyWith<Repository> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RepositoryCopyWith<$Res> {
  factory $RepositoryCopyWith(
          Repository value, $Res Function(Repository) then) =
      _$RepositoryCopyWithImpl<$Res, Repository>;
  @useResult
  $Res call(
      {int id,
      String name,
      String owner,
      String defaultBranch,
      bool isPrivate,
      String? language,
      int starCount,
      String? description,
      String? htmlUrl,
      DateTime? updatedAt});
}

/// @nodoc
class _$RepositoryCopyWithImpl<$Res, $Val extends Repository>
    implements $RepositoryCopyWith<$Res> {
  _$RepositoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Repository
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? owner = null,
    Object? defaultBranch = null,
    Object? isPrivate = null,
    Object? language = freezed,
    Object? starCount = null,
    Object? description = freezed,
    Object? htmlUrl = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      defaultBranch: null == defaultBranch
          ? _value.defaultBranch
          : defaultBranch // ignore: cast_nullable_to_non_nullable
              as String,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      language: freezed == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String?,
      starCount: null == starCount
          ? _value.starCount
          : starCount // ignore: cast_nullable_to_non_nullable
              as int,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      htmlUrl: freezed == htmlUrl
          ? _value.htmlUrl
          : htmlUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RepositoryImplCopyWith<$Res>
    implements $RepositoryCopyWith<$Res> {
  factory _$$RepositoryImplCopyWith(
          _$RepositoryImpl value, $Res Function(_$RepositoryImpl) then) =
      __$$RepositoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String owner,
      String defaultBranch,
      bool isPrivate,
      String? language,
      int starCount,
      String? description,
      String? htmlUrl,
      DateTime? updatedAt});
}

/// @nodoc
class __$$RepositoryImplCopyWithImpl<$Res>
    extends _$RepositoryCopyWithImpl<$Res, _$RepositoryImpl>
    implements _$$RepositoryImplCopyWith<$Res> {
  __$$RepositoryImplCopyWithImpl(
      _$RepositoryImpl _value, $Res Function(_$RepositoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of Repository
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? owner = null,
    Object? defaultBranch = null,
    Object? isPrivate = null,
    Object? language = freezed,
    Object? starCount = null,
    Object? description = freezed,
    Object? htmlUrl = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$RepositoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      defaultBranch: null == defaultBranch
          ? _value.defaultBranch
          : defaultBranch // ignore: cast_nullable_to_non_nullable
              as String,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      language: freezed == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String?,
      starCount: null == starCount
          ? _value.starCount
          : starCount // ignore: cast_nullable_to_non_nullable
              as int,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      htmlUrl: freezed == htmlUrl
          ? _value.htmlUrl
          : htmlUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RepositoryImpl implements _Repository {
  const _$RepositoryImpl(
      {required this.id,
      required this.name,
      required this.owner,
      required this.defaultBranch,
      this.isPrivate = false,
      this.language,
      this.starCount = 0,
      this.description,
      this.htmlUrl,
      this.updatedAt});

  factory _$RepositoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$RepositoryImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String owner;
  @override
  final String defaultBranch;
  @override
  @JsonKey()
  final bool isPrivate;
  @override
  final String? language;
  @override
  @JsonKey()
  final int starCount;
  @override
  final String? description;
  @override
  final String? htmlUrl;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Repository(id: $id, name: $name, owner: $owner, defaultBranch: $defaultBranch, isPrivate: $isPrivate, language: $language, starCount: $starCount, description: $description, htmlUrl: $htmlUrl, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RepositoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.defaultBranch, defaultBranch) ||
                other.defaultBranch == defaultBranch) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.starCount, starCount) ||
                other.starCount == starCount) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, owner, defaultBranch,
      isPrivate, language, starCount, description, htmlUrl, updatedAt);

  /// Create a copy of Repository
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RepositoryImplCopyWith<_$RepositoryImpl> get copyWith =>
      __$$RepositoryImplCopyWithImpl<_$RepositoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RepositoryImplToJson(
      this,
    );
  }
}

abstract class _Repository implements Repository {
  const factory _Repository(
      {required final int id,
      required final String name,
      required final String owner,
      required final String defaultBranch,
      final bool isPrivate,
      final String? language,
      final int starCount,
      final String? description,
      final String? htmlUrl,
      final DateTime? updatedAt}) = _$RepositoryImpl;

  factory _Repository.fromJson(Map<String, dynamic> json) =
      _$RepositoryImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get owner;
  @override
  String get defaultBranch;
  @override
  bool get isPrivate;
  @override
  String? get language;
  @override
  int get starCount;
  @override
  String? get description;
  @override
  String? get htmlUrl;
  @override
  DateTime? get updatedAt;

  /// Create a copy of Repository
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RepositoryImplCopyWith<_$RepositoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GitHubAccount _$GitHubAccountFromJson(Map<String, dynamic> json) {
  return _GitHubAccount.fromJson(json);
}

/// @nodoc
mixin _$GitHubAccount {
  String get username => throw _privateConstructorUsedError;
  String get avatarUrl => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  List<String> get scopes => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;

  /// Serializes this GitHubAccount to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GitHubAccount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GitHubAccountCopyWith<GitHubAccount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GitHubAccountCopyWith<$Res> {
  factory $GitHubAccountCopyWith(
          GitHubAccount value, $Res Function(GitHubAccount) then) =
      _$GitHubAccountCopyWithImpl<$Res, GitHubAccount>;
  @useResult
  $Res call(
      {String username,
      String avatarUrl,
      String? email,
      List<String> scopes,
      String? name});
}

/// @nodoc
class _$GitHubAccountCopyWithImpl<$Res, $Val extends GitHubAccount>
    implements $GitHubAccountCopyWith<$Res> {
  _$GitHubAccountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GitHubAccount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? avatarUrl = null,
    Object? email = freezed,
    Object? scopes = null,
    Object? name = freezed,
  }) {
    return _then(_value.copyWith(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: null == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      scopes: null == scopes
          ? _value.scopes
          : scopes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GitHubAccountImplCopyWith<$Res>
    implements $GitHubAccountCopyWith<$Res> {
  factory _$$GitHubAccountImplCopyWith(
          _$GitHubAccountImpl value, $Res Function(_$GitHubAccountImpl) then) =
      __$$GitHubAccountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String username,
      String avatarUrl,
      String? email,
      List<String> scopes,
      String? name});
}

/// @nodoc
class __$$GitHubAccountImplCopyWithImpl<$Res>
    extends _$GitHubAccountCopyWithImpl<$Res, _$GitHubAccountImpl>
    implements _$$GitHubAccountImplCopyWith<$Res> {
  __$$GitHubAccountImplCopyWithImpl(
      _$GitHubAccountImpl _value, $Res Function(_$GitHubAccountImpl) _then)
      : super(_value, _then);

  /// Create a copy of GitHubAccount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? avatarUrl = null,
    Object? email = freezed,
    Object? scopes = null,
    Object? name = freezed,
  }) {
    return _then(_$GitHubAccountImpl(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: null == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      scopes: null == scopes
          ? _value._scopes
          : scopes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GitHubAccountImpl implements _GitHubAccount {
  const _$GitHubAccountImpl(
      {required this.username,
      required this.avatarUrl,
      this.email,
      final List<String> scopes = const [],
      this.name})
      : _scopes = scopes;

  factory _$GitHubAccountImpl.fromJson(Map<String, dynamic> json) =>
      _$$GitHubAccountImplFromJson(json);

  @override
  final String username;
  @override
  final String avatarUrl;
  @override
  final String? email;
  final List<String> _scopes;
  @override
  @JsonKey()
  List<String> get scopes {
    if (_scopes is EqualUnmodifiableListView) return _scopes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_scopes);
  }

  @override
  final String? name;

  @override
  String toString() {
    return 'GitHubAccount(username: $username, avatarUrl: $avatarUrl, email: $email, scopes: $scopes, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GitHubAccountImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.email, email) || other.email == email) &&
            const DeepCollectionEquality().equals(other._scopes, _scopes) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, username, avatarUrl, email,
      const DeepCollectionEquality().hash(_scopes), name);

  /// Create a copy of GitHubAccount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GitHubAccountImplCopyWith<_$GitHubAccountImpl> get copyWith =>
      __$$GitHubAccountImplCopyWithImpl<_$GitHubAccountImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GitHubAccountImplToJson(
      this,
    );
  }
}

abstract class _GitHubAccount implements GitHubAccount {
  const factory _GitHubAccount(
      {required final String username,
      required final String avatarUrl,
      final String? email,
      final List<String> scopes,
      final String? name}) = _$GitHubAccountImpl;

  factory _GitHubAccount.fromJson(Map<String, dynamic> json) =
      _$GitHubAccountImpl.fromJson;

  @override
  String get username;
  @override
  String get avatarUrl;
  @override
  String? get email;
  @override
  List<String> get scopes;
  @override
  String? get name;

  /// Create a copy of GitHubAccount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GitHubAccountImplCopyWith<_$GitHubAccountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GitTreeItem _$GitTreeItemFromJson(Map<String, dynamic> json) {
  return _GitTreeItem.fromJson(json);
}

/// @nodoc
mixin _$GitTreeItem {
  String get path => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError; // blob | tree
  String get sha => throw _privateConstructorUsedError;
  int? get size => throw _privateConstructorUsedError;

  /// Serializes this GitTreeItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GitTreeItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GitTreeItemCopyWith<GitTreeItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GitTreeItemCopyWith<$Res> {
  factory $GitTreeItemCopyWith(
          GitTreeItem value, $Res Function(GitTreeItem) then) =
      _$GitTreeItemCopyWithImpl<$Res, GitTreeItem>;
  @useResult
  $Res call({String path, String type, String sha, int? size});
}

/// @nodoc
class _$GitTreeItemCopyWithImpl<$Res, $Val extends GitTreeItem>
    implements $GitTreeItemCopyWith<$Res> {
  _$GitTreeItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GitTreeItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? type = null,
    Object? sha = null,
    Object? size = freezed,
  }) {
    return _then(_value.copyWith(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      sha: null == sha
          ? _value.sha
          : sha // ignore: cast_nullable_to_non_nullable
              as String,
      size: freezed == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GitTreeItemImplCopyWith<$Res>
    implements $GitTreeItemCopyWith<$Res> {
  factory _$$GitTreeItemImplCopyWith(
          _$GitTreeItemImpl value, $Res Function(_$GitTreeItemImpl) then) =
      __$$GitTreeItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String path, String type, String sha, int? size});
}

/// @nodoc
class __$$GitTreeItemImplCopyWithImpl<$Res>
    extends _$GitTreeItemCopyWithImpl<$Res, _$GitTreeItemImpl>
    implements _$$GitTreeItemImplCopyWith<$Res> {
  __$$GitTreeItemImplCopyWithImpl(
      _$GitTreeItemImpl _value, $Res Function(_$GitTreeItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of GitTreeItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? type = null,
    Object? sha = null,
    Object? size = freezed,
  }) {
    return _then(_$GitTreeItemImpl(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      sha: null == sha
          ? _value.sha
          : sha // ignore: cast_nullable_to_non_nullable
              as String,
      size: freezed == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GitTreeItemImpl implements _GitTreeItem {
  const _$GitTreeItemImpl(
      {required this.path, required this.type, required this.sha, this.size});

  factory _$GitTreeItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$GitTreeItemImplFromJson(json);

  @override
  final String path;
  @override
  final String type;
// blob | tree
  @override
  final String sha;
  @override
  final int? size;

  @override
  String toString() {
    return 'GitTreeItem(path: $path, type: $type, sha: $sha, size: $size)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GitTreeItemImpl &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.sha, sha) || other.sha == sha) &&
            (identical(other.size, size) || other.size == size));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, path, type, sha, size);

  /// Create a copy of GitTreeItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GitTreeItemImplCopyWith<_$GitTreeItemImpl> get copyWith =>
      __$$GitTreeItemImplCopyWithImpl<_$GitTreeItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GitTreeItemImplToJson(
      this,
    );
  }
}

abstract class _GitTreeItem implements GitTreeItem {
  const factory _GitTreeItem(
      {required final String path,
      required final String type,
      required final String sha,
      final int? size}) = _$GitTreeItemImpl;

  factory _GitTreeItem.fromJson(Map<String, dynamic> json) =
      _$GitTreeItemImpl.fromJson;

  @override
  String get path;
  @override
  String get type; // blob | tree
  @override
  String get sha;
  @override
  int? get size;

  /// Create a copy of GitTreeItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GitTreeItemImplCopyWith<_$GitTreeItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
