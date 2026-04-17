import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';

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
    return AppDialog(
      icon: AppIcons.rename,
      iconType: AppDialogIconType.teal,
      title: 'Rename Conversation',
      hasInputField: true,
      content: AppTextField(
        controller: _controller,
        autofocus: true,
        onSubmitted: (_) => _submit(),
        errorText: _error,
        labelText: 'Conversation title',
      ),
      actions: [
        AppDialogAction.cancel(onPressed: () => Navigator.of(context).pop()),
        AppDialogAction.primary(label: 'Rename', onPressed: _submit),
      ],
    );
  }
}
