import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';

/// Settings link pinned to the bottom of the project sidebar.
class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
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
              color: ThemeConstants.chipSurface,
              border: Border.all(color: ThemeConstants.chipBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.settings, size: 11, color: ThemeConstants.textSecondary),
                const SizedBox(width: 6),
                const Text('Settings', style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
