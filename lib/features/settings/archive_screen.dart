import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_icons.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/utils/debug_logger.dart';
import '../../data/models/chat_session.dart';
import '../chat/chat_notifier.dart';
import '../project_sidebar/project_sidebar_notifier.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key, required this.onUnarchive});

  final void Function(String sessionId) onUnarchive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(archivedSessionsProvider);
    final projectsAsync = ref.watch(projectsProvider);

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, st) {
        dLog('[archive] load failed: $e\n$st');
        return _ArchiveErrorView(onRetry: () => ref.invalidate(archivedSessionsProvider));
      },
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(AppIcons.archive, size: 32, color: ThemeConstants.mutedFg),
                SizedBox(height: 12),
                Text('No archived conversations', style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 12)),
              ],
            ),
          );
        }

        final projects = projectsAsync.value ?? [];
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
              for (final s in entry.value)
                _ArchivedSessionCard(session: s, onUnarchive: () => onUnarchive(s.sessionId)),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Failed to load archived sessions.', style: TextStyle(color: ThemeConstants.error, fontSize: 11)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: ThemeConstants.textPrimary,
              side: const BorderSide(color: ThemeConstants.borderColor),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        children: [
          const Icon(AppIcons.folder, size: 12, color: ThemeConstants.mutedFg),
          const SizedBox(width: 6),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: ThemeConstants.mutedFg,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedSessionCard extends StatelessWidget {
  const _ArchivedSessionCard({required this.session, required this.onUnarchive});

  final ChatSession session;
  final VoidCallback onUnarchive;

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: ThemeConstants.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Archived ${_relativeTime(session.updatedAt)} · Created ${_relativeTime(session.createdAt)}',
                  style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onUnarchive,
            icon: const Icon(AppIcons.archiveRestore, size: 12),
            label: const Text('Unarchive'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ThemeConstants.textPrimary,
              side: const BorderSide(color: ThemeConstants.borderColor),
              textStyle: const TextStyle(fontSize: 11),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
