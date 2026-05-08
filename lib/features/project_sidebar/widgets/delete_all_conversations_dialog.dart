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
  bool _submitting = false;
  int? _count;
  late final Future<int> _countFuture = ref
      .read(projectSidebarActionsProvider.notifier)
      .fetchSessionCount(widget.project.id);

  @override
  void initState() {
    super.initState();
    _countFuture.then((c) {
      if (mounted) setState(() => _count = c);
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(projectSidebarActionsProvider.notifier).deleteAllSessionsForProject(widget.project.id);
      if (!mounted) return;
      if (ref.read(projectSidebarActionsProvider).hasError) return;
      Navigator.of(context).pop(true);
      if (ref.read(activeSessionIdProvider) == null && context.mounted) {
        context.go('/chat');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(projectSidebarActionsProvider, (_, next) {
      if (!_submitting) return;
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      if (failure is! ProjectSidebarFailure) return;
      AppSnackBar.show(context, 'Failed to delete conversations — please try again.', type: AppSnackBarType.error);
    });

    return AppDialog(
      icon: AppIcons.trash,
      iconType: AppDialogIconType.destructive,
      title: 'Delete all conversations for "${widget.project.name}"?',
      maxWidth: 480,
      content: Builder(
        builder: (context) {
          final c = AppColors.of(context);
          return FutureBuilder<int>(
            future: _countFuture,
            builder: (_, snap) {
              final count = snap.data;
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
              return Text(message, style: TextStyle(color: c.mutedFg, fontSize: 11));
            },
          );
        },
      ),
      actions: [
        if (_count == 0) ...[
          AppDialogAction.primary(label: 'Close', onPressed: () => Navigator.of(context).pop(false)),
        ] else ...[
          AppDialogAction.cancel(onPressed: _submitting ? () {} : () => Navigator.of(context).pop(false)),
          AppDialogAction.destructive(
            label: _submitting ? 'Deleting…' : 'Delete all',
            onPressed: _submitting ? () {} : _submit,
          ),
        ],
      ],
    );
  }
}
