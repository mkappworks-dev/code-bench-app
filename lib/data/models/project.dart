import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_action.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
abstract class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    required String path,
    @Default(false) bool isGit,
    String? currentBranch,
    required DateTime createdAt,
    @Default(0) int sortOrder,
    @Default([]) List<ProjectAction> actions,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
}
