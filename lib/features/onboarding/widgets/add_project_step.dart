import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/buttons.dart';
import '../../../layout/notifiers/git_actions.dart';
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

  bool get _isGitRepo => _selectedPath != null && ref.read(gitActionsProvider.notifier).isGitRepo(_selectedPath!);

  Future<void> _browse() async {
    final result = await FilePicker.getDirectoryPath();
    if (result != null) setState(() => _selectedPath = result);
  }

  /// Validates a dropped payload and, if it looks like exactly one real
  /// directory, sets it as the selected path. Everything else surfaces a
  /// SnackBar and leaves `_selectedPath` untouched — the previous behaviour
  /// of silently falling back to the dropped file's parent turned a stray
  /// file-drop (e.g. from `~/Downloads`) into "add Downloads as a project".
  Future<void> _handleDrop(DropDoneDetails detail) async {
    setState(() => _isDragOver = false);

    if (detail.files.isEmpty) return;
    if (detail.files.length > 1) {
      _showDropError('Please drop a single folder');
      return;
    }

    final path = detail.files.first.path;
    final resolved = await ref.read(projectSidebarActionsProvider.notifier).resolveDroppedDirectory(path);
    if (resolved != null && mounted) setState(() => _selectedPath = resolved);
    // Errors are surfaced through projectSidebarActionsProvider state via ref.listen.
  }

  void _showDropError(String message) {
    if (!mounted) return;
    AppSnackBar.show(context, message, type: AppSnackBarType.error);
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
    final c = AppColors.of(context);
    ref.listen(projectSidebarActionsProvider, (_, next) {
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      final message = switch (failure) {
        ProjectSidebarDuplicatePath() => 'This project is already added.',
        ProjectSidebarInvalidPath(:final reason) => reason,
        ProjectSidebarPermissionDenied() =>
          'macOS blocked access to that folder. Click Allow on the system permission dialog, then try again.',
        ProjectSidebarStorageError() => 'Failed to save project — please try again.',
        ProjectSidebarUnknownError() => 'Failed to add project — please try again.',
        _ => 'Failed to add project — please try again.',
      };
      AppSnackBar.show(context, message, type: AppSnackBarType.error);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildDropZone(c)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ChipButton(label: 'Skip for now', onPressed: widget.onSkip, size: ChipButtonSize.medium),
            PrimaryButton(
              label: 'Add Project',
              onPressed: (_selectedPath == null || _adding) ? null : _addProject,
              loading: _adding,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropZone(AppColors c) {
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
          color: _isDragOver ? c.panelBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _isDragOver ? c.accent : c.borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.folderOpen, size: 40, color: _isDragOver ? c.accent : c.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Drop a folder here',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: ThemeConstants.uiFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '— or —',
              style: TextStyle(color: c.textMuted, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _browse,
              style: TextButton.styleFrom(
                foregroundColor: c.accent,
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

class _SelectedFolderPreview extends StatefulWidget {
  const _SelectedFolderPreview({required this.path, required this.isGit, required this.onBrowse});

  final String path;
  final bool isGit;
  final VoidCallback onBrowse;

  @override
  State<_SelectedFolderPreview> createState() => _SelectedFolderPreviewState();
}

class _SelectedFolderPreviewState extends State<_SelectedFolderPreview> {
  bool _changeHovered = false;

  String get _projectName => p.basename(widget.path);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.inputSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.faintFg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.folderOpen, size: 18, color: c.textSecondary),
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
                            color: c.textPrimary,
                            fontSize: ThemeConstants.uiFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.isGit) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.gitBadgeBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: c.gitBadgeBorder),
                            ),
                            child: Text(
                              'git',
                              style: TextStyle(color: c.gitBadgeText, fontSize: ThemeConstants.uiFontSizeBadge),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.path,
                      style: TextStyle(color: c.textMuted, fontSize: ThemeConstants.uiFontSizeLabel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _changeHovered = true),
            onExit: (_) => setState(() => _changeHovered = false),
            child: GestureDetector(
              onTap: widget.onBrowse,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _changeHovered ? 0.65 : 1.0,
                child: Text(
                  'Change folder',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
