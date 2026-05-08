import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/shared/ai_model.dart';
import '../../../data/session/models/chat_session.dart';
import '../../../data/project/models/project_action.dart';
import '../../chat/notifiers/chat_notifier.dart';
import '../../git/notifiers/git_live_state_notifier.dart';
import 'project_sidebar_notifier.dart';
import '../../../services/project/project_service.dart';
import '../../../services/session/session_service.dart';
import 'project_sidebar_failure.dart';

part 'project_sidebar_actions.g.dart';

/// Command notifier that mediates every imperative project/session mutation
/// triggered from the sidebar. Widgets never reach into [ProjectService] or
/// [SessionService] directly — they call methods here instead.
@Riverpod(keepAlive: true)
class ProjectSidebarActions extends _$ProjectSidebarActions {
  @override
  FutureOr<void> build() {}

  ProjectService get _projects => ref.read(projectServiceProvider);
  Future<SessionService> get _sessions => ref.read(sessionServiceProvider.future);

  ProjectSidebarFailure _asFailure(Object e) => switch (e) {
    DuplicateProjectPathException(:final path) => ProjectSidebarFailure.duplicatePath(path),
    ProjectPermissionDeniedException(:final path) => ProjectSidebarFailure.permissionDenied(path),
    ArgumentError(:final message) => ProjectSidebarFailure.invalidPath(message?.toString() ?? ''),
    StorageException(:final message) => ProjectSidebarFailure.storageError(message),
    _ => ProjectSidebarFailure.unknown(e),
  };

