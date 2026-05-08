import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../data/project/models/project.dart';
import '../../chat/notifiers/chat_notifier.dart';
import '../notifiers/project_sidebar_actions.dart';
import '../notifiers/project_sidebar_failure.dart';

class ArchiveAllConversationsDialog extends ConsumerWidget {
  const ArchiveAllConversationsDialog({super.key, required this.project});

  final Project project;

  static Future<bool?> show(BuildContext context, Project project) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ArchiveAllConversationsDialog(project: project),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final priorActiveSessionId = ref.read(activeSessionIdProvider);
    await ref.read(projectSidebarActionsProvider.notifier).archiveAllSessionsForProject(project.id);
    if (!context.mounted) return;
    final actionState = ref.read(projectSidebarActionsProvider);
    if (actionState.hasError && actionState.error is ProjectSidebarFailure) {
      AppSnackBar.show(context, 'Failed to archive conversations — please try again.', type: AppSnackBarType.error);
      return;
    }
    Navigator.of(context).pop(true);
    if (priorActiveSessionId != null && ref.read(activeSessionIdProvider) == null && context.mounted) {
      context.go('/chat');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(projectSidebarActionsProvider).isLoading;
    return AppDialog(
      icon: AppIcons.archive,
      iconType: AppDialogIconType.teal,
      title: 'Archive all conversations for "${project.name}"?',
      maxWidth: 480,
      content: Builder(
        builder: (context) {
          final c = AppColors.of(context);
          return Text(
            'All active conversations for this project will be moved to the archive. '
            'You can restore them from the archive at any time.',
            style: TextStyle(color: c.mutedFg, fontSize: 11),
          );
        },
      ),
      actions: [
        AppDialogAction.cancel(onPressed: isSubmitting ? () {} : () => Navigator.of(context).pop(false)),
        AppDialogAction.primary(
          label: isSubmitting ? 'Archiving…' : 'Archive all',
          onPressed: isSubmitting ? null : () => _submit(context, ref),
        ),
      ],
    );
  }
}
