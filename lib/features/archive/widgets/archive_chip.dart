import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/buttons.dart';

enum ArchiveChipSize { group, card }

class ArchiveChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hoverFg = isDestructive ? c.error : c.accent;
    final hoverFill = isDestructive ? c.error.withValues(alpha: 0.12) : c.accentTintMid;
    final hoverBorder = isDestructive ? null : c.accentBorderTeal;
    final (padding, iconSize, gap, fontSize, radius) = switch (size) {
      ArchiveChipSize.group => (
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        10.0,
        4.0,
        ThemeConstants.uiFontSizeLabel,
        5.0,
      ),
      ArchiveChipSize.card => (
        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        12.0,
        5.0,
        ThemeConstants.uiFontSizeSmall,
        6.0,
      ),
    };

    return ChipButtonShell(
      label: label,
      onPressed: onTap,
      padding: padding,
      fontSize: fontSize,
      iconSize: iconSize,
      gap: gap,
      radius: radius,
      restFill: c.chipFill,
      hoverFill: hoverFill,
      foreground: c.chipText,
      hoverForeground: hoverFg,
      borderColor: c.chipStroke,
      hoverBorderColor: hoverBorder,
      fontWeight: FontWeight.w500,
      icon: icon,
    );
  }
}
