import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/models/project.dart';
import '../../data/models/project_action.dart';
import 'git_detector.dart';

part 'project_service.g.dart';

@Riverpod(keepAlive: true)
ProjectService projectService(Ref ref) {
  return ProjectService(ref);
}

class ProjectService {
  ProjectService(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  Stream<List<Project>> watchAllProjects() {
    return _db.projectDao.watchAllProjects().map(
          (rows) => rows.map(_projectFromRow).toList(),
        );
  }

  Future<Project> addExistingFolder(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      throw ArgumentError('Directory does not exist: $directoryPath');
    }

    final id = _uuid.v4();
    final name = dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => directoryPath);
    final isGit = GitDetector.isGitRepo(directoryPath);
    final branch = isGit ? GitDetector.getCurrentBranch(directoryPath) : null;

    await _db.projectDao.upsertProject(
      WorkspaceProjectsCompanion(
        id: Value(id),
        name: Value(name),
        path: Value(directoryPath),
        isGit: Value(isGit),
        currentBranch: Value(branch),
        createdAt: Value(DateTime.now()),
        sortOrder: Value(0),
      ),
    );

    return Project(
      id: id,
      name: name,
      path: directoryPath,
      isGit: isGit,
      currentBranch: branch,
      createdAt: DateTime.now(),
    );
  }

  Future<Project> createNewFolder(String parentPath, String folderName) async {
    final fullPath = '$parentPath/$folderName';
    final dir = Directory(fullPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return addExistingFolder(fullPath);
  }

  Future<void> removeProject(String projectId) async {
    // Only removes from the database — does NOT delete the folder from disk
    await _db.projectDao.deleteProject(projectId);
  }

  Future<void> updateProjectActions(
    String projectId,
    List<ProjectAction> actions,
  ) async {
    final json = jsonEncode(actions.map((a) => a.toJson()).toList());
    await _db.projectDao.updateProject(
      projectId,
      WorkspaceProjectsCompanion(actionsJson: Value(json)),
    );
  }

  Future<void> refreshGitStatus(String projectId) async {
    final row = await _db.projectDao.getProject(projectId);
    if (row == null) return;

    final isGit = GitDetector.isGitRepo(row.path);
    final branch = isGit ? GitDetector.getCurrentBranch(row.path) : null;

    await _db.projectDao.updateProject(
      projectId,
      WorkspaceProjectsCompanion(isGit: Value(isGit), currentBranch: Value(branch)),
    );
  }

  Project _projectFromRow(WorkspaceProjectRow row) {
    List<ProjectAction> actions = const [];
    // We write this column ourselves as jsonEncode(...) in
    // updateProjectActions, so a decode failure here means either manual
    // DB tampering or a schema bug — log it and fall back to an empty
    // list so the UI still functions.
    try {
      final decoded = jsonDecode(row.actionsJson) as List<dynamic>;
      actions = decoded.map((e) => ProjectAction.fromJson(e as Map<String, dynamic>)).toList();
    } on FormatException catch (e) {
      if (kDebugMode) debugPrint('[ProjectService] actionsJson FormatException for ${row.id}: $e');
    } on TypeError catch (e) {
      if (kDebugMode) debugPrint('[ProjectService] actionsJson TypeError for ${row.id}: $e');
    }
    return Project(
      id: row.id,
      name: row.name,
      path: row.path,
      isGit: row.isGit,
      currentBranch: row.currentBranch,
      createdAt: row.createdAt,
      sortOrder: row.sortOrder,
      actions: actions,
    );
  }
}
