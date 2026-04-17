import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_icons.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/relative_time.dart';
import '../../core/utils/debug_logger.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../data/session/models/chat_session.dart';
import '../../data/project/models/project.dart';
import '../chat/notifiers/chat_notifier.dart';
import '../project_sidebar/notifiers/project_sidebar_actions.dart';
import '../project_sidebar/notifiers/project_sidebar_notifier.dart';
import 'notifiers/archive_actions.dart';

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
      if (next is AsyncData && prev is AsyncLoading) {
        AppSnackBar.show(context, 'Session unarchived', type: AppSnackBarType.success);
      }
    });

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, st) {
        dLog('[archive] load failed: $e\n$st');
        return _ArchiveErrorView(
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

        // Group sessions by projectId
        final groups = <String?, List<ChatSession>>{};
        for (final s in sessions) {
          groups.putIfAbsent(s.projectId, () => []).add(s);
        }

        return ListView(
          children: [
            for (final entry in groups.entries) ...[
              _ProjectHeader(name: projectMap[entry.key] ?? 'No Project'),
              for (final s in entry.value) _ArchivedSessionCard(session: s),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _ArchiveErrorView extends StatelessWidget {
  const _ArchiveErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Failed to load archived sessions.', style: TextStyle(color: c.error, fontSize: 11)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: c.textPrimary,
              side: BorderSide(color: c.borderColor),
              textStyle: const TextStyle(fontSize: 11),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        children: [
          Icon(AppIcons.folder, size: 12, color: c.mutedFg),
          const SizedBox(width: 6),
          Text(
            name.toUpperCase(),
            style: TextStyle(color: c.mutedFg, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

class _ArchivedSessionCard extends ConsumerStatefulWidget {
  const _ArchivedSessionCard({required this.session});

  final ChatSession session;

  @override
  ConsumerState<_ArchivedSessionCard> createState() => _ArchivedSessionCardState();
}

class _ArchivedSessionCardState extends ConsumerState<_ArchivedSessionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.background,
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.title,
                  style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Archived ${widget.session.updatedAt.relativeTime} · Created ${widget.session.createdAt.relativeTime}',
                  style: TextStyle(color: c.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: () => ref.read(archiveActionsProvider.notifier).unarchiveSession(widget.session.sessionId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _hovered ? c.borderColor : Colors.transparent,
                  border: Border.all(color: c.borderColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.archiveRestore, size: 12, color: c.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      'Unarchive',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
