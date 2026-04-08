import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/chat_session.dart';
import '../../../data/models/project.dart';
import 'conversation_tile.dart';
import 'project_context_menu.dart';

class ProjectTile extends ConsumerWidget {
  const ProjectTile({
    super.key,
    required this.project,
    required this.sessions,
    required this.isExpanded,
    required this.activeSessionId,
    required this.onToggleExpand,
    required this.onSessionTap,
    required this.onRemove,
    required this.onRename,
    required this.onNewConversation,
  });

  final Project project;
  final List<ChatSession> sessions;
  final bool isExpanded;
  final String? activeSessionId;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onSessionTap;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onNewConversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project header
        GestureDetector(
          onSecondaryTapUp: (details) async {
            final action = await ProjectContextMenu.show(
              context: context,
              position: details.globalPosition,
              projectPath: project.path,
              isGit: project.isGit,
            );
            if (action != null && context.mounted) {
              await ProjectContextMenu.handleAction(
                action: action,
                projectId: project.id,
                projectPath: project.path,
                context: context,
                onRemove: onRemove,
                onRename: onRename,
                onNewConversation: onNewConversation,
              );
            }
          },
          child: InkWell(
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Chevron
                  Icon(
                    isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 16,
                    color: const Color(0xFF444444),
                  ),
                  const SizedBox(width: 4),
                  // Folder icon
                  const Icon(
                    Icons.folder_outlined,
                    size: 14,
                    color: Color(0xFF9D9D9D),
                  ),
                  const SizedBox(width: 6),
                  // Project name
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Git tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: project.isGit
                          ? const Color(0xFF0D2818)
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      project.isGit
                          ? project.currentBranch ?? 'git'
                          : 'Not git',
                      style: TextStyle(
                        color: project.isGit
                            ? ThemeConstants.success
                            : const Color(0xFF555555),
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Conversations list (when expanded)
        if (isExpanded && sessions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 10, bottom: 6),
            child: Column(
              children: sessions
                  .map(
                    (s) => ConversationTile(
                      session: s,
                      isActive: s.sessionId == activeSessionId,
                      onTap: () => onSessionTap(s.sessionId),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
