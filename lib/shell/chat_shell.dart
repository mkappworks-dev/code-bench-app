import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/theme_constants.dart';
import '../features/chat/chat_notifier.dart';
import '../features/project_sidebar/project_sidebar.dart';
import '../features/project_sidebar/project_sidebar_notifier.dart';
import '../services/session/session_service.dart';
import 'widgets/status_bar.dart';
import 'widgets/top_action_bar.dart';

class ChatShell extends ConsumerWidget {
  const ChatShell({super.key, required this.child});

  final Widget child;

  Future<void> _newChat(WidgetRef ref, BuildContext context) async {
    final projectId = ref.read(activeProjectIdProvider);
    if (projectId == null) return;
    final model = ref.read(selectedModelProvider);
    final service = ref.read(sessionServiceProvider);
    final sessionId = await service.createSession(
      model: model,
      projectId: projectId,
    );
    ref.read(activeSessionIdProvider.notifier).set(sessionId);
    if (context.mounted) context.go('/chat/$sessionId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: ThemeConstants.background,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
              _newChat(ref, context),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
              _newChat(ref, context),
          const SingleActivator(LogicalKeyboardKey.comma, meta: true): () =>
              context.go('/settings'),
          const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
              context.go('/settings'),
        },
        child: Focus(
          autofocus: true,
          child: Row(
            children: [
              // Sidebar
              const ProjectSidebar(),
              // Right panel
              Expanded(
                child: Column(
                  children: [
                    const TopActionBar(),
                    Expanded(child: child),
                    const StatusBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
