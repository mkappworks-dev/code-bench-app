import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_icons.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/project.dart';
import '../../features/chat/chat_notifier.dart';
import '../../features/project_sidebar/project_sidebar_notifier.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(activeProjectIdProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final activeSessionId = ref.watch(activeSessionIdProvider);
    final panelVisible = ref.watch(changesPanelVisibleProvider);

    Project? activeProject;
    if (projectId != null) {
      activeProject = projectsAsync.whenOrNull(data: (list) => list.firstWhereOrNull((p) => p.id == projectId));
    }

    // Count changes for the current session (watch unconditionally — Riverpod rule)
    final allChanges = ref.watch(appliedChangesProvider);
    final changeCount = activeSessionId != null ? (allChanges[activeSessionId]?.length ?? 0) : 0;

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
          Icon(AppIcons.storage, size: 10, color: ThemeConstants.faintFg),
          const SizedBox(width: 5),
          Text(
            'Local',
            style: const TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
          ),
          const Spacer(),
          // Centre-right: N changes indicator (hidden when 0)
          if (changeCount > 0) ...[
            GestureDetector(
              onTap: () => ref.read(changesPanelVisibleProvider.notifier).toggle(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: panelVisible ? ThemeConstants.accent : ThemeConstants.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$changeCount ${changeCount == 1 ? 'change' : 'changes'}',
                    style: TextStyle(
                      color: panelVisible ? ThemeConstants.accent : ThemeConstants.warning,
                      fontSize: ThemeConstants.uiFontSizeLabel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Right: Git branch
          if (activeProject != null && activeProject.isGit) ...[
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(color: ThemeConstants.success, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              activeProject.currentBranch ?? 'unknown',
              style: const TextStyle(color: ThemeConstants.success, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
          ] else if (activeProject != null) ...[
            Text(
              'Not git',
              style: const TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
          ],
        ],
      ),
    );
  }
}
