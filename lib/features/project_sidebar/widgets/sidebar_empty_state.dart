import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';

/// Shown in the project list when there are no projects yet.
class SidebarEmptyState extends StatelessWidget {
  const SidebarEmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.folder, size: 32, color: ThemeConstants.faintFg),
          const SizedBox(height: 12),
          const Text(
            'No projects yet',
            style: TextStyle(color: ThemeConstants.mutedFg, fontSize: ThemeConstants.uiFontSize),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAdd,
            icon: Icon(AppIcons.add, size: 12),
            label: const Text('Open folder', style: TextStyle(fontSize: ThemeConstants.uiFontSizeSmall)),
          ),
        ],
      ),
    );
  }
}
