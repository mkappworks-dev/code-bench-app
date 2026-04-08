import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/chat_session.dart';
import '../../services/session/session_service.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'chat_notifier.dart';

class ChatHomeScreen extends ConsumerWidget {
  const ChatHomeScreen({super.key});

  Future<void> _newChat(BuildContext context, WidgetRef ref) async {
    final service = ref.read(sessionServiceProvider);
    final model = ref.read(selectedModelProvider);
    final id = await service.createSession(model: model);
    ref.read(activeSessionIdProvider.notifier).set(id);
    if (context.mounted) context.go('/chat/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: Column(
        children: [
          // Header
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: ThemeConstants.sidebarBackground,
            child: Row(
              children: [
                const Text(
                  'Chats',
                  style: TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  color: ThemeConstants.textSecondary,
                  tooltip: 'New Chat',
                  onPressed: () => _newChat(context, ref),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Session list
          Expanded(
            child: sessionsAsync.when(
              loading: () => const SkeletonLoader(itemCount: 6),
              error: (e, _) => Center(
                child: Text(
                  'Failed to load chats: $e',
                  style: const TextStyle(color: ThemeConstants.error),
                ),
              ),
              data: (List<ChatSession> sessions) {
                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 36,
                          color: ThemeConstants.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No conversations yet',
                          style: TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _newChat(context, ref),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('New Chat'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    return _SessionTile(
                      session: s,
                      onTap: () {
                        ref
                            .read(activeSessionIdProvider.notifier)
                            .set(s.sessionId);
                        context.go('/chat/${s.sessionId}');
                      },
                      onDelete: () => ref
                          .read(sessionServiceProvider)
                          .deleteSession(s.sessionId),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
        style: const TextStyle(
          color: ThemeConstants.textPrimary,
          fontSize: 13,
        ),
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
