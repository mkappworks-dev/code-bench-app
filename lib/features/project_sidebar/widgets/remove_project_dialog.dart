import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/project.dart';
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
  bool _alsoDeleteSessions = false;
  bool _submitting = false;
  int _sessionCount = 0;
  bool _sessionCountLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSessionCount();
  }

  Future<void> _loadSessionCount() async {
    try {
      final sessions = await ref.read(projectSidebarActionsProvider.notifier).getSessionsByProject(widget.project.id);
      if (!mounted) return;
      setState(() {
        _sessionCount = sessions.length;
        _sessionCountLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      // Mark loaded so the dialog remains usable. Sessions are not deleted
      // without an explicit checkbox, so this is safe — the user just won't
      // see the cascade-delete option if the count query failed.
      setState(() {
        _sessionCount = 0;
        _sessionCountLoaded = true;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(projectSidebarActionsProvider.notifier)
          .removeProject(widget.project.id, deleteSessions: _alsoDeleteSessions);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to remove project — please try again.')));
    });

    final isMissing = widget.project.status == ProjectStatus.missing;
    return AlertDialog(
      backgroundColor: ThemeConstants.panelBackground,
      title: Text(
        'Remove "${widget.project.name}"?',
        style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 14),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 360, maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMissing
                  ? 'This project folder is already missing from disk. '
                        'Removing it will only delete the entry from Code Bench.'
                  : 'This will remove the project from Code Bench. '
                        'The folder on disk will NOT be deleted.',
              style: TextStyle(color: ThemeConstants.mutedFg, fontSize: 11),
            ),
            const SizedBox(height: 12),
            if (_sessionCountLoaded && _sessionCount > 0)
              InkWell(
                onTap: _submitting ? null : () => setState(() => _alsoDeleteSessions = !_alsoDeleteSessions),
                child: Row(
                  children: [
                    Checkbox(
                      value: _alsoDeleteSessions,
                      onChanged: _submitting ? null : (v) => setState(() => _alsoDeleteSessions = v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        'Also delete $_sessionCount '
                        '${_sessionCount == 1 ? "conversation" : "conversations"} '
                        'linked to this project',
                        style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        TextButton(
          onPressed: _submitting ? null : _submit,
          style: TextButton.styleFrom(foregroundColor: ThemeConstants.error),
          child: Text(_submitting ? 'Removing…' : 'Remove'),
        ),
      ],
    );
  }
}
