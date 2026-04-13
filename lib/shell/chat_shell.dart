import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/theme_constants.dart';
import '../features/chat/notifiers/chat_notifier.dart';
import '../features/chat/widgets/changes_panel.dart';
import '../features/project_sidebar/project_sidebar.dart';
import '../features/project_sidebar/notifiers/project_sidebar_actions.dart';
import '../features/project_sidebar/notifiers/project_sidebar_notifier.dart';
import 'widgets/action_output_panel.dart';
import 'widgets/app_lifecycle_observer.dart';
import 'widgets/status_bar.dart';
import 'widgets/top_action_bar.dart';

class ChatShell extends ConsumerWidget {
  const ChatShell({super.key, required this.child});

  final Widget child;

  Future<void> _newChat(WidgetRef ref, BuildContext context) async {
    final projectId = ref.read(activeProjectIdProvider);
    if (projectId == null) return;
    final model = ref.read(selectedModelProvider);
    final sessionId = await ref
        .read(projectSidebarActionsProvider.notifier)
        .createSession(model: model, projectId: projectId);
    ref.read(activeSessionIdProvider.notifier).set(sessionId);
    if (context.mounted) context.go('/chat/$sessionId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panelVisible = ref.watch(changesPanelVisibleProvider);
    final activeSessionId = ref.watch(activeSessionIdProvider);

    return AppLifecycleObserver(
      child: Material(
        color: ThemeConstants.background,
        child: CallbackShortcuts(
          bindings: {
            // The notifier logs createSession failures; swallow here so the
            // shortcut never surfaces as an uncaught exception.
            const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
                _newChat(ref, context).catchError((Object _) {}),
            const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
                _newChat(ref, context).catchError((Object _) {}),
            const SingleActivator(LogicalKeyboardKey.comma, meta: true): () => context.go('/settings'),
            const SingleActivator(LogicalKeyboardKey.comma, control: true): () => context.go('/settings'),
          },
          child: Focus(
            autofocus: true,
            child: Row(
              children: [
                // Left sidebar
                const ProjectSidebar(),
                // Right: chat column + optional changes panel
                Expanded(
                  child: Column(
                    children: [
                      const TopActionBar(),
                      const ActionOutputPanel(),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: child),
                            if (panelVisible && activeSessionId != null)
                              SizedBox(width: 190, child: ChangesPanel(sessionId: activeSessionId)),
                          ],
                        ),
                      ),
                      const StatusBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
