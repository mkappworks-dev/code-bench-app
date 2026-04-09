import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/chat_session.dart';
import '../../../data/models/project.dart';
import 'conversation_tile.dart';
import 'project_context_menu.dart';

class ProjectTile extends ConsumerStatefulWidget {
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
  ConsumerState<ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends ConsumerState<ProjectTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onSecondaryTapUp: (details) async {
            final action = await ProjectContextMenu.show(
              context: context,
              position: details.globalPosition,
              projectPath: widget.project.path,
              isGit: widget.project.isGit,
            );
            if (action != null && context.mounted) {
              await ProjectContextMenu.handleAction(
                action: action,
                projectId: widget.project.id,
                projectPath: widget.project.path,
                context: context,
                onRemove: widget.onRemove,
                onRename: widget.onRename,
                onNewConversation: widget.onNewConversation,
              );
            }
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: InkWell(
              onTap: widget.onToggleExpand,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    // Chevron
                    Icon(
                      widget.isExpanded
                          ? LucideIcons.chevronDown
                          : LucideIcons.chevronRight,
                      size: 14,
                      color: ThemeConstants.faintFg,
                    ),
                    const SizedBox(width: 4),
                    // Folder icon
                    Icon(LucideIcons.folder,
                        size: 13, color: ThemeConstants.textSecondary),
                    const SizedBox(width: 6),
                    // Project name
                    Expanded(
                      child: Text(
                        widget.project.name,
                        style: const TextStyle(
                          color: ThemeConstants.textPrimary,
                          fontSize: ThemeConstants.uiFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // New-chat icon (hover only)
                    AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 120),
                      child: InkWell(
                        onTap: () =>
                            widget.onNewConversation(widget.project.id),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            LucideIcons.messageSquarePlus,
                            size: 13,
                            color: ThemeConstants.mutedFg,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Git icon (icon only, no pill)
                    Tooltip(
                      message: widget.project.isGit
                          ? (widget.project.currentBranch ?? 'git')
                          : '',
                      child: Icon(
                        LucideIcons.gitBranch,
                        size: 13,
                        color: widget.project.isGit
                            ? ThemeConstants.success
                            : ThemeConstants.faintFg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.isExpanded && widget.sessions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 10, bottom: 6),
            child: Column(
              children: widget.sessions
                  .map((s) => ConversationTile(
                        session: s,
                        isActive: s.sessionId == widget.activeSessionId,
                        onTap: () => widget.onSessionTap(s.sessionId),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
