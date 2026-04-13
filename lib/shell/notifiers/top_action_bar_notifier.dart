import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/chat_session.dart';
import '../../data/models/project.dart';
import '../../features/chat/notifiers/chat_notifier.dart';
import '../../features/project_sidebar/notifiers/project_sidebar_notifier.dart';
import 'git_live_state_notifier.dart';

part 'top_action_bar_notifier.freezed.dart';
part 'top_action_bar_notifier.g.dart';

/// Derived state consumed by [TopActionBar].
@freezed
abstract class TopActionBarState with _$TopActionBarState {
  const factory TopActionBarState({
    required String sessionTitle,
    required Project? project,

    /// Tri-state: `true` = confirmed git repo, `false` = confirmed non-git,
    /// `null` = loading or error. Widgets only show "No Git" badge or
    /// "Init Git" button for the confirmed `false` case — never while loading,
    /// so the bar doesn't flicker on every refocus.
    required bool? isGit,
  }) = _TopActionBarState;
}

/// Synchronously derives [TopActionBarState] from lower-level providers.
@riverpod
TopActionBarState topActionBarState(Ref ref) {
  final sessionId = ref.watch(activeSessionIdProvider);
  final projectId = ref.watch(activeProjectIdProvider);

  final sessionTitle =
      ref
          .watch(chatSessionsProvider)
          .whenOrNull(
            data: (List<ChatSession> list) {
              if (sessionId == null) return 'Code Bench';
              return list.firstWhereOrNull((s) => s.sessionId == sessionId)?.title ?? 'New Chat';
            },
          ) ??
      'Code Bench';

  final project = projectId == null
      ? null
      : ref.watch(projectsProvider).whenOrNull(data: (list) => list.firstWhereOrNull((p) => p.id == projectId));

  final bool? isGit = project != null ? ref.watch(gitLiveStateProvider(project.path)).value?.isGit : null;

  return TopActionBarState(sessionTitle: sessionTitle, project: project, isGit: isGit);
}
