// lib/features/archive/archive_screen.dart
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
import 'widgets/archived_session_card.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sessionsAsync = ref.watch(archivedSessionsProvider);
    final projectsAsync = ref.watch(projectsProvider);

    ref.listen(archiveActionsProvider, (prev, next) {
      if (!mounted) return;
      if (next is AsyncError) {
        final failure = next.error;
        if (failure is! ArchiveFailure) return;
        switch (failure) {
          case ArchiveStorageError():
            AppSnackBar.show(context, 'Storage error — please try again.', type: AppSnackBarType.error);
          case ArchiveUnknownError():
            AppSnackBar.show(context, 'Unexpected error — please try again.', type: AppSnackBarType.error);
        }
        return;
      }
      if (next is AsyncData && prev is AsyncLoading) {
        AppSnackBar.show(context, 'Session unarchived', type: AppSnackBarType.success);
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
                _ => const <Project>[],
              };
              final projectMap = {for (final p in projects) p.id: p.name};

              final groups = <String?, List<ChatSession>>{};
              for (final s in sessions) {
                groups.putIfAbsent(s.projectId, () => []).add(s);
              }

              return ListView(
                padding: const EdgeInsets.only(right: 24, bottom: 24),
                children: [
                  for (final entry in groups.entries) ...[
                    ProjectHeader(name: projectMap[entry.key] ?? 'No Project'),
                    for (final s in entry.value) ArchivedSessionCard(session: s),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
