import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/debug_logger.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../data/project/models/project.dart';
import '../../data/session/models/chat_session.dart';
import '../chat/notifiers/chat_notifier.dart';
import '../project_sidebar/notifiers/project_sidebar_actions.dart';
import '../project_sidebar/notifiers/project_sidebar_notifier.dart';
import 'notifiers/archive_actions.dart';
import 'notifiers/archive_failure.dart';
import '../settings/widgets/section_label.dart';
import 'widgets/archive_error_view.dart';
import 'widgets/archive_project_group.dart';

enum _ArchivePendingAction { unarchive, unarchiveAll, delete, deleteAll }

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  _ArchivePendingAction? _pendingAction;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sessionsAsync = ref.watch(archivedSessionsProvider);
    final projectsAsync = ref.watch(projectsProvider);

    ref.listen(archiveActionsProvider, (prev, next) {
      if (!mounted) return;
      if (next is AsyncError) {
        final failure = next.error;
        if (failure is! ArchiveFailure) {
          dLog('[ArchiveScreen] unexpected error type in archiveActionsProvider: ${failure.runtimeType}');
          return;
        }
        final op = switch (_pendingAction) {
          _ArchivePendingAction.delete || _ArchivePendingAction.deleteAll => 'delete',
          _ArchivePendingAction.unarchive || _ArchivePendingAction.unarchiveAll || null => 'unarchive',
        };
        switch (failure) {
          case ArchiveStorageError():
            AppSnackBar.show(context, 'Could not $op — storage error. Please try again.', type: AppSnackBarType.error);
          case ArchiveUnknownError():
            AppSnackBar.show(
              context,
              'Could not $op — unexpected error. Please try again.',
              type: AppSnackBarType.error,
            );
        }
        return;
      }
      if (next is AsyncData && prev is AsyncLoading) {
        final message = switch (_pendingAction) {
          _ArchivePendingAction.unarchive => 'Session unarchived',
          _ArchivePendingAction.unarchiveAll => 'All sessions unarchived',
          _ArchivePendingAction.delete => 'Session deleted',
          _ArchivePendingAction.deleteAll => 'All archived sessions deleted',
          null => 'Done',
        };
        AppSnackBar.show(context, message, type: AppSnackBarType.success);
        _pendingAction = null;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Archive'),
        const SizedBox(height: 8),
        Expanded(
          child: sessionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, st) {
              dLog('[archive] load failed: $e\n$st');
              return ArchiveErrorView(
                onRetry: () => ref.read(projectSidebarActionsProvider.notifier).refreshArchivedSessions(),
              );
            },
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.archive, size: 32, color: c.mutedFg),
                      const SizedBox(height: 12),
                      Text('No archived conversations', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                    ],
                  ),
                );
              }

              final projects = switch (projectsAsync) {
                AsyncData(:final value) => value,
                AsyncLoading() => const <Project>[],
                AsyncError(:final error, :final stackTrace) => () {
                  dLog(
                    '[ArchiveScreen] projectsAsync error — project names will show as "No Project": ${error.runtimeType}\n$stackTrace',
                  );
                  return const <Project>[];
                }(),
              };
              final projectMap = {for (final p in projects) p.id: p.name};

              final groups = <String?, List<ChatSession>>{};
              for (final s in sessions) {
                groups.putIfAbsent(s.projectId, () => []).add(s);
              }

              return ListView(
                padding: const EdgeInsets.only(right: 24, bottom: 24),
                children: [
                  for (final entry in groups.entries)
                    ArchiveProjectGroup(
                      key: ValueKey(entry.key),
                      projectName: projectMap[entry.key] ?? 'No Project',
                      sessions: entry.value,
                      initiallyExpanded: groups.length == 1,
                      isLoading: ref.watch(archiveActionsProvider).isLoading,
                      onUnarchive: (id) {
                        _pendingAction = _ArchivePendingAction.unarchive;
                        ref.read(archiveActionsProvider.notifier).unarchiveSession(id);
                      },
                      onDelete: (id) {
                        _pendingAction = _ArchivePendingAction.delete;
                        ref.read(archiveActionsProvider.notifier).deleteSession(id);
                      },
                      onUnarchiveAll: () {
                        _pendingAction = _ArchivePendingAction.unarchiveAll;
                        final ids = entry.value.map((s) => s.sessionId).toList();
                        ref.read(archiveActionsProvider.notifier).unarchiveAllForProject(ids);
                      },
                      onDeleteAll: () {
                        _pendingAction = _ArchivePendingAction.deleteAll;
                        final ids = entry.value.map((s) => s.sessionId).toList();
                        ref.read(archiveActionsProvider.notifier).deleteAllForProject(ids);
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
