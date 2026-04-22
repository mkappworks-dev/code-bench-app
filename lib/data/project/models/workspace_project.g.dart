// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkspaceProject _$WorkspaceProjectFromJson(Map<String, dynamic> json) =>
    _WorkspaceProject(
      id: json['id'] as String,
      name: json['name'] as String,
      localPath: json['localPath'] as String?,
      repositoryId: json['repositoryId'] as String?,
      activeBranch: json['activeBranch'] as String?,
      sessionIds:
          (json['sessionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      lastOpenedAt: json['lastOpenedAt'] == null
          ? null
          : DateTime.parse(json['lastOpenedAt'] as String),
    );

Map<String, dynamic> _$WorkspaceProjectToJson(_WorkspaceProject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'localPath': instance.localPath,
      'repositoryId': instance.repositoryId,
      'activeBranch': instance.activeBranch,
      'sessionIds': instance.sessionIds,
      'lastOpenedAt': instance.lastOpenedAt?.toIso8601String(),
    };