  Future<void> refreshProjectStatuses() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await _projects.refreshProjectStatuses();
      } catch (e, st) {
        dLog('[ProjectSidebarActions] refreshProjectStatuses failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> refreshProjectStatus(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await _projects.refreshProjectStatus(id);
      } catch (e, st) {
        dLog('[ProjectSidebarActions] refreshProjectStatus($id) failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<String?> addExistingFolder(String path) async {
    state = const AsyncLoading();
    String? sessionId;
    state = await AsyncValue.guard(() async {
      try {
        final project = await _projects.addExistingFolder(path);
        final model = ref.read(selectedModelProvider);
        sessionId = await (await _sessions).createSession(model: model, projectId: project.id);
        ref.read(activeProjectIdProvider.notifier).set(project.id);
        ref.read(activeSessionIdProvider.notifier).set(sessionId);
      } catch (e, st) {
        dLog('[ProjectSidebarActions] addExistingFolder failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    if (state is AsyncError) return null;
    return sessionId;
  }

  Future<void> relocateProject(String id, String path) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await _projects.relocateProject(id, path);
      } catch (e, st) {
        dLog('[ProjectSidebarActions] relocateProject failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> updateProjectActions(String id, List<ProjectAction> actions) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await _projects.updateProjectActions(id, actions);
      } catch (e, st) {
        dLog('[ProjectSidebarActions] updateProjectActions failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  /// Removes the project from Code Bench. If [deleteSessions] is true, all
  /// sessions linked to the project (archived AND active) are deleted first.
  /// When the active project is being removed, also clears the active session
  /// and project ids so the chat view falls back to its empty state.
  Future<void> removeProject(String id, {bool deleteSessions = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        sLog('[ProjectSidebarActions] removeProject id=$id deleteSessions=$deleteSessions');
        // Clear active pointers before any DB write — if the cascade fails
        // partway, the chat view must not be left mounted on a session whose
        // row may already be gone.
        if (ref.read(activeProjectIdProvider) == id) {
          ref.read(activeSessionIdProvider.notifier).set(null);
          ref.read(activeProjectIdProvider.notifier).set(null);
        }
        if (deleteSessions) {
          await (await _sessions).deleteSessionsByProject(id);
        }
        await _projects.removeProject(id);
      } catch (e, st) {
        dLog('[ProjectSidebarActions] removeProject failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  /// Invalidates all cached git state for [projectPath].
  ///
  /// Call this after any in-app git mutation (commit, push, pull, checkout,
  /// init-git, create-branch). Widgets must not call [ref.invalidate] on git
  /// providers directly — that would couple them to the provider topology.
  void refreshGitState(String projectPath) {
    ref.invalidate(gitLiveStateProvider(projectPath));
    ref.invalidate(behindCountProvider(projectPath));
  }

  /// Switches the git context for the active session to [worktreePath].
  ///
  /// Persists the override keyed by session ID so each thread remembers its
  /// worktree context across app restarts.
  ///
  /// If [worktreePath] equals the project's own stored path the override is
  /// cleared, returning to the main working tree.
  Future<void> switchWorktreePath(String worktreePath) async {
    final sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) return;
    final project = ref.read(activeProjectProvider);
    if (project == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        if (worktreePath == project.path) {
          await ref.read(activeWorktreePathProvider.notifier).clearPath(sessionId);
        } else {
          await ref.read(activeWorktreePathProvider.notifier).setPath(sessionId, worktreePath);
        }
      } catch (e, st) {
        dLog('[ProjectSidebarActions] switchWorktreePath failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  /// Returns `true` when the folder at [path] currently exists on disk.
  /// Used by widgets that need a fast availability check without async I/O.
  bool projectExistsOnDisk(String path) => _projects.projectExistsOnDisk(path);

  /// Resolves [path] to its canonical real path and confirms it is a
  /// directory. Returns the resolved path on success, or `null` when the
  /// path cannot be resolved — error is surfaced via [state] as a
  /// [ProjectSidebarInvalidPath] failure so widgets can react via `ref.listen`.
  Future<String?> resolveDroppedDirectory(String path) async {
    state = const AsyncLoading();
    String? resolved;
    state = await AsyncValue.guard(() async {
      try {
        resolved = _projects.resolveDroppedDirectory(path);
      } catch (e, st) {
        dLog('[ProjectSidebarActions] resolveDroppedDirectory failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return resolved;
  }

  Future<String> createSession({required AIModel model, required String projectId}) async {
    state = const AsyncLoading();
    late String sessionId;
    state = await AsyncValue.guard(() async {
      try {
        sessionId = await (await _sessions).createSession(model: model, projectId: projectId);
      } catch (e, st) {
        dLog('[ProjectSidebarActions] createSession failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    if (state is AsyncError) throw (state as AsyncError).error;
    return sessionId;
  }

  Future<void> archiveSession(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await (await _sessions).archiveSession(id);
        if (ref.read(activeSessionIdProvider) == id) {
          ref.read(activeSessionIdProvider.notifier).set(null);
        }
      } catch (e, st) {
        dLog('[ProjectSidebarActions] archiveSession failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  /// Archives every active session for [projectId] in a single DB transaction.
  /// Archived sessions for the project are unaffected. Clears the active
  /// session id when the active session is among the archived ones.
  Future<void> archiveAllSessionsForProject(String projectId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final activeId = ref.read(activeSessionIdProvider);
        final archived = await (await _sessions).archiveActiveSessionsByProject(projectId);
        if (activeId != null && archived.contains(activeId)) {
          ref.read(activeSessionIdProvider.notifier).set(null);
        }
      } catch (e, st) {
        dLog('[ProjectSidebarActions] archiveAllSessionsForProject failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  /// Permanently deletes every active session for [projectId] in a single DB
  /// transaction. Archived sessions are unaffected. Clears the active session
  /// id when the active session is among the deleted ones.
  Future<void> deleteAllSessionsForProject(String projectId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        sLog('[ProjectSidebarActions] deleteAllSessionsForProject projectId=$projectId');
        final activeId = ref.read(activeSessionIdProvider);
        final deleted = await (await _sessions).deleteActiveSessionsByProject(projectId);
        if (activeId != null && deleted.contains(activeId)) {
          ref.read(activeSessionIdProvider.notifier).set(null);
        }
      } catch (e, st) {
        dLog('[ProjectSidebarActions] deleteAllSessionsForProject failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> deleteSession(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await (await _sessions).deleteSession(id);
        if (ref.read(activeSessionIdProvider) == id) {
          ref.read(activeSessionIdProvider.notifier).set(null);
        }
      } catch (e, st) {
        dLog('[ProjectSidebarActions] deleteSession failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> updateSessionTitle(String id, String title) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await (await _sessions).updateSessionTitle(id, title);
      } catch (e, st) {
        dLog('[ProjectSidebarActions] updateSessionTitle failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  /// Non-throwing read of the active session count for [projectId]. Returns 0
  /// on any error so widgets can show "did not load" UI without needing
  /// try/catch. Widgets that need this count (e.g. DeleteAllConversationsDialog)
  /// rely on the safe default — a failed query simply hides the cascade
  /// option.
  Future<int> fetchSessionCount(String projectId) async {
    try {
      final sessions = await (await _sessions).getSessionsByProject(projectId);
      return sessions.length;
    } catch (e, st) {
      dLog('[ProjectSidebarActions] fetchSessionCount failed: $e\n$st');
      return 0;
    }
  }

  Future<({int active, int archived})> fetchSessionCounts(String projectId) async {
    try {
      final svc = await _sessions;
      final active = await svc.getSessionsByProject(projectId);
      final archived = await svc.watchArchivedSessionsByProject(projectId).first;
      return (active: active.length, archived: archived.length);
    } catch (e, st) {
      dLog('[ProjectSidebarActions] fetchSessionCounts failed: $e\n$st');
      return (active: 0, archived: 0);
    }
  }

  Future<List<ChatSession>> getSessionsByProject(String projectId) async {
    state = const AsyncLoading();
    late List<ChatSession> sessions;
    state = await AsyncValue.guard(() async {
      try {
        sessions = await (await _sessions).getSessionsByProject(projectId);
      } catch (e, st) {
        dLog('[ProjectSidebarActions] getSessionsByProject failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    if (state is AsyncError) throw (state as AsyncError).error;
    return sessions;
  }

  /// Forces [archivedSessionsProvider] to re-fetch from the DB.
  ///
  /// Widgets must not call [ref.invalidate] on [archivedSessionsProvider]
  /// directly — use this method so the provider topology stays encapsulated.
  void refreshArchivedSessions() => ref.invalidate(archivedSessionsProvider);
}
