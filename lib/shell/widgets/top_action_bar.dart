import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/chat_session.dart';
import '../../data/models/project.dart';
import '../../features/chat/chat_notifier.dart';
import '../../features/project_sidebar/project_sidebar_notifier.dart';

class TopActionBar extends ConsumerWidget {
  const TopActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionId = ref.watch(activeSessionIdProvider);
    final projectId = ref.watch(activeProjectIdProvider);
    final sessionsAsync = ref.watch(chatSessionsProvider);
    final projectsAsync = ref.watch(projectsProvider);

    final sessionTitle = sessionsAsync.whenOrNull(
          data: (List<ChatSession> list) {
            if (sessionId == null) return 'Code Bench';
            try {
              return list.firstWhere((s) => s.sessionId == sessionId).title;
            } catch (_) {
              return 'New Chat';
            }
          },
        ) ??
        'Code Bench';

    final projectName = projectsAsync.whenOrNull(
      data: (List<Project> list) {
        if (projectId == null) return null;
        try {
          return list.firstWhere((p) => p.id == projectId).name;
        } catch (_) {
          return null;
        }
      },
    );

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Row(
        children: [
          Text(
            sessionTitle,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (projectName != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                projectName,
                style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 10,
                ),
              ),
            ),
          ],
          const Spacer(),
          // Action buttons
          _ActionButton(
            icon: Icons.add,
            label: 'Add action',
            onTap: () {},
          ),
          const SizedBox(width: 5),
          _ActionButton(
            icon: Icons.folder_open_outlined,
            label: 'Open',
            onTap: () {},
          ),
          const SizedBox(width: 5),
          _ActionButton(
            icon: Icons.commit_outlined,
            label: 'Commit & Push',
            isPrimary: true,
            onTap: () {
              // Prompt user for review before committing
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isPrimary ? ThemeConstants.accent : const Color(0xFF1A1A1A),
          border: Border.all(
            color: isPrimary ? ThemeConstants.accent : const Color(0xFF222222),
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isPrimary ? Colors.white : const Color(0xFF888888),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : const Color(0xFF888888),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
