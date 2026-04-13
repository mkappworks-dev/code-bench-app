import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_project.freezed.dart';
part 'workspace_project.g.dart';

@freezed
abstract class WorkspaceProject with _$WorkspaceProject {
  const factory WorkspaceProject({
    required String id,
    required String name,
    String? localPath,
    String? repositoryId,
    String? activeBranch,
    @Default([]) List<String> sessionIds,
    DateTime? lastOpenedAt,
  }) = _WorkspaceProject;

  factory WorkspaceProject.fromJson(Map<String, dynamic> json) => _$WorkspaceProjectFromJson(json);
}
