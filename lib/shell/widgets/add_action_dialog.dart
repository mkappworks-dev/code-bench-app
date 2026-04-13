import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../data/project/models/project_action.dart';

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
    return AlertDialog(
      backgroundColor: ThemeConstants.inputSurface,
      title: const Text('Add Action', style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 14)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Name (e.g. Run tests)',
              labelStyle: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
            style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commandController,
            decoration: const InputDecoration(
              labelText: 'Command (e.g. flutter test)',
              labelStyle: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              helperText: 'Arguments are split on whitespace. Quoted args are not supported.',
              helperStyle: TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
            style: TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: ThemeConstants.uiFontSize,
              fontFamily: ThemeConstants.editorFontFamily,
            ),
          ),
          const SizedBox(height: 10),
          // Security: the app runs without macOS App Sandbox (see
          // macos/Runner/README.md), so user-defined actions execute
          // with the user's full privileges. Make that visible.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(AppIcons.warning, size: 12, color: ThemeConstants.worktreeBadgeFg),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Commands run with your full user privileges. Only add actions '
                  'you would run in a terminal yourself.',
                  style: TextStyle(color: ThemeConstants.worktreeBadgeFg, fontSize: ThemeConstants.uiFontSizeLabel),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: ThemeConstants.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final command = _commandController.text.trim();
            if (name.isEmpty || command.isEmpty) return;
            Navigator.of(context).pop(ProjectAction(name: name, command: command));
          },
          child: const Text('Save', style: TextStyle(color: ThemeConstants.accent)),
        ),
      ],
    );
  }
}
