import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Shown in the project list when there are no projects yet.
class SidebarEmptyState extends StatelessWidget {
  const SidebarEmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.folder, size: 32, color: c.faintFg),
          const SizedBox(height: 12),
          Text(
            'No projects yet',
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSize),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAdd,
            icon: Icon(AppIcons.add, size: 12),
            label: Text('Open folder', style: TextStyle(fontSize: ThemeConstants.uiFontSizeSmall)),
          ),
        ],
      ),
    );
  }
}
