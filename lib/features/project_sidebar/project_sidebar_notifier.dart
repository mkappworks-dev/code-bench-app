import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/project.dart';
import '../../services/project/project_service.dart';

part 'project_sidebar_notifier.g.dart';

/// Currently active project ID
@Riverpod(keepAlive: true)
class ActiveProjectId extends _$ActiveProjectId {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

/// Set of expanded project IDs in the sidebar
@Riverpod(keepAlive: true)
class ExpandedProjectIds extends _$ExpandedProjectIds {
  @override
  Set<String> build() => {};

  void toggle(String projectId) {
    if (state.contains(projectId)) {
      state = {...state}..remove(projectId);
    } else {
      state = {...state, projectId};
    }
  }

  void expand(String projectId) {
    state = {...state, projectId};
  }

  void collapse(String projectId) {
    state = {...state}..remove(projectId);
  }
}

/// Watch all projects from the database
@riverpod
Stream<List<Project>> projects(Ref ref) {
  final service = ref.watch(projectServiceProvider);
  return service.watchAllProjects();
}
