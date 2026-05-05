import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Compact action button used in the top action bar.
///
/// When [onTap] is `null` the button renders without an [InkWell] — callers
/// that wrap this in a [PopupMenuButton] must pass `null` to avoid
/// double-wrapping and swallowing the tap event.
class ActionButton extends StatelessWidget {
  const ActionButton({super.key, required this.icon, required this.label, this.onTap, this.trailingCaret = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool trailingCaret;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      constraints: const BoxConstraints.tightFor(height: ThemeConstants.actionButtonHeight),
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        widthFactor: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: c.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
            if (trailingCaret) ...[const SizedBox(width: 4), Icon(AppIcons.chevronDown, size: 10, color: c.faintFg)],
          ],
        ),
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(5), child: content);
  }
}
