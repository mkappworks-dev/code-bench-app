import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/git/repository/git_repository_impl.dart';
import '../../project_sidebar/notifiers/project_sidebar_actions.dart';
import '../../project_sidebar/notifiers/project_sidebar_failure.dart';

class AddProjectStep extends ConsumerStatefulWidget {
  const AddProjectStep({super.key, required this.onComplete, required this.onSkip});
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  ConsumerState<AddProjectStep> createState() => _AddProjectStepState();
}

class _AddProjectStepState extends ConsumerState<AddProjectStep> {
  String? _selectedPath;
  bool _adding = false;
  bool _isDragOver = false;

  bool get _isGitRepo => _selectedPath != null && ref.read(gitRepositoryProvider).isGitRepo(_selectedPath!);

  Future<void> _browse() async {
    final result = await FilePicker.getDirectoryPath();
    if (result != null) setState(() => _selectedPath = result);
  }

  /// Validates a dropped payload and, if it looks like exactly one real
  /// directory, sets it as the selected path. Everything else surfaces a
  /// SnackBar and leaves `_selectedPath` untouched — the previous behaviour
  /// of silently falling back to the dropped file's parent turned a stray
  /// file-drop (e.g. from `~/Downloads`) into "add Downloads as a project".
  void _handleDrop(DropDoneDetails detail) {
    setState(() => _isDragOver = false);

    if (detail.files.isEmpty) return;
    if (detail.files.length > 1) {
      _showDropError('Please drop a single folder');
      return;
    }

    final path = detail.files.first.path;
    try {
      final resolved = ref.read(projectSidebarActionsProvider.notifier).resolveDroppedDirectory(path);
      setState(() => _selectedPath = resolved);
    } on ArgumentError catch (e) {
      _showDropError(e.message as String);
    }
  }

  void _showDropError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addProject() async {
    if (_selectedPath == null) return;
    setState(() => _adding = true);
    try {
      await ref.read(projectSidebarActionsProvider.notifier).addExistingFolder(_selectedPath!);
      if (!mounted) return;
      if (!ref.read(projectSidebarActionsProvider).hasError) {
        widget.onComplete();
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(projectSidebarActionsProvider, (_, next) {
      if (!_adding) return;
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      final message = switch (failure) {
        ProjectSidebarDuplicatePath() => 'This project is already added.',
        ProjectSidebarInvalidPath() => 'Invalid folder path.',
        ProjectSidebarStorageError() => 'Failed to save project — please try again.',
        ProjectSidebarUnknownError() => 'Failed to add project — please try again.',
        _ => 'Failed to add project — please try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildDropZone()),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: widget.onSkip,
              style: TextButton.styleFrom(
                foregroundColor: ThemeConstants.textMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Skip for now', style: TextStyle(fontSize: 12)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ThemeConstants.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: _selectedPath == null || _adding ? null : _addProject,
              child: _adding
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add Project', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropZone() {
    if (_selectedPath != null) {
      return _SelectedFolderPreview(path: _selectedPath!, isGit: _isGitRepo, onBrowse: _browse);
    }

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragOver = true),
      onDragExited: (_) => setState(() => _isDragOver = false),
      onDragDone: _handleDrop,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isDragOver ? ThemeConstants.panelBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _isDragOver ? ThemeConstants.accent : ThemeConstants.borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.folderOpen,
              size: 40,
              color: _isDragOver ? ThemeConstants.accent : ThemeConstants.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Drop a folder here',
              style: TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: ThemeConstants.uiFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '— or —',
              style: TextStyle(color: ThemeConstants.textMuted, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _browse,
              style: TextButton.styleFrom(
                foregroundColor: ThemeConstants.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('Browse for folder…', style: TextStyle(fontSize: ThemeConstants.uiFontSize)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selected folder preview ────────────────────────────────────────────────

class _SelectedFolderPreview extends StatelessWidget {
  const _SelectedFolderPreview({required this.path, required this.isGit, required this.onBrowse});

  final String path;
  final bool isGit;
  final VoidCallback onBrowse;

  String get _projectName {
    final segments = path.split(Platform.pathSeparator)..removeWhere((s) => s.isEmpty);
    return segments.isNotEmpty ? segments.last : path;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeConstants.inputSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeConstants.faintFg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.folderOpen, size: 18, color: ThemeConstants.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _projectName,
                          style: TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: ThemeConstants.uiFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isGit) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ThemeConstants.gitBadgeBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: ThemeConstants.gitBadgeBorder),
                            ),
                            child: Text(
                              'git',
                              style: TextStyle(
                                color: ThemeConstants.gitBadgeText,
                                fontSize: ThemeConstants.uiFontSizeBadge,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      path,
                      style: TextStyle(color: ThemeConstants.textMuted, fontSize: ThemeConstants.uiFontSizeLabel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onBrowse,
            child: Text(
              'Change folder',
              style: TextStyle(
                color: ThemeConstants.accent,
                fontSize: ThemeConstants.uiFontSizeSmall,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
