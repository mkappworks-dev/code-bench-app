import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';

enum DenylistChipVariant { baseline, userAdded, suppressed }

class DenylistChip extends StatelessWidget {
  const DenylistChip({super.key, required this.label, required this.variant, required this.onRemove});

  final String label;
  final DenylistChipVariant variant;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (fg, bg, border, strike) = switch (variant) {
      DenylistChipVariant.baseline => (c.accent, c.accentTintMid, c.accentTintLight, false),
      DenylistChipVariant.userAdded => (c.success, c.successTintBg, c.accent.withValues(alpha: 0.3), false),
      DenylistChipVariant.suppressed => (c.error, c.errorTintBg, c.error.withValues(alpha: 0.4), true),
    };
    return Tooltip(
      message: switch (variant) {
        DenylistChipVariant.suppressed => 'Click × to re-block',
        _ => 'Click × to remove',
      },
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontFamily: ThemeConstants.editorFontFamily,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  decoration: strike ? TextDecoration.lineThrough : null,
                  decorationColor: fg,
                ),
              ),
              const SizedBox(width: 6),
              Icon(AppIcons.close, size: 11, color: fg.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
