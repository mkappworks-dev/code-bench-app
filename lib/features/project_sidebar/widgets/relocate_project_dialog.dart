import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/project/models/project.dart';
import '../notifiers/project_sidebar_actions.dart';
import '../notifiers/project_sidebar_failure.dart';

class RelocateProjectDialog extends ConsumerStatefulWidget {
  const RelocateProjectDialog({super.key, required this.project});

  final Project project;

  static Future<bool?> show(BuildContext context, Project project) {
    return showDialog<bool>(
      context: context,
      builder: (_) => RelocateProjectDialog(project: project),
    );
  }

  @override
  ConsumerState<RelocateProjectDialog> createState() => _RelocateProjectDialogState();
}

class _RelocateProjectDialogState extends ConsumerState<RelocateProjectDialog> {
  String? _newPath;
  bool _submitting = false;
  String? _error;

  Future<void> _pick() async {
    final picked = await FilePicker.getDirectoryPath(dialogTitle: 'Select new folder for "${widget.project.name}"');
    if (picked != null) {
      setState(() {
        _newPath = picked;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_newPath == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(projectSidebarActionsProvider.notifier).relocateProject(widget.project.id, _newPath!);
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
      setState(
        () => _error = switch (failure) {
          ProjectSidebarInvalidPath() => 'The selected folder does not exist. Please choose a valid folder.',
          ProjectSidebarDuplicatePath() => 'A project at that path is already added.',
          ProjectSidebarStorageError() => 'Could not relocate project. Please try again.',
          ProjectSidebarUnknownError() => 'Could not relocate project. Please try again.',
        },
      );
    });

    return AppDialog(
      icon: AppIcons.folder,
      iconType: AppDialogIconType.teal,
      title: 'Relocate "${widget.project.name}"',
      maxWidth: 480,
      content: Builder(
        builder: (context) {
          final bc = AppColors.of(context);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Original path:', style: TextStyle(color: bc.mutedFg, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                widget.project.path,
                style: TextStyle(color: bc.textSecondary, fontSize: 11, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              Text('New path:', style: TextStyle(color: bc.mutedFg, fontSize: 11)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _newPath ?? '(none selected)',
                      style: TextStyle(
                        color: _newPath == null ? bc.faintFg : bc.textPrimary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: _submitting ? null : _pick, child: const Text('Browse…')),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: bc.error, fontSize: 11)),
              ],
            ],
          );
        },
      ),
      actions: [
        AppDialogAction.cancel(onPressed: _submitting ? () {} : () => Navigator.of(context).pop(false)),
        AppDialogAction.primary(
          label: _submitting ? 'Relocating…' : 'Relocate',
          onPressed: _submitting || _newPath == null ? null : _submit,
        ),
      ],
    );
  }
}
