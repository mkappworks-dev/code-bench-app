import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/project/models/project_action.dart';

/// Dialog for adding a new project action (name + shell command).
///
/// Returns a [ProjectAction] via [Navigator.pop] on Save, or `null` on Cancel.
class AddActionDialog extends StatefulWidget {
  const AddActionDialog({super.key});

  @override
  State<AddActionDialog> createState() => _AddActionDialogState();
}

class _AddActionDialogState extends State<AddActionDialog> {
  final _nameController = TextEditingController();
  final _commandController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppDialog(
      icon: AppIcons.add,
      iconType: AppDialogIconType.teal,
      title: 'Add Action',
      hasInputField: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(controller: _nameController, maxLength: 40, labelText: 'Name (e.g. Run tests)'),
          const SizedBox(height: 8),
          AppTextField(
            controller: _commandController,
            labelText: 'Command (e.g. flutter test)',
            helperText: 'Arguments are split on whitespace. Quoted args are not supported.',
            fontFamily: ThemeConstants.editorFontFamily,
          ),
          const SizedBox(height: 10),
          // Security: the app runs without macOS App Sandbox (see
          // macos/Runner/README.md), so user-defined actions execute
          // with the user's full privileges. Make that visible.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.warning, size: 12, color: c.worktreeBadgeFg),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Commands run with your full user privileges. Only add actions '
                  'you would run in a terminal yourself.',
                  style: TextStyle(color: c.worktreeBadgeFg, fontSize: ThemeConstants.uiFontSizeLabel),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        AppDialogAction.cancel(onPressed: () => Navigator.of(context).pop()),
        AppDialogAction.primary(
          label: 'Save',
          onPressed: () {
            final name = _nameController.text.trim();
            final command = _commandController.text.trim();
            if (name.isEmpty || command.isEmpty) return;
            Navigator.of(context).pop(ProjectAction(name: name, command: command));
          },
        ),
      ],
    );
  }
}
