import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';

/// Settings link pinned to the bottom of the project sidebar.
class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
              color: c.chipFill,
              border: Border.all(color: c.chipStroke),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.settings, size: 11, color: c.chipText),
                const SizedBox(width: 6),
                Text('Settings', style: TextStyle(color: c.chipText, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
