import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/ai_model.dart';
import '../../data/models/chat_session.dart';
import '../../data/models/project.dart';
import '../../services/project/project_service.dart';
import '../../services/session/session_service.dart';

part 'project_sidebar_actions.g.dart';

/// Command notifier that mediates every imperative project/session mutation
/// triggered from the sidebar. Widgets never reach into [ProjectService] or
/// [SessionService] directly — they call methods here instead.
@Riverpod(keepAlive: true)
class ProjectSidebarActions extends _$ProjectSidebarActions {
  @override
  void build() {}

  ProjectService get _projects => ref.read(projectServiceProvider);
  SessionService get _sessions => ref.read(sessionServiceProvider);

  // ── Project mutations ──────────────────────────────────────────────────────

  Future<void> refreshProjectStatuses() => _projects.refreshProjectStatuses();

  Future<void> refreshProjectStatus(String id) => _projects.refreshProjectStatus(id);

  Future<Project> addExistingFolder(String path) => _projects.addExistingFolder(path);

  Future<void> relocateProject(String id, String path) => _projects.relocateProject(id, path);

  /// Removes the project from Code Bench. If [deleteSessions] is true, all
  /// conversations linked to the project are deleted first.
  Future<void> removeProject(String id, {bool deleteSessions = false}) async {
    if (deleteSessions) {
      final sessions = await _sessions.getSessionsByProject(id);
      for (final s in sessions) {
        await _sessions.deleteSession(s.sessionId);
      }
    }
    await _projects.removeProject(id);
  }

  // ── Session mutations ──────────────────────────────────────────────────────

  Future<String> createSession({required AIModel model, required String projectId}) =>
      _sessions.createSession(model: model, projectId: projectId);

  Future<void> archiveSession(String id) => _sessions.archiveSession(id);

  Future<void> deleteSession(String id) => _sessions.deleteSession(id);

  Future<void> updateSessionTitle(String id, String title) => _sessions.updateSessionTitle(id, title);

  Future<List<ChatSession>> getSessionsByProject(String projectId) => _sessions.getSessionsByProject(projectId);
}
