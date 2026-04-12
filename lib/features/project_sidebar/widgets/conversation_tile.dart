import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/utils/instant_menu.dart';
import '../../../data/models/chat_session.dart';

class ConversationTile extends StatelessWidget {
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

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  void _showContextMenu(BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final action = await showInstantMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      color: ThemeConstants.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: ThemeConstants.faintFg),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'rename',
          height: 32,
          child: Row(
            children: [
              Icon(AppIcons.rename, size: 13, color: ThemeConstants.textSecondary),
              const SizedBox(width: 8),
              const Text(
                'Rename',
                style: TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'archive',
          height: 32,
          child: Row(
            children: [
              Icon(AppIcons.archive, size: 13, color: ThemeConstants.textSecondary),
              const SizedBox(width: 8),
              const Text(
                'Archive',
                style: TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
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
              const Icon(AppIcons.trash, size: 13, color: ThemeConstants.error),
              const SizedBox(width: 8),
              const Text(
                'Delete',
                style: TextStyle(color: ThemeConstants.error, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ],
          ),
        ),
      ],
    );

    if (action == 'rename') onRename?.call();
    if (action == 'archive') onArchive?.call();
    if (action == 'delete') onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details) => _showContextMenu(context, details.globalPosition),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? ThemeConstants.inputSurface : null,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              // Status dot
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isActive ? ThemeConstants.accent : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              // Title
              Expanded(
                child: Text(
                  session.title,
                  style: TextStyle(
                    color: isActive ? ThemeConstants.textPrimary : ThemeConstants.mutedFg,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Time
              Text(
                _relativeTime(session.updatedAt),
                style: const TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSizeBadge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
