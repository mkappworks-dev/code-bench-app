import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/_core/preferences/general_preferences.dart';
import '../../../data/git/models/git_changed_file.dart';
import '../../../shell/notifiers/git_actions.dart';

class CommitDialog extends ConsumerStatefulWidget {
  const CommitDialog({super.key, required this.initialMessage, required this.projectPath});

  final String initialMessage;
  final String projectPath;

  /// Shows the commit dialog and returns the confirmed message, or null if cancelled.
  static Future<String?> show(BuildContext context, String initialMessage, {required String projectPath}) {
    return showDialog<String>(
      context: context,
      builder: (_) => CommitDialog(initialMessage: initialMessage, projectPath: projectPath),
    );
  }

  @override
  ConsumerState<CommitDialog> createState() => _CommitDialogState();
}

class _CommitDialogState extends ConsumerState<CommitDialog> {
  late final TextEditingController _controller;
  bool _autoCommit = false;
  List<GitChangedFile> _changedFiles = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMessage);
    unawaited(_loadAutoCommit());
    unawaited(_loadChangedFiles());
  }

  Future<void> _loadAutoCommit() async {
    final value = await ref.read(generalPreferencesProvider).getAutoCommit();
    if (mounted) setState(() => _autoCommit = value);
  }

  Future<void> _loadChangedFiles() async {
    final files = await ref.read(gitActionsProvider.notifier).fetchChangedFiles(widget.projectPath);
    if (mounted) setState(() => _changedFiles = files);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final msg = _controller.text.trim();
    if (msg.isEmpty) return;
    Navigator.of(context).pop(msg);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => AppDialog(
        icon: AppIcons.gitCommit,
        iconType: AppDialogIconType.teal,
        title: 'Commit changes',
        hasInputField: true,
        maxWidth: 440,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_changedFiles.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(child: Column(children: _changedFiles.map(_buildFileRow).toList())),
              ),
              const SizedBox(height: 10),
            ],
            Builder(
              builder: (context) {
                final c = AppColors.of(context);
                return TextField(
                  controller: _controller,
                  maxLines: 3,
                  maxLength: 72,
                  decoration: InputDecoration(
                    labelText: 'Commit message',
                    labelStyle: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                  ),
                  style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSize),
                );
              },
            ),
            const SizedBox(height: 4),
            Builder(
              builder: (context) {
                final c = AppColors.of(context);
                return Row(
                  children: [
                    Switch(
                      value: _autoCommit,
                      onChanged: (v) async {
                        setState(() => _autoCommit = v);
                        await ref.read(generalPreferencesProvider).setAutoCommit(v);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '⚡ Auto-commit future commits',
                      style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.of(context).pop()),
          AppDialogAction.primary(label: 'Commit', onPressed: _controller.text.trim().isEmpty ? null : _submit),
        ],
      ),
    );
  }

  Widget _buildFileRow(GitChangedFile file) {
    // context is available via the ListenableBuilder → Builder chain above
    // but _buildFileRow is called from within that builder scope; we need
    // to obtain context from the widget tree. Use a Builder wrapper:
    return Builder(
      builder: (context) {
        final c = AppColors.of(context);
        final (badgeColor, badgeBg) = switch (file.status) {
          GitChangedFileStatus.modified => (c.warning, c.warningBadgeBg),
          GitChangedFileStatus.added => (c.accent, c.successBadgeBg),
          GitChangedFileStatus.deleted => (c.error, c.errorBadgeBg),
          GitChangedFileStatus.renamed => (c.textSecondary, c.inputSurface),
        };

        return SizedBox(
          height: 22,
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(2)),
                alignment: Alignment.center,
                child: Text(
                  file.status.badge,
                  style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  file.path,
                  style: TextStyle(color: c.textPrimary, fontSize: 11, fontFamily: ThemeConstants.editorFontFamily),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('+${file.additions}', style: TextStyle(color: c.success, fontSize: 10)),
              const SizedBox(width: 4),
              Text('−${file.deletions}', style: TextStyle(color: c.error, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }
}
