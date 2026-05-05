import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../data/project/models/project.dart';
import '../notifiers/git_actions.dart';
import '../notifiers/git_actions_failure.dart';
import '../../../features/project_sidebar/notifiers/project_sidebar_actions.dart';
import '../../project_actions/widgets/action_button.dart';
import '../../../layout/widgets/project_guard.dart';

/// Button shown in the top action bar when the active project is confirmed
/// to not be a git repository. Initialises a new repo on tap.
class InitGitButton extends ConsumerWidget {
  const InitGitButton({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(gitActionsProvider, (prev, next) {
      if (next is! AsyncError || !context.mounted) return;
      final failure = next.error;
      if (failure is! GitActionsFailure) return;
      final msg = switch (failure) {
        GitActionsNoUpstream(:final branch) =>
          'No upstream branch for $branch. Run `git push -u origin <branch>` in your terminal.',
        GitActionsAuthFailed() => 'Push failed — check your git credentials.',
        GitActionsConflict() => 'Pull failed — merge conflict detected. Resolve conflicts in your editor.',
        GitActionsGitError(:final message) => message,
        GitActionsUnknownError() => 'Git operation failed.',
      };
      AppSnackBar.show(context, msg, type: AppSnackBarType.error);
    });

    return ActionButton(
      icon: AppIcons.gitMerge,
      label: 'Initialize Git',
      onTap: () async {
        if (!ensureProjectAvailable(context, ref, project.id, project.path)) return;
        await ref.read(gitActionsProvider.notifier).initGit(project.path);
        if (ref.read(gitActionsProvider).hasError) return;
        ref.read(projectSidebarActionsProvider.notifier).refreshGitState(project.path);
        if (context.mounted) {
          AppSnackBar.show(context, 'Git repository initialized', type: AppSnackBarType.success);
        }
      },
    );
  }
}
