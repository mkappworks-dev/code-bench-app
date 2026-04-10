import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';

class RenameConversationDialog extends StatefulWidget {
  const RenameConversationDialog({super.key, required this.currentTitle});
  final String currentTitle;

  /// Shows the dialog and returns the new title, or null if cancelled.
  static Future<String?> show(BuildContext context, String currentTitle) {
    return showDialog<String>(
      context: context,
      builder: (_) => RenameConversationDialog(currentTitle: currentTitle),
    );
  }

  @override
  State<RenameConversationDialog> createState() => _RenameConversationDialogState();
}

class _RenameConversationDialogState extends State<RenameConversationDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title cannot be empty');
      return;
    }
    Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ThemeConstants.inputSurface,
      title: const Text('Rename Conversation', style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 14)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          errorText: _error,
          labelText: 'Conversation title',
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
