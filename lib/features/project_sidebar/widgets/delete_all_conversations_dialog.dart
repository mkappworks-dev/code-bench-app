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

class DeleteAllConversationsDialog extends ConsumerStatefulWidget {
  const DeleteAllConversationsDialog({super.key, required this.project});

  final Project project;

  static Future<bool?> show(BuildContext context, Project project) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteAllConversationsDialog(project: project),
    );
  }

  @override
  ConsumerState<DeleteAllConversationsDialog> createState() => _DeleteAllConversationsDialogState();
}

class _DeleteAllConversationsDialogState extends ConsumerState<DeleteAllConversationsDialog> {
  late final Future<int> _countFuture = ref
      .read(projectSidebarActionsProvider.notifier)
      .fetchSessionCount(widget.project.id);

  Future<void> _submit() async {
    final priorActiveSessionId = ref.read(activeSessionIdProvider);
    await ref.read(projectSidebarActionsProvider.notifier).deleteAllSessionsForProject(widget.project.id);
    if (!mounted) return;
    final actionState = ref.read(projectSidebarActionsProvider);
    if (actionState.hasError && actionState.error is ProjectSidebarFailure) {
      AppSnackBar.show(context, 'Failed to delete conversations — please try again.', type: AppSnackBarType.error);
      return;
    }
    Navigator.of(context).pop(true);
    if (priorActiveSessionId != null && ref.read(activeSessionIdProvider) == null && context.mounted) {
      context.go('/chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(projectSidebarActionsProvider).isLoading;
    return FutureBuilder<int>(
      future: _countFuture,
      builder: (_, snap) {
        final count = snap.data;
        final c = AppColors.of(context);
        final String message;
        if (count == null) {
          message = 'Loading conversations…';
        } else if (count == 0) {
          message = 'There are no active conversations to delete for this project.';
        } else {
          final phrase = count == 1 ? '1 active conversation' : '$count active conversations';
          message =
              'This will permanently delete $phrase for this project. '
              'Archived conversations are unaffected.';
        }
        return AppDialog(
          icon: AppIcons.trash,
          iconType: AppDialogIconType.destructive,
          title: 'Delete all conversations for "${widget.project.name}"?',
          maxWidth: 480,
          content: Text(message, style: TextStyle(color: c.mutedFg, fontSize: 11)),
          actions: [
            if (count == 0) ...[
              AppDialogAction.cancel(label: 'Close', onPressed: () => Navigator.of(context).pop(false)),
            ] else ...[
              AppDialogAction.cancel(onPressed: isSubmitting ? () {} : () => Navigator.of(context).pop(false)),
              AppDialogAction.destructive(
                label: isSubmitting ? 'Deleting…' : 'Delete all',
                onPressed: (count == null || isSubmitting) ? () {} : _submit,
              ),
            ],
          ],
        );
      },
    );
  }
}
