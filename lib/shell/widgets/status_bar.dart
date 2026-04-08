import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Row(
        children: [
          // Left: Local indicator
          const Icon(
            Icons.folder_outlined,
            size: 10,
            color: Color(0xFF444444),
          ),
          const SizedBox(width: 5),
          const Text(
            'Local',
            style: TextStyle(color: Color(0xFF444444), fontSize: 10),
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
                fontSize: 10,
              ),
            ),
          ] else if (activeProject != null) ...[
            const Text(
              'Not git',
              style: TextStyle(color: Color(0xFF444444), fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
