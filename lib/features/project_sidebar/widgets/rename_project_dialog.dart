import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/theme_constants.dart';

class RenameProjectDialog extends StatefulWidget {
  const RenameProjectDialog({super.key, required this.currentName});
  final String currentName;

  /// Shows the dialog and returns the new name, or null if cancelled.
  static Future<String?> show(BuildContext context, String currentName) {
    return showDialog<String>(
      context: context,
      builder: (_) => RenameProjectDialog(currentName: currentName),
    );
  }

  @override
  State<RenameProjectDialog> createState() => _RenameProjectDialogState();
}

class _RenameProjectDialogState extends State<RenameProjectDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name cannot be empty');
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ThemeConstants.inputSurface,
      title: const Text('Rename Project', style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 14)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        inputFormatters: [LengthLimitingTextInputFormatter(60)],
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          errorText: _error,
          labelText: 'Project name',
          labelStyle: const TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
        ),
        style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: ThemeConstants.textSecondary)),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Rename', style: TextStyle(color: ThemeConstants.accent)),
        ),
      ],
    );
  }
}
