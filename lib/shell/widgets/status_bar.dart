import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/project.dart';
import '../../features/project_sidebar/project_sidebar_notifier.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(activeProjectIdProvider);
    final projectsAsync = ref.watch(projectsProvider);

    Project? activeProject;
    if (projectId != null) {
      activeProject = projectsAsync.whenOrNull(
        data: (list) {
          try {
            return list.firstWhere((p) => p.id == projectId);
          } catch (_) {
            return null;
          }
        },
      );
    }

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: ThemeConstants.activityBar,
        border: Border(top: BorderSide(color: ThemeConstants.borderColor)),
      ),
      child: Row(
        children: [
          // Left: Local indicator
          Icon(
            LucideIcons.hardDrive,
            size: 10,
            color: ThemeConstants.faintFg,
          ),
          const SizedBox(width: 5),
          Text(
            'Local',
            style: const TextStyle(
              color: ThemeConstants.faintFg,
              fontSize: ThemeConstants.uiFontSizeLabel,
            ),
          ),
          const Spacer(),
          // Right: Git branch
          if (activeProject != null && activeProject.isGit) ...[
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: ThemeConstants.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              activeProject.currentBranch ?? 'unknown',
              style: const TextStyle(
                color: ThemeConstants.success,
                fontSize: ThemeConstants.uiFontSizeLabel,
              ),
            ),
          ] else if (activeProject != null) ...[
            Text(
              'Not git',
              style: const TextStyle(
                color: ThemeConstants.faintFg,
                fontSize: ThemeConstants.uiFontSizeLabel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
