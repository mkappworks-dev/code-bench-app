import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/datasources/local/general_preferences.dart';

class CommitDialog extends ConsumerStatefulWidget {
  const CommitDialog({super.key, required this.initialMessage});
  final String initialMessage;

  /// Shows the dialog and returns the confirmed commit message, or null if cancelled.
  static Future<String?> show(BuildContext context, String initialMessage) {
    return showDialog<String>(
      context: context,
      builder: (_) => CommitDialog(initialMessage: initialMessage),
    );
  }

  @override
  ConsumerState<CommitDialog> createState() => _CommitDialogState();
}

class _CommitDialogState extends ConsumerState<CommitDialog> {
  late final TextEditingController _controller;
  bool _autoCommit = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMessage);
    _loadAutoCommit();
  }

  Future<void> _loadAutoCommit() async {
    final prefs = ref.read(generalPreferencesProvider);
    final value = await prefs.getAutoCommit();
    if (mounted) setState(() => _autoCommit = value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ThemeConstants.inputSurface,
      title: const Text('Commit', style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 14)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              maxLength: 72,
              decoration: const InputDecoration(
                labelText: 'Commit message',
                labelStyle: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
              style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: _autoCommit,
                  onChanged: (v) async {
                    setState(() => _autoCommit = v);
                    await ref.read(generalPreferencesProvider).setAutoCommit(v);
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  '⚡ Auto-commit future commits',
                  style: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
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
            final msg = _controller.text.trim();
            if (msg.isEmpty) return;
            Navigator.of(context).pop(msg);
          },
          child: const Text('Commit', style: TextStyle(color: ThemeConstants.accent)),
        ),
      ],
    );
  }
}
