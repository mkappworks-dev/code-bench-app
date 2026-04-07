import 'package:freezed_annotation/freezed_annotation.dart';

part 'repository.freezed.dart';
part 'repository.g.dart';

@freezed
class Repository with _$Repository {
  const factory Repository({
    required int id,
    required String name,
    required String owner,
    required String defaultBranch,
    @Default(false) bool isPrivate,
    String? language,
    @Default(0) int starCount,
    String? description,
    String? htmlUrl,
    DateTime? updatedAt,
  }) = _Repository;

  factory Repository.fromJson(Map<String, dynamic> json) =>
      _$RepositoryFromJson(json);
}

@freezed
class GitHubAccount with _$GitHubAccount {
  const factory GitHubAccount({
    required String username,
    required String avatarUrl,
    String? email,
    @Default([]) List<String> scopes,
    String? name,
  }) = _GitHubAccount;

  factory GitHubAccount.fromJson(Map<String, dynamic> json) =>
      _$GitHubAccountFromJson(json);
}

@freezed
class GitTreeItem with _$GitTreeItem {
  const factory GitTreeItem({
    required String path,
    required String type, // blob | tree
    required String sha,
    int? size,
  }) = _GitTreeItem;

  factory GitTreeItem.fromJson(Map<String, dynamic> json) =>
      _$GitTreeItemFromJson(json);
}
