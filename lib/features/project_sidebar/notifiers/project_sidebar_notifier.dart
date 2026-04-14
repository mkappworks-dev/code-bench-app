import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/project/models/project.dart';
import '../../../services/project/project_service.dart';

part 'project_sidebar_notifier.g.dart';

/// Currently active project ID
@Riverpod(keepAlive: true)
class ActiveProjectIdNotifier extends _$ActiveProjectIdNotifier {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

/// Persisted worktree path overrides: sessionId → effective filesystem path.
///
/// When the user switches to a worktree via the branch picker, the entry
/// for the active session is stored here and written through to SharedPreferences
/// so each thread remembers its worktree context across app restarts.
/// Cleared when the user switches back to the main working tree.
@Riverpod(keepAlive: true)
class ActiveWorktreePathNotifier extends _$ActiveWorktreePathNotifier {
  static const _prefsKey = 'worktree_path_overrides';

  @override
  Map<String, String> build() {
    _loadFromPrefs();
    return {};
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      state = Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (e) {
      dLog('[ActiveWorktreePathNotifier] failed to deserialize persisted paths, clearing corrupt data: $e');
      await prefs.remove(_prefsKey);
    }
  }

  Future<void> setPath(String sessionId, String worktreePath) async {
    state = {...state, sessionId: worktreePath};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state));
  }

  Future<void> clearPath(String sessionId) async {
    state = {...state}..remove(sessionId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state));
  }
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
  final svc = ref.watch(projectServiceProvider);
  return svc.watchAllProjects();
}

/// Derives the currently active [Project] from [activeProjectIdProvider] and
/// [projectsProvider]. Returns null while projects are loading or if no project
/// is selected. Use `ref.watch` in build for reactivity; `ref.read` in handlers.
@riverpod
Project? activeProject(Ref ref) {
  final projectId = ref.watch(activeProjectIdProvider);
  final projects = ref.watch(projectsProvider).value ?? const [];
  return projects.firstWhereOrNull((p) => p.id == projectId);
}
