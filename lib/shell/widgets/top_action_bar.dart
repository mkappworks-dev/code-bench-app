import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

    final project = projectsAsync.whenOrNull(
      data: (List<Project> list) {
        if (projectId == null) return null;
        try {
          return list.firstWhere((p) => p.id == projectId);
        } catch (_) {
          return null;
        }
      },
    );

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: ThemeConstants.inputBackground,
        border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
      ),
      child: Row(
        children: [
          // ── Left: title + badges ──────────────────────────────────────────
          Text(
            sessionTitle,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: ThemeConstants.uiFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (project != null) ...[
            const SizedBox(width: 8),
            // Project name badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: ThemeConstants.inputSurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                project.name,
                style: const TextStyle(
                  color: ThemeConstants.mutedFg,
                  fontSize: ThemeConstants.uiFontSizeLabel,
                ),
              ),
            ),
            // No Git badge (only when not a git repo)
            if (!project.isGit) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1F0A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'No Git',
                  style: TextStyle(
                    color: Color(0xFFE8A228),
                    fontSize: ThemeConstants.uiFontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
          const Spacer(),
          // ── Right: action buttons ─────────────────────────────────────────
          _ActionButton(
            icon: LucideIcons.plus,
            label: 'Add action',
            onTap: () {}, // wired in Phase 3
          ),
          const SizedBox(width: 5),
          _VsCodeDropdown(),
          const SizedBox(width: 5),
          // Git action: Commit & Push (git) or Initialize Git (no git)
          if (project != null && project.isGit)
            _CommitPushButton(onCommit: () {}, onDropdown: () {})
          else if (project != null && !project.isGit)
            _ActionButton(
              icon: LucideIcons.gitMerge,
              label: 'Initialize Git',
              onTap: () {}, // wired in Phase 3
            ),
        ],
      ),
    );
  }
}

// ── VS Code dropdown ─────────────────────────────────────────────────────────

class _VsCodeDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      icon: LucideIcons.code,
      label: 'VS Code',
      trailingCaret: true,
      onTap: () {
        // Stub — wired in Phase 3
      },
    );
  }
}

// ── Commit & Push split button ───────────────────────────────────────────────

class _CommitPushButton extends StatelessWidget {
  const _CommitPushButton({required this.onCommit, required this.onDropdown});
  final VoidCallback onCommit;
  final VoidCallback onDropdown;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left: Commit & Push
        GestureDetector(
          onTap: onCommit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeConstants.accent,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.gitCommitHorizontal,
                    size: 12, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'Commit & Push',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: ThemeConstants.uiFontSizeSmall),
                ),
              ],
            ),
          ),
        ),
        // Right: dropdown caret
        GestureDetector(
          onTap: onDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeConstants.accentLight,
              border: const Border(
                  left: BorderSide(color: ThemeConstants.accentDark)),
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(5)),
            ),
            child: const Icon(LucideIcons.chevronDown,
                size: 11, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ── Shared action button ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingCaret = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool trailingCaret;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: ThemeConstants.inputSurface,
          border: Border.all(color: ThemeConstants.deepBorder),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: ThemeConstants.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: ThemeConstants.uiFontSizeSmall,
              ),
            ),
            if (trailingCaret) ...[
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronDown,
                  size: 10, color: ThemeConstants.faintFg),
            ],
          ],
        ),
      ),
    );
  }
}
