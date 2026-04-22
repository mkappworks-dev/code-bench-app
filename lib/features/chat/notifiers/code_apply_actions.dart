import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/apply/models/applied_change.dart';
import '../../../services/apply/apply_service.dart';
import '../../project_sidebar/notifiers/project_sidebar_actions.dart';
import 'chat_notifier.dart';
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
    PathEscapeException() => const CodeApplyFailure.outsideProject(),
    ApplyTooLargeException(:final bytes) => CodeApplyFailure.tooLarge(bytes),
    ApplyDiskException(:final message) => CodeApplyFailure.diskWrite(message),
    ApplyContentChangedException() => const CodeApplyFailure.contentChanged(),
    _ => CodeApplyFailure.unknown(e),
  };

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
        final change = await ref
            .read(applyServiceProvider)
            .applyChange(
              filePath: filePath,
              projectPath: projectPath,
              newContent: newContent,
              sessionId: sessionId,
              messageId: messageId,
            );
        ref.read(appliedChangesProvider.notifier).apply(change);
      } on ProjectMissingException catch (e, st) {
        dLog('[CodeApplyActions] applyChange projectMissing: $e');
        unawaited(ref.read(projectSidebarActionsProvider.notifier).refreshProjectStatus(projectId));
        Error.throwWithStackTrace(_asApplyFailure(e), st);
      } catch (e, st) {
        dLog('[CodeApplyActions] applyChange failed: $e');
        Error.throwWithStackTrace(_asApplyFailure(e), st);
      }
    });
  }

  Future<void> revertChange({required AppliedChange change, required bool isGit, required String projectPath}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(applyServiceProvider).revertChange(change: change, isGit: isGit, projectPath: projectPath);
        ref.read(appliedChangesProvider.notifier).revert(change.id);
      } catch (e, st) {
        dLog('[CodeApplyActions] revertChange failed: $e');
        Error.throwWithStackTrace(_asApplyFailure(e), st);
      }
    });
  }

  Future<String?> readFileContent(String filePath, String projectPath) =>
      ref.read(applyServiceProvider).readFileContent(filePath, projectPath);

  /// Checks whether [filePath] has been modified since [storedChecksum] was
  /// recorded. Called from [ChangesPanel] via `ref.read(.notifier)` in
  /// `initState` — routing through the notifier keeps dart:io out of widgets.
  Future<bool> isExternallyModified(String filePath, String storedChecksum) =>
      ref.read(applyServiceProvider).isExternallyModified(filePath, storedChecksum);
}
