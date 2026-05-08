import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/instant_menu.dart';
import '../../../core/utils/relative_time.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/session/models/chat_session.dart';
import '../../chat/notifiers/chat_session_streaming.dart';
import '../../chat/utils/session_status_for.dart';
import '../../chat/widgets/session_status_dot.dart';

class ConversationTile extends ConsumerWidget {
  const ConversationTile({
    super.key,
    required this.session,
    required this.isActive,
    required this.onTap,
    this.onRename,
    this.onArchive,
    this.onDelete,
  });

  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  Future<void> _showContextMenu(BuildContext context, WidgetRef ref, Offset globalPosition) async {
    final c = AppColors.of(context);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final action = await showInstantMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      color: c.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: c.faintFg),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'rename',
          height: 32,
          child: Row(
            children: [
              Icon(AppIcons.rename, size: 13, color: c.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Rename',
                style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'archive',
          height: 32,
          child: Row(
            children: [
              Icon(AppIcons.archive, size: 13, color: c.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Archive',
                style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          height: 32,
          child: Row(
            children: [
              Icon(AppIcons.trash, size: 13, color: c.error),
              const SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ],
          ),
        ),
      ],
    );

    if (action == 'rename') onRename?.call();
    if (action == 'archive') onArchive?.call();
    if (action == 'delete') {
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AppDialog(
          icon: AppIcons.trash,
          iconType: AppDialogIconType.destructive,
          title: 'Delete this conversation?',
          content: Builder(
            builder: (context) {
              final c = AppColors.of(context);
              return Text(
                '"${session.title}" and all its messages will be permanently deleted. '
                'This cannot be undone.',
                style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
              );
            },
          ),
          actions: [
            AppDialogAction.cancel(onPressed: () => Navigator.of(ctx).pop(false)),
            AppDialogAction.destructive(label: 'Delete', onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      );
      if (confirmed == true) onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final isStreaming = ref.watch(chatSessionStreamingProvider(session.sessionId)).value ?? false;
    final isFailed = ref.watch(chatSessionFailedProvider(session.sessionId)).value ?? false;
    final isAwaiting = ref.watch(chatSessionAwaitingProvider(session.sessionId)).value ?? false;
    final status = sessionStatusFor(
      isStreaming: isStreaming,
      hasPendingPermission: isAwaiting,
      hasPendingQuestion: false,
      lastTurnFailed: isFailed,
    );
    return GestureDetector(
      onSecondaryTapUp: (details) => unawaited(_showContextMenu(context, ref, details.globalPosition)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(color: isActive ? c.accentTintMid : null, borderRadius: BorderRadius.circular(5)),
          child: Row(
            children: [
              SessionStatusDot(status: status),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  session.title,
                  style: TextStyle(
                    color: isActive ? c.textPrimary : c.mutedFg,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                session.updatedAt.relativeTimeCompact,
                style: TextStyle(color: c.faintFg, fontSize: ThemeConstants.uiFontSizeBadge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
