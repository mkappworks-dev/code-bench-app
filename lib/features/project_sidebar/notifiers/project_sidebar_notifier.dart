import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/project.dart';
import '../../services/project/project_service.dart';

part 'project_sidebar_notifier.g.dart';

/// Currently active project ID
@Riverpod(keepAlive: true)
class ActiveProjectIdNotifier extends _$ActiveProjectIdNotifier {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

/// Set of expanded project IDs in the sidebar
@Riverpod(keepAlive: true)
class ExpandedProjectIdsNotifier extends _$ExpandedProjectIdsNotifier {
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

enum ProjectSortOrder { lastMessage, createdAt, manual }

enum ThreadSortOrder { lastMessage, createdAt }

class ProjectSortState {
  const ProjectSortState({required this.projectSort, required this.threadSort});
  final ProjectSortOrder projectSort;
  final ThreadSortOrder threadSort;
  ProjectSortState copyWith({ProjectSortOrder? projectSort, ThreadSortOrder? threadSort}) =>
      ProjectSortState(projectSort: projectSort ?? this.projectSort, threadSort: threadSort ?? this.threadSort);
}

@Riverpod(keepAlive: true)
class ProjectSortNotifier extends _$ProjectSortNotifier {
  static const _projectKey = 'project_sort_order';
  static const _threadKey = 'thread_sort_order';

  @override
  Future<ProjectSortState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final projectSort = ProjectSortOrder.values.firstWhere(
      (e) => e.name == prefs.getString(_projectKey),
      orElse: () => ProjectSortOrder.lastMessage,
    );
    final threadSort = ThreadSortOrder.values.firstWhere(
      (e) => e.name == prefs.getString(_threadKey),
      orElse: () => ThreadSortOrder.lastMessage,
    );
    return ProjectSortState(projectSort: projectSort, threadSort: threadSort);
  }

  Future<void> setProjectSort(ProjectSortOrder order) async {
    final current = state.value ?? await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_projectKey, order.name);
    state = AsyncData(current.copyWith(projectSort: order));
  }

  Future<void> setThreadSort(ThreadSortOrder order) async {
    final current = state.value ?? await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_threadKey, order.name);
    state = AsyncData(current.copyWith(threadSort: order));
  }
}

/// Watch all projects from the database
@riverpod
Stream<List<Project>> projects(Ref ref) {
  final service = ref.watch(projectServiceProvider);
  return service.watchAllProjects();
}
