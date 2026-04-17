// lib/features/archive/widgets/archive_error_view.dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';

class ArchiveErrorView extends StatelessWidget {
  const ArchiveErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Failed to load archived sessions.', style: TextStyle(color: c.error, fontSize: 11)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: c.textPrimary,
              side: BorderSide(color: c.borderColor),
              textStyle: const TextStyle(fontSize: 11),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class ProjectHeader extends StatelessWidget {
  const ProjectHeader({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        children: [
          Icon(AppIcons.folder, size: 12, color: c.mutedFg),
          const SizedBox(width: 6),
          Text(
            name.toUpperCase(),
            style: TextStyle(color: c.mutedFg, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}
