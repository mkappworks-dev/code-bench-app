import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';

/// Settings link pinned to the bottom of the project sidebar.
class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/settings'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(AppIcons.settings, size: 14, color: ThemeConstants.mutedFg),
            const SizedBox(width: 7),
            const Text(
              'Settings',
              style: TextStyle(color: ThemeConstants.mutedFg, fontSize: ThemeConstants.uiFontSize),
            ),
          ],
        ),
      ),
    );
  }
}
