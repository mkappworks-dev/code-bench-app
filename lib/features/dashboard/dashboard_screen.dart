import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/chat_session.dart';
import '../../services/session/session_service.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../chat/chat_notifier.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            const Text(
              'Code Bench',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'AI-powered code assistant',
              style: TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Quick actions
            const Text(
              'Quick Start',
              style: TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickAction(
                  icon: Icons.add_comment_outlined,
                  label: 'New Chat',
                  description: 'Start a new AI conversation',
                  onTap: () async {
                    final service = ref.read(sessionServiceProvider);
                    final model = ref.read(selectedModelProvider);
                    final id = await service.createSession(model: model);
                    ref.read(activeSessionIdProvider.notifier).set(id);
                    if (context.mounted) context.go('/chat/$id');
                  },
                ),
                _QuickAction(
                  icon: Icons.folder_open_outlined,
                  label: 'Open Folder',
                  description: 'Browse local files',
                  onTap: () => context.go('/editor'),
                ),
                _QuickAction(
                  icon: Icons.source_outlined,
                  label: 'GitHub',
                  description: 'Browse repositories',
                  onTap: () => context.go('/github'),
                ),
                _QuickAction(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  description: 'Configure API keys',
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Recent sessions
            const Text(
              'Recent Conversations',
              style: TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            sessionsAsync.when(
              loading: () => const SizedBox(
                height: 280,
                child: SkeletonLoader(itemCount: 4),
              ),
              error: (e, _) => Text(
                'Failed to load sessions: $e',
                style: const TextStyle(color: ThemeConstants.error),
              ),
              data: (List<ChatSession> sessions) {
                if (sessions.isEmpty) {
                  return const _EmptySessions();
                }
                return Column(
                  children: sessions
                      .take(10)
                      .map(
                        (s) => _SessionTile(
                          session: s,
                          onTap: () {
                            ref
                                .read(activeSessionIdProvider.notifier)
                                .set(s.sessionId);
                            context.go('/chat/${s.sessionId}');
                          },
                          onDelete: () async {
                            await ref
                                .read(sessionServiceProvider)
                                .deleteSession(s.sessionId);
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: ThemeConstants.editorLineHighlight,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeConstants.sidebarBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ThemeConstants.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: ThemeConstants.accent),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: ThemeConstants.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  final ChatSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, HH:mm').format(session.updatedAt);

    return ListTile(
      onTap: onTap,
      leading: const Icon(
        Icons.chat_bubble_outline,
        size: 16,
        color: ThemeConstants.textMuted,
      ),
      title: Text(
        session.title,
        style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${session.providerId}/${session.modelId} · $dateStr',
        style: const TextStyle(color: ThemeConstants.textMuted, fontSize: 11),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 16),
        color: ThemeConstants.textMuted,
        tooltip: 'Delete',
        onPressed: onDelete,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      hoverColor: ThemeConstants.editorLineHighlight,
    );
  }
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ThemeConstants.sidebarBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeConstants.borderColor),
      ),
      child: const Center(
        child: Text(
          'No conversations yet. Start one above!',
          style: TextStyle(color: ThemeConstants.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}
