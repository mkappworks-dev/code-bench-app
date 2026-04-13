import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_action.dart';

part 'project.freezed.dart';
part 'project.g.dart';

enum ProjectStatus {
  /// The project folder exists on disk and is usable for all operations.
  available,

  /// The project folder is missing from disk. The project row stays in the
  /// DB (along with any linked chat sessions) but all write operations are
  /// blocked until the user either Relocates or Removes it.
  missing,
}

@freezed
abstract class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    required String path,
    required DateTime createdAt,
    @Default(0) int sortOrder,
    @Default([]) List<ProjectAction> actions,
    @Default(ProjectStatus.available) ProjectStatus status,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
}
