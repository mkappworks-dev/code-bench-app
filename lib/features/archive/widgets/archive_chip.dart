import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';

enum ArchiveChipSize { group, card }

class ArchiveChip extends StatefulWidget {
  const ArchiveChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isDestructive,
    this.onTap,
    this.size = ArchiveChipSize.group,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback? onTap;
  final ArchiveChipSize size;

  @override
  State<ArchiveChip> createState() => _ArchiveChipState();
}

class _ArchiveChipState extends State<ArchiveChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hovered = _hovered;
    final fg = widget.isDestructive ? (hovered ? c.error : c.chipText) : (hovered ? c.accent : c.chipText);
    final bg = widget.isDestructive
        ? (hovered ? c.error.withValues(alpha: 0.12) : c.chipFill)
        : (hovered ? c.accentTintMid : c.chipFill);
    final border = widget.isDestructive
        ? (hovered ? c.destructiveBorder : c.chipStroke)
        : (hovered ? c.accentBorderTeal : c.chipStroke);
    final padding = switch (widget.size) {
      ArchiveChipSize.group => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ArchiveChipSize.card => const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    };
    final iconSize = switch (widget.size) {
      ArchiveChipSize.group => 10.0,
      ArchiveChipSize.card => 12.0,
    };
    final gap = switch (widget.size) {
      ArchiveChipSize.group => 4.0,
      ArchiveChipSize.card => 5.0,
    };
    final fontSize = switch (widget.size) {
      ArchiveChipSize.group => ThemeConstants.uiFontSizeLabel,
      ArchiveChipSize.card => ThemeConstants.uiFontSizeSmall,
    };
    final radius = switch (widget.size) {
      ArchiveChipSize.group => 5.0,
      ArchiveChipSize.card => 6.0,
    };

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: iconSize, color: fg),
              SizedBox(width: gap),
              Text(
                widget.label,
                style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
