import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
import '../../services/session/session_service.dart';
import 'chat_notifier.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_list.dart';

/// Persistent chat panel shown in the desktop shell alongside the editor
class ChatPanel extends ConsumerWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionId = ref.watch(activeSessionIdProvider);

    return Container(
      color: ThemeConstants.panelBackground,
      child: Column(
        children: [
          // Panel header
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: ThemeConstants.sidebarBackground,
              border: Border(
                bottom: BorderSide(color: ThemeConstants.borderColor),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Chat',
                  style: TextStyle(
                    color: ThemeConstants.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  tooltip: 'New chat',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
                  onPressed: () async {
                    final service = ref.read(sessionServiceProvider);
                    final model = ref.read(selectedModelProvider);
                    final id = await service.createSession(model: model);
                    ref.read(activeSessionIdProvider.notifier).set(id);
                    if (context.mounted) context.go('/chat/$id');
                  },
                ),
              ],
            ),
          ),
          // Messages or empty state
          Expanded(
            child: sessionId == null
                ? const _NoChatSelected()
                : MessageList(sessionId: sessionId),
          ),
          // Input
          if (sessionId != null) ChatInputBar(sessionId: sessionId),
        ],
      ),
    );
  }
}

class _NoChatSelected extends StatelessWidget {
  const _NoChatSelected();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Select or start a chat',
        style: TextStyle(color: ThemeConstants.textMuted, fontSize: 13),
      ),
    );
  }
}
