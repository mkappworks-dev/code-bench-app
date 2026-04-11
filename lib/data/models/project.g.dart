// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Project _$ProjectFromJson(Map<String, dynamic> json) => _Project(
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
  status: $enumDecodeNullable(_$ProjectStatusEnumMap, json['status']) ?? ProjectStatus.available,
);

Map<String, dynamic> _$ProjectToJson(_Project instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'path': instance.path,
  'isGit': instance.isGit,
  'currentBranch': instance.currentBranch,
  'createdAt': instance.createdAt.toIso8601String(),
  'sortOrder': instance.sortOrder,
  'actions': instance.actions,
  'status': _$ProjectStatusEnumMap[instance.status]!,
};

const _$ProjectStatusEnumMap = {ProjectStatus.available: 'available', ProjectStatus.missing: 'missing'};
