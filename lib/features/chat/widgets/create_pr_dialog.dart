import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';

class PrFormResult {
  const PrFormResult({
    required this.title,
    required this.body,
    required this.base,
    required this.draft,
  });
  final String title;
  final String body;
  final String base;
  final bool draft;
}

class CreatePrDialog extends ConsumerStatefulWidget {
  const CreatePrDialog({
    super.key,
    required this.initialTitle,
    required this.initialBody,
    required this.branches,
  });
  final String initialTitle;
  final String initialBody;
  final List<String> branches;

  static Future<PrFormResult?> show(
    BuildContext context, {
    required String initialTitle,
    required String initialBody,
    required List<String> branches,
  }) {
    return showDialog<PrFormResult>(
      context: context,
      builder: (_) => CreatePrDialog(
        initialTitle: initialTitle,
        initialBody: initialBody,
        branches: branches,
      ),
    );
  }

  @override
  ConsumerState<CreatePrDialog> createState() => _CreatePrDialogState();
}

class _CreatePrDialogState extends ConsumerState<CreatePrDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late String _base;
  bool _draft = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _bodyController = TextEditingController(text: widget.initialBody);
    _base = widget.branches.contains('main') ? 'main' : (widget.branches.isNotEmpty ? widget.branches.first : 'main');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ThemeConstants.inputSurface,
      title: const Text(
        'Create Pull Request',
        style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 14),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              maxLength: 70,
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
              style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                alignLabelWithHint: true,
              ),
              style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Base branch:',
                  style: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: widget.branches.contains(_base) ? _base : null,
                  dropdownColor: ThemeConstants.inputSurface,
                  style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
                  items: widget.branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _base = v);
                  },
                ),
                const Spacer(),
                const Text(
                  'Draft PR',
                  style: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
                Switch(
                  value: _draft,
                  onChanged: (v) => setState(() => _draft = v),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: ThemeConstants.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty) return;
            Navigator.of(context).pop(PrFormResult(
              title: title,
              body: _bodyController.text.trim(),
              base: _base,
              draft: _draft,
            ));
          },
          child: const Text('Create PR', style: TextStyle(color: ThemeConstants.accent)),
        ),
      ],
    );
  }
}
