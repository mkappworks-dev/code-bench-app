import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/models/project.dart';
import '../../../services/project/project_service.dart';

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
      await ref.read(projectServiceProvider).relocateProject(widget.project.id, _newPath!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      dLog('[RelocateProjectDialog] relocate failed: $e\n$st');
      setState(() {
        _submitting = false;
        _error = e is ArgumentError
            ? 'The selected folder does not exist. Please choose a valid folder.'
            : e is DuplicateProjectPathException
            ? e.toString()
            : 'Could not relocate project. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        'Relocate "${widget.project.name}"',
        style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 14),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 360, maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original path:', style: TextStyle(color: ThemeConstants.mutedFg, fontSize: 11)),
            const SizedBox(height: 2),
            Text(
              widget.project.path,
              style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 11, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            Text('New path:', style: TextStyle(color: ThemeConstants.mutedFg, fontSize: 11)),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _newPath ?? '(none selected)',
                    style: TextStyle(
                      color: _newPath == null ? ThemeConstants.faintFg : ThemeConstants.textPrimary,
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
              Text(_error!, style: const TextStyle(color: ThemeConstants.error, fontSize: 11)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        TextButton(
          onPressed: _submitting || _newPath == null ? null : _submit,
          child: Text(_submitting ? 'Relocating…' : 'Relocate'),
        ),
      ],
    );
  }
}
