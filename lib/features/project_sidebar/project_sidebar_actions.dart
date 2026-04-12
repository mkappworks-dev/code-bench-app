import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/ai_model.dart';
import '../../data/models/chat_session.dart';
import '../../data/models/project.dart';
import '../../data/models/project_action.dart';
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

  Future<void> updateProjectActions(String id, List<ProjectAction> actions) =>
      _projects.updateProjectActions(id, actions);

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

  // ── Filesystem helpers ─────────────────────────────────────────────────────

  /// Returns `true` when the folder at [path] currently exists on disk.
  /// Used by widgets that need a fast availability check without async I/O.
  bool projectExistsOnDisk(String path) => Directory(path).existsSync();

  /// Resolves [path] to its canonical real path and confirms it is a
  /// directory. Returns the resolved path on success.
  ///
  /// Throws [ArgumentError] with a user-facing message on failure:
  /// - broken / non-existent path → `'That path could not be opened'`
  /// - resolved path is a file, not a directory → `'Please drop a folder, not a file'`
  String resolveDroppedDirectory(String path) {
    final String resolved;
    try {
      // resolveSymbolicLinksSync throws on broken or non-existent paths —
      // a dangling symlink must not become a project root.
      resolved = Directory(path).resolveSymbolicLinksSync();
    } catch (_) {
      throw ArgumentError('That path could not be opened');
    }
    if (!FileSystemEntity.isDirectorySync(resolved)) {
      throw ArgumentError('Please drop a folder, not a file');
    }
    return resolved;
  }

  // ── Session mutations ──────────────────────────────────────────────────────

  Future<String> createSession({required AIModel model, required String projectId}) =>
      _sessions.createSession(model: model, projectId: projectId);

  Future<void> archiveSession(String id) => _sessions.archiveSession(id);

  Future<void> deleteSession(String id) => _sessions.deleteSession(id);

  Future<void> updateSessionTitle(String id, String title) => _sessions.updateSessionTitle(id, title);

  Future<List<ChatSession>> getSessionsByProject(String projectId) => _sessions.getSessionsByProject(projectId);
}
