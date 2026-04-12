import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/project.dart';
import '../notifiers/top_action_bar_notifier.dart';
import 'actions_dropdown.dart';
import 'commit_push_button.dart';
import 'init_git_button.dart';
import 'code_dropdown.dart';

/// Top bar showing the active session title, project badges, and action
/// buttons (Actions dropdown, VS Code, Commit & Push / Initialize Git).
///
/// Data derivation lives in [topActionBarStateProvider]; each button is
/// extracted to its own widget file.
class TopActionBar extends ConsumerWidget {
  const TopActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(topActionBarStateProvider);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: ThemeConstants.inputBackground,
        border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
      ),
      child: Row(
        children: [
          // ── Left: title + badges ────────────────────────────────────────
          Text(
            s.sessionTitle,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: ThemeConstants.uiFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (s.project != null) ...[
            const SizedBox(width: 8),
            // Project name badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: ThemeConstants.inputSurface, borderRadius: BorderRadius.circular(4)),
              child: Text(
                s.project!.name,
                style: const TextStyle(color: ThemeConstants.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
              ),
            ),
            // No Git badge (only when we've definitively observed the path
            // is not a git repo — skipped during loading/error).
            if (s.isGit == false) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: ThemeConstants.worktreeBadgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'No Git',
                  style: TextStyle(
                    color: ThemeConstants.worktreeBadgeFg,
                    fontSize: ThemeConstants.uiFontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
          const Spacer(),
          // ── Right: action buttons ───────────────────────────────────────
          if (s.project != null)
            Opacity(
              opacity: s.project!.status == ProjectStatus.missing ? 0.4 : 1.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionsDropdown(project: s.project!),
                  const SizedBox(width: 5),
                  CodeDropdown(projectId: s.project!.id, projectPath: s.project!.path),
                  const SizedBox(width: 5),
                  // Git action: Commit & Push (git) or Initialize Git
                  // (confirmed non-git). During loading/error (isGit == null)
                  // render a spacer so the layout doesn't jump and the user
                  // is never offered "Init Git" on a repo that already exists.
                  if (s.isGit == true)
                    CommitPushButton(project: s.project!)
                  else if (s.isGit == false)
                    InitGitButton(project: s.project!)
                  else
                    const SizedBox(width: 1, height: ThemeConstants.actionButtonHeight),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
