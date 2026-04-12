import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/chat_session.dart';
import '../../../data/models/project.dart';
import '../../../services/git/git_live_state_provider.dart';
import '../project_sidebar_actions.dart';
import '../project_sidebar_notifier.dart';
import 'conversation_tile.dart';
import 'project_context_menu.dart';
import 'rename_conversation_dialog.dart';

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
    required this.onNewConversation,
    required this.onArchive,
    required this.onDelete,
    required this.onRelocate,
  });

  final Project project;
  final List<ChatSession> sessions;
  final bool isExpanded;
  final String? activeSessionId;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onSessionTap;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onNewConversation;
  final ValueChanged<String> onArchive;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onRelocate;

  @override
  ConsumerState<ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends ConsumerState<ProjectTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMissing = widget.project.status == ProjectStatus.missing;
    final activeProjectId = ref.watch(activeProjectIdProvider);
    // Safe to watch unconditionally: for a missing folder the provider's
    // isGitRepo check returns false (no `.git` entry), so it resolves to
    // GitLiveState.notGit without spawning any git processes.
    final liveStateAsync = ref.watch(gitLiveStateProvider(widget.project.path));
    final liveState = switch (liveStateAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final isActive = widget.project.id == activeProjectId;
    final isGit = !isMissing && (liveState?.isGit ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onSecondaryTapUp: (details) async {
            final action = await ProjectContextMenu.show(
              context: context,
              position: details.globalPosition,
              projectPath: widget.project.path,
              isGit: isGit,
              isMissing: isMissing,
            );
            if (action != null && context.mounted) {
              await ProjectContextMenu.handleAction(
                action: action,
                projectId: widget.project.id,
                projectPath: widget.project.path,
                context: context,
                onRemove: widget.onRemove,
                onNewConversation: widget.onNewConversation,
                onRelocate: widget.onRelocate,
              );
            }
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: InkWell(
              onTap: widget.onToggleExpand,
              child: Container(
                decoration: isActive
                    ? BoxDecoration(
                        color: ThemeConstants.success.withValues(alpha: 0.06),
                        border: const Border(left: BorderSide(color: ThemeConstants.success, width: 2)),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      // Chevron
                      Icon(
                        widget.isExpanded ? AppIcons.chevronDown : AppIcons.chevronRight,
                        size: 14,
                        color: ThemeConstants.faintFg,
                      ),
                      const SizedBox(width: 4),
                      // Folder icon — warning triangle when missing
                      Icon(
                        isMissing ? AppIcons.warning : AppIcons.folder,
                        size: 13,
                        color: isMissing ? ThemeConstants.warning : ThemeConstants.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      // Project name — muted + strikethrough when missing
                      Expanded(
                        child: Tooltip(
                          message: isMissing ? 'Folder not found: ${widget.project.path}' : '',
                          child: Text(
                            widget.project.name,
                            style: TextStyle(
                              color: isMissing ? ThemeConstants.mutedFg : ThemeConstants.textPrimary,
                              fontSize: ThemeConstants.uiFontSize,
                              fontWeight: FontWeight.w500,
                              decoration: isMissing ? TextDecoration.lineThrough : null,
                              decorationColor: ThemeConstants.mutedFg,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // New-chat icon — hidden entirely when missing
                      if (!isMissing)
                        AnimatedOpacity(
                          opacity: _hovered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 120),
                          child: InkWell(
                            onTap: () => widget.onNewConversation(widget.project.id),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(AppIcons.newChat, size: 13, color: ThemeConstants.mutedFg),
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      // Git icon — faint when missing or not a repo
                      Tooltip(
                        message: isGit ? (liveState?.branch ?? 'git') : '',
                        child: Icon(
                          AppIcons.gitBranch,
                          size: 13,
                          color: isGit ? ThemeConstants.success : ThemeConstants.faintFg,
                        ),
                      ),
                    ],
                  ),
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
                  .map(
                    (s) => ConversationTile(
                      session: s,
                      isActive: s.sessionId == widget.activeSessionId,
                      onTap: () => widget.onSessionTap(s.sessionId),
                      onArchive: () => widget.onArchive(s.sessionId),
                      onDelete: () => widget.onDelete(s.sessionId),
                      onRename: () async {
                        if (!context.mounted) return;
                        final newTitle = await RenameConversationDialog.show(context, s.title);
                        if (newTitle != null) {
                          await ref
                              .read(projectSidebarActionsProvider.notifier)
                              .updateSessionTitle(s.sessionId, newTitle);
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
