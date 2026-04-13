import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/project.dart';
import '../../features/chat/notifiers/chat_notifier.dart';
import '../../features/project_sidebar/notifiers/project_sidebar_notifier.dart';
import '../../data/git/git_live_state.dart';
import '../../data/git/repository/git_repository_impl.dart';

part 'status_bar_notifier.freezed.dart';
part 'status_bar_notifier.g.dart';

/// Derived state consumed by [StatusBar].
///
/// Bundles the active project, the per-session applied-change count, and the
/// current git live state so the widget's [build] method only reads a single
/// provider instead of doing multi-step derivation inline.
@freezed
abstract class StatusBarState with _$StatusBarState {
  const factory StatusBarState({
    required Project? activeProject,
    required int changeCount,
    required GitLiveState? liveState,
  }) = _StatusBarState;
}

/// Synchronously derives [StatusBarState] from lower-level providers.
///
/// [changesPanelVisibleProvider] is intentionally excluded — it is a UI-only
/// toggle that the status bar both reads and writes, so it stays a direct
/// [ref.watch] in the widget.
@riverpod
StatusBarState statusBarState(Ref ref) {
  final projectId = ref.watch(activeProjectIdProvider);
  final activeSessionId = ref.watch(activeSessionIdProvider);

  final activeProject = projectId == null
      ? null
      : ref.watch(projectsProvider).whenOrNull(data: (list) => list.firstWhereOrNull((p) => p.id == projectId));

  final allChanges = ref.watch(appliedChangesProvider);
  final changeCount = activeSessionId != null ? (allChanges[activeSessionId]?.length ?? 0) : 0;

  final liveStateAsync = activeProject != null ? ref.watch(gitLiveStateProvider(activeProject.path)) : null;

  return StatusBarState(
    activeProject: activeProject,
    changeCount: changeCount,
    liveState: switch (liveStateAsync) {
      AsyncData(:final value) => value,
      _ => null,
    },
  );
}
