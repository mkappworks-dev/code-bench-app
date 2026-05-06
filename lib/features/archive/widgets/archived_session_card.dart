import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_time.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/session/models/chat_session.dart';
import 'archive_chip.dart';

class ArchivedSessionCard extends StatefulWidget {
  const ArchivedSessionCard({
    super.key,
    required this.session,
    required this.isLoading,
    required this.onUnarchive,
    required this.onDelete,
  });

  final ChatSession session;
  final bool isLoading;
  final VoidCallback onUnarchive;
  final VoidCallback onDelete;

  @override
  State<ArchivedSessionCard> createState() => _ArchivedSessionCardState();
}

class _ArchivedSessionCardState extends State<ArchivedSessionCard> {
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: AppIcons.trash,
        iconType: AppDialogIconType.destructive,
        title: 'Delete archived conversation?',
        content: Builder(
          builder: (context) {
            final c = AppColors.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.chipFill,
                    border: Border.all(color: c.chipStroke),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.session.title,
                    style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will permanently delete the conversation and all its messages. '
                  'This cannot be undone.',
                  style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
              ],
            );
          },
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.of(ctx).pop(false)),
          AppDialogAction.destructive(label: 'Delete', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.background,
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.title,
                  style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Archived ${widget.session.updatedAt.relativeTime} · Created ${widget.session.createdAt.relativeTime}',
                  style: TextStyle(color: c.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArchiveChip(
                size: ArchiveChipSize.card,
                icon: AppIcons.archiveRestore,
                label: 'Unarchive',
                isDestructive: false,
                onTap: widget.isLoading ? null : widget.onUnarchive,
              ),
              const SizedBox(width: 6),
              ArchiveChip(
                size: ArchiveChipSize.card,
                icon: AppIcons.trash,
                label: 'Delete',
                isDestructive: true,
                onTap: widget.isLoading ? null : () => _confirmDelete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
