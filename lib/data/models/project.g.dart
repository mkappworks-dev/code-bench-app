// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectImpl _$$ProjectImplFromJson(Map<String, dynamic> json) => _$ProjectImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      isGit: json['isGit'] as bool? ?? false,
      currentBranch: json['currentBranch'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      actions:
          (json['actions'] as List<dynamic>?)?.map((e) => ProjectAction.fromJson(e as Map<String, dynamic>)).toList() ??
              const [],
    );

Map<String, dynamic> _$$ProjectImplToJson(_$ProjectImpl instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'path': instance.path,
      'isGit': instance.isGit,
      'currentBranch': instance.currentBranch,
      'createdAt': instance.createdAt.toIso8601String(),
      'sortOrder': instance.sortOrder,
      'actions': instance.actions,
    };
