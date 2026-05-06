import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_time.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/session/models/chat_session.dart';

class ArchivedSessionCard extends StatefulWidget {
  const ArchivedSessionCard({super.key, required this.session, required this.onUnarchive, required this.onDelete});

  final ChatSession session;
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
              _CardChip(
                icon: AppIcons.archiveRestore,
                label: 'Unarchive',
                isDestructive: false,
                onTap: widget.onUnarchive,
              ),
              const SizedBox(width: 6),
              _CardChip(
                icon: AppIcons.trash,
                label: 'Delete',
                isDestructive: true,
                onTap: () => _confirmDelete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardChip extends StatefulWidget {
  const _CardChip({required this.icon, required this.label, required this.isDestructive, required this.onTap});

  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  State<_CardChip> createState() => _CardChipState();
}

class _CardChipState extends State<_CardChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hovered = _hovered;
    final Color fg = widget.isDestructive ? (hovered ? c.error : c.chipText) : (hovered ? c.accent : c.chipText);
    final Color bg = widget.isDestructive
        ? (hovered ? c.error.withValues(alpha: 0.12) : c.chipFill)
        : (hovered ? c.accentTintMid : c.chipFill);
    final Color border = widget.isDestructive
        ? (hovered ? c.destructiveBorder : c.chipStroke)
        : (hovered ? c.accentBorderTeal : c.chipStroke);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 12, color: fg),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(color: fg, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
