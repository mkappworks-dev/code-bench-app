import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';

/// Settings link pinned to the bottom of the project sidebar.
class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = dark ? ThemeConstants.chipSurface : ThemeConstants.lightChipSurface;
    final borderColor = dark ? ThemeConstants.chipBorder : ThemeConstants.lightChipBorder;
    final textColor = dark ? ThemeConstants.textSecondary : ThemeConstants.lightChipText;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () => context.go('/settings'),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: chipColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.settings, size: 11, color: textColor),
                const SizedBox(width: 6),
                Text('Settings', style: TextStyle(color: textColor, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
