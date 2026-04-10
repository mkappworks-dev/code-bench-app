// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RepositoryImpl _$$RepositoryImplFromJson(Map<String, dynamic> json) => _$RepositoryImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      owner: json['owner'] as String,
      defaultBranch: json['defaultBranch'] as String,
      isPrivate: json['isPrivate'] as bool? ?? false,
      language: json['language'] as String?,
      starCount: (json['starCount'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      htmlUrl: json['htmlUrl'] as String?,
      updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$RepositoryImplToJson(_$RepositoryImpl instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'owner': instance.owner,
      'defaultBranch': instance.defaultBranch,
      'isPrivate': instance.isPrivate,
      'language': instance.language,
      'starCount': instance.starCount,
      'description': instance.description,
      'htmlUrl': instance.htmlUrl,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$GitHubAccountImpl _$$GitHubAccountImplFromJson(Map<String, dynamic> json) => _$GitHubAccountImpl(
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String,
      email: json['email'] as String?,
      scopes: (json['scopes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$GitHubAccountImplToJson(_$GitHubAccountImpl instance) => <String, dynamic>{
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
      'email': instance.email,
      'scopes': instance.scopes,
      'name': instance.name,
    };

_$GitTreeItemImpl _$$GitTreeItemImplFromJson(Map<String, dynamic> json) => _$GitTreeItemImpl(
      path: json['path'] as String,
      type: json['type'] as String,
      sha: json['sha'] as String,
      size: (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$GitTreeItemImplToJson(_$GitTreeItemImpl instance) => <String, dynamic>{
      'path': instance.path,
      'type': instance.type,
      'sha': instance.sha,
      'size': instance.size,
    };
