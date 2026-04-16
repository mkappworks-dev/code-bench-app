import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../data/project/models/project.dart';
import '../notifiers/project_sidebar_actions.dart';
import '../notifiers/project_sidebar_failure.dart';

class RemoveProjectDialog extends ConsumerStatefulWidget {
  const RemoveProjectDialog({super.key, required this.project});

  final Project project;

  static Future<bool?> show(BuildContext context, Project project) {
    return showDialog<bool>(
      context: context,
      builder: (_) => RemoveProjectDialog(project: project),
    );
  }

  @override
  ConsumerState<RemoveProjectDialog> createState() => _RemoveProjectDialogState();
}

class _RemoveProjectDialogState extends ConsumerState<RemoveProjectDialog> {
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(projectSidebarActionsProvider.notifier).removeProject(widget.project.id, deleteSessions: true);
      if (!mounted) return;
      if (!ref.read(projectSidebarActionsProvider).hasError) {
        Navigator.of(context).pop(true);
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
      AppSnackBar.show(context, 'Failed to remove project — please try again.', type: AppSnackBarType.error);
    });

    final isMissing = widget.project.status == ProjectStatus.missing;
    return AppDialog(
      icon: AppIcons.trash,
      iconType: AppDialogIconType.destructive,
      title: 'Remove "${widget.project.name}"?',
      maxWidth: 480,
      content: Builder(
        builder: (context) {
          final c = AppColors.of(context);
          return Text(
            isMissing
                ? 'This project folder is already missing from disk. '
                      'Removing it will delete the entry and all linked conversations from Code Bench.'
                : 'This will remove the project and all linked conversations from Code Bench. '
                      'The folder on disk will NOT be deleted.',
            style: TextStyle(color: c.mutedFg, fontSize: 11),
          );
        },
      ),
      actions: [
        AppDialogAction.cancel(onPressed: _submitting ? () {} : () => Navigator.of(context).pop(false)),
        AppDialogAction.destructive(
          label: _submitting ? 'Removing…' : 'Remove',
          onPressed: _submitting ? () {} : _submit,
        ),
      ],
    );
  }
}
