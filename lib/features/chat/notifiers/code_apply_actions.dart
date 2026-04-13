import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/models/applied_change.dart';
import '../../project_sidebar/notifiers/project_sidebar_actions.dart';
import '../../../services/apply/apply_service.dart';
import 'code_apply_failure.dart';

part 'code_apply_actions.g.dart';

/// Command notifier for code-apply and revert operations.
///
/// Widgets never reach [ApplyService] directly — they call methods here.
/// State is [AsyncValue<void>]: loading/error/data are driven by each method.
/// Typed failures are emitted as [AsyncError] carrying a [CodeApplyFailure].
///
/// On [ProjectMissingException], [applyChange] also triggers a project-status
/// refresh so the sidebar reflects the missing state without the widget needing
/// to know about [ProjectSidebarActions].
@Riverpod(keepAlive: true)
class CodeApplyActions extends _$CodeApplyActions {
  @override
  FutureOr<void> build() {}

  CodeApplyFailure _asApplyFailure(Object e) => switch (e) {
    ProjectMissingException() => const CodeApplyFailure.projectMissing(),
    StateError() => const CodeApplyFailure.outsideProject(),
    FileSystemException(:final message) => CodeApplyFailure.diskWrite(message),
    _ => CodeApplyFailure.unknown(e),
  };

  /// Applies [newContent] to [filePath] and records the change for revert.
  ///
  /// On success, state becomes [AsyncData]. On failure, state becomes
  /// [AsyncError] carrying a [CodeApplyFailure].
  Future<void> applyChange({
    required String projectId,
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
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
      } on ProjectMissingException catch (e, st) {
        dLog('[CodeApplyActions] applyChange projectMissing: $e');
        // Fire-and-forget — refreshProjectStatus has its own AsyncError path
        // on projectSidebarActionsProvider; swallowing here would hide the
        // sidebar-badge failure that the user needs to see.
        unawaited(ref.read(projectSidebarActionsProvider.notifier).refreshProjectStatus(projectId));
        Error.throwWithStackTrace(_asApplyFailure(e), st);
      } catch (e, st) {
        dLog('[CodeApplyActions] applyChange failed: $e');
        Error.throwWithStackTrace(_asApplyFailure(e), st);
      }
    });
  }

  /// Reverts a previously applied change.
  ///
  /// On success, state becomes [AsyncData]. On failure, state becomes
  /// [AsyncError] carrying a [CodeApplyFailure].
  Future<void> revertChange({required AppliedChange change, required bool isGit, required String projectPath}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(applyServiceProvider).revertChange(change: change, isGit: isGit, projectPath: projectPath);
      } catch (e, st) {
        dLog('[CodeApplyActions] revertChange failed: $e');
        Error.throwWithStackTrace(CodeApplyFailure.unknown(e), st);
      }
    });
  }

  /// Reads raw file content for the conflict-merge view. Returns `null`
  /// when the file cannot be read — callers must block destructive merges
  /// on null rather than treating it as an empty file.
  Future<String?> readFileContent(String filePath, String projectPath) =>
      ref.read(applyServiceProvider).readFileContent(filePath, projectPath);
}
