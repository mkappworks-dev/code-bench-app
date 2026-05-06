import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/session/models/chat_session.dart';
import 'archived_session_card.dart';

class ArchiveProjectGroup extends StatefulWidget {
  const ArchiveProjectGroup({
    super.key,
    required this.projectName,
    required this.sessions,
    required this.initiallyExpanded,
    required this.isLoading,
    required this.onUnarchive,
    required this.onDelete,
    required this.onUnarchiveAll,
    required this.onDeleteAll,
  });

  final String projectName;
  final List<ChatSession> sessions;
  final bool initiallyExpanded;
  final bool isLoading;
  final void Function(String sessionId) onUnarchive;
  final void Function(String sessionId) onDelete;
  final VoidCallback onUnarchiveAll;
  final VoidCallback onDeleteAll;

  @override
  State<ArchiveProjectGroup> createState() => _ArchiveProjectGroupState();
}

class _ArchiveProjectGroupState extends State<ArchiveProjectGroup> {
  late bool _expanded = widget.initiallyExpanded;
  bool _hovered = false;

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final count = widget.sessions.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: AppIcons.trash,
        iconType: AppDialogIconType.destructive,
        title: 'Delete all archived conversations for "${widget.projectName}"?',
        content: Builder(
          builder: (context) {
            final c = AppColors.of(context);
            return Text(
              'This will permanently delete $count archived conversation${count == 1 ? '' : 's'} '
              'and all their messages. This cannot be undone.',
              style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
            );
          },
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.of(ctx).pop(false)),
          AppDialogAction.destructive(label: 'Delete All', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      widget.onDeleteAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(AppIcons.chevronRight, size: 10, color: c.mutedFg),
                  ),
                  const SizedBox(width: 6),
                  Icon(AppIcons.folder, size: 11, color: c.mutedFg),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.projectName.toUpperCase(),
                      style: TextStyle(
                        color: c.mutedFg,
                        fontSize: ThemeConstants.uiFontSizeLabel,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 120),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionChip(
                          icon: AppIcons.archiveRestore,
                          label: 'Unarchive All',
                          isDestructive: false,
                          onTap: widget.isLoading ? null : widget.onUnarchiveAll,
                        ),
                        const SizedBox(width: 5),
                        _ActionChip(
                          icon: AppIcons.trash,
                          label: 'Delete All',
                          isDestructive: true,
                          onTap: widget.isLoading ? null : () => _confirmDeleteAll(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded)
          Column(
            children: widget.sessions
                .map(
                  (s) => ArchivedSessionCard(
                    session: s,
                    isLoading: widget.isLoading,
                    onUnarchive: () => widget.onUnarchive(s.sessionId),
                    onDelete: () => widget.onDelete(s.sessionId),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _ActionChip extends StatefulWidget {
  const _ActionChip({required this.icon, required this.label, required this.isDestructive, required this.onTap});

  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
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
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 10, color: fg),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(color: fg, fontSize: ThemeConstants.uiFontSizeLabel, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
