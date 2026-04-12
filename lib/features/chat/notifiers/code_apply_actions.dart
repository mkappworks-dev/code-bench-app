import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/models/applied_change.dart';
import '../../../features/project_sidebar/project_sidebar_actions.dart';
import '../../../services/apply/apply_service.dart';

part 'code_apply_actions.g.dart';

/// Command notifier for code-apply and revert operations.
///
/// Widgets never reach [ApplyService] directly — they call methods here.
/// On [ProjectMissingException], [applyChange] also triggers a project-status
/// refresh so the sidebar reflects the missing state without the widget needing
/// to know about [ProjectSidebarActions].
@Riverpod(keepAlive: true)
class CodeApplyActions extends _$CodeApplyActions {
  @override
  void build() {}

  /// Applies [newContent] to [filePath] and records the change for revert.
  ///
  /// Throws on failure — callers should catch:
  /// - [ProjectMissingException] — project folder was deleted/moved
  /// - [StateError]              — path is outside the project root
  /// - [FileSystemException]     — low-level disk write failure
  Future<void> applyChange({
    required String projectId,
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    try {
      await ref
          .read(applyServiceProvider)
          .applyChange(
            filePath: filePath,
            projectPath: projectPath,
            newContent: newContent,
            sessionId: sessionId,
            messageId: messageId,
          );
    } on ProjectMissingException {
      // Flip the sidebar tile to "missing" immediately rather than waiting for
      // the next app-resume refresh cycle.
      unawaited(
        ref
            .read(projectSidebarActionsProvider.notifier)
            .refreshProjectStatus(projectId)
            .catchError((Object e) => dLog('[CodeApplyActions] refresh after ProjectMissingException failed: $e')),
      );
      rethrow;
    }
  }

  /// Reverts a previously applied change.
  ///
  /// Throws on failure — callers should catch and surface appropriate UI.
  Future<void> revertChange({required AppliedChange change, required bool isGit, required String projectPath}) =>
      ref.read(applyServiceProvider).revertChange(change: change, isGit: isGit, projectPath: projectPath);
}
