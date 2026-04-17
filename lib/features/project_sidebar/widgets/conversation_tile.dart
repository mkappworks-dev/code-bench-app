import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/instant_menu.dart';
import '../../../core/utils/relative_time.dart';
import '../../../data/session/models/chat_session.dart';

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

  void _showContextMenu(BuildContext context, Offset globalPosition) async {
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
    if (action == 'delete') onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onSecondaryTapUp: (details) => _showContextMenu(context, details.globalPosition),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(color: isActive ? c.accentTintMid : null, borderRadius: BorderRadius.circular(5)),
          child: Row(
            children: [
              // Status dot
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: isActive ? c.accent : Colors.transparent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              // Title
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
              // Time
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
