import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snack_bar.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/apply/models/applied_change.dart';
import '../../../data/project/models/project.dart';
import '../../../features/project_sidebar/notifiers/project_sidebar_notifier.dart';
import '../../git/notifiers/git_actions.dart';
import '../notifiers/chat_notifier.dart';
import '../notifiers/code_apply_actions.dart';
import '../notifiers/code_apply_failure.dart';
import 'conflict_merge_view.dart';

class ChangesPanel extends ConsumerWidget {
  const ChangesPanel({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allChanges = ref.watch(appliedChangesProvider);
    final changes = allChanges[sessionId] ?? [];

    // Group changes by messageId preserving insertion order
    final grouped = <String, List<AppliedChange>>{};
    for (final change in changes) {
      grouped.putIfAbsent(change.messageId, () => []).add(change);
    }

    // Resolve active project for path.
    // Revert uses a *synchronous* `gitRepositoryProvider.isGitRepo` check rather than
    // reading `gitLiveStateProvider`. The provider's `AsyncValue.value`
    // would fall back to `false` during loading/error and silently degrade
    // the revert mechanism — a destructive mismatch if this gate is wrong.
    final projectId = ref.watch(activeProjectIdProvider);
    final project = switch (ref.watch(projectsProvider)) {
      AsyncData(:final value) => value.firstWhereOrNull((proj) => proj.id == projectId),
      _ => null,
    };

    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.sidebarBackground,
        border: Border(left: BorderSide(color: c.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.borderColor)),
            ),
            child: Text(
              'Changes',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: ThemeConstants.uiFontSizeSmall,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Change entries
          Expanded(
            child: changes.isEmpty
                ? Center(
                    child: Text(
                      'No changes yet',
                      style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: grouped.entries.toList().asMap().entries.expand((indexed) {
                      final entry = indexed.value;
                      final groupIndex = indexed.key + 1;
                      return [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                          child: Text(
                            'Message $groupIndex',
                            style: TextStyle(color: c.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
                          ),
                        ),
                        ...entry.value.map((change) => _ChangeEntry(change: change, project: project)),
                      ];
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Single change entry ───────────────────────────────────────────────────────

class _ChangeEntry extends ConsumerStatefulWidget {
  const _ChangeEntry({required this.change, required this.project});

  final AppliedChange change;
  final Project? project;

  @override
  ConsumerState<_ChangeEntry> createState() => _ChangeEntryState();
}

class _ChangeEntryState extends ConsumerState<_ChangeEntry> {
  // Cached once per widget lifecycle so the badge doesn't flicker between
  // rebuilds. The entry is short-lived — it goes away as soon as revert
  // succeeds — so a stale result is acceptable.
  late final Future<bool> _editedFuture;

  bool _reverting = false;

  @override
  void initState() {
    super.initState();
    final checksum = widget.change.contentChecksum;
    _editedFuture = checksum == null
        ? Future.value(false)
        : ref.read(codeApplyActionsProvider.notifier).isExternallyModified(widget.change.filePath, checksum);
  }

  Future<void> _handleRevert() async {
    final project = widget.project;
    if (project == null) return;

    final isEdited = await _editedFuture;
    if (!mounted) return;

    if (!isEdited) {
      // No conflict — revert directly.
      final isGit = ref.read(gitActionsProvider.notifier).isGitRepo(project.path);
      setState(() => _reverting = true);
      try {
        await ref
            .read(codeApplyActionsProvider.notifier)
            .revertChange(change: widget.change, isGit: isGit, projectPath: project.path);
      } finally {
        if (mounted) setState(() => _reverting = false);
      }
      return;
    }

    // File was modified out-of-band — show conflict merge view.
    final currentContent = await ref
        .read(codeApplyActionsProvider.notifier)
        .readFileContent(widget.change.filePath, project.path);
    if (!mounted) return;
    if (currentContent == null) {
      // Refuse to open the merge view on an unreadable file — accepting the
      // merge would overwrite the real file with an empty / placeholder body.
      AppSnackBar.show(
        context,
        'Could not read current file contents — try again after resolving file access.',
        type: AppSnackBarType.error,
      );
      return;
    }

    final isGit = ref.read(gitActionsProvider.notifier).isGitRepo(project.path);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AppDialog(
        icon: AppIcons.warning,
        iconType: AppDialogIconType.teal,
        title: 'File externally modified',
        maxWidth: 580,
        content: ConflictMergeView(
          change: widget.change,
          currentContent: currentContent,
          onAcceptRevert: () async {
            Navigator.of(dialogCtx).pop();
            setState(() => _reverting = true);
            try {
              await ref
                  .read(codeApplyActionsProvider.notifier)
                  .revertChange(change: widget.change, isGit: isGit, projectPath: project.path);
            } finally {
              if (mounted) setState(() => _reverting = false);
            }
          },
          onKeepCurrent: () => Navigator.of(dialogCtx).pop(),
        ),
        // ConflictMergeView provides its own action buttons.
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(codeApplyActionsProvider, (_, next) {
      if (!_reverting) return; // not our operation
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      if (failure is! CodeApplyFailure) return;
      showErrorSnackBar(context, switch (failure) {
        CodeApplyProjectMissing() => 'Project folder is missing.',
        CodeApplyOutsideProject() => 'This file is outside the current project.',
        CodeApplyTooLarge(:final bytes) => 'Content too large to apply ($bytes bytes).',
        CodeApplyDiskWrite(:final message) => 'Could not write file: $message',
        CodeApplyGitRevert() => 'Git revert failed. Run `git checkout` manually.',
        CodeApplyContentChanged() => 'File was modified externally. Please retry.',
        CodeApplyUnknownError() => 'Revert failed. Please try again.',
      });
    });

    final c = AppColors.of(context);
    final change = widget.change;
    final project = widget.project;
    final filename = p.basename(change.filePath);
    final relativePath = project != null ? p.relative(change.filePath, from: project.path) : change.filePath;

    // Use persisted line counts computed from a char-level diff at
    // apply-time — see ApplyService._computeLineCounts. This is strictly
    // more accurate than a signed line-delta (which reports 0/0 when you
    // swap 10 lines for 10 different lines).
    final additions = change.additions;
    final deletions = change.deletions;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        children: [
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        filename,
                        style: TextStyle(
                          fontFamily: ThemeConstants.editorFontFamily,
                          color: c.textPrimary,
                          fontSize: ThemeConstants.uiFontSizeSmall,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    FutureBuilder<bool>(
                      future: _editedFuture,
                      builder: (context, snap) {
                        final isEdited = snap.data ?? false;
                        if (!isEdited) return const SizedBox.shrink();
                        final c2 = AppColors.of(context);
                        return Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: c2.editedBadgeBg,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: c2.editedBadgeBorder),
                          ),
                          child: Text('edited', style: TextStyle(color: c2.pendingAmber, fontSize: 9)),
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  relativePath,
                  style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // +N line count
          Text(
            '+$additions',
            style: TextStyle(
              color: c.success,
              fontSize: ThemeConstants.uiFontSizeLabel,
              fontFamily: ThemeConstants.editorFontFamily,
            ),
          ),
          const SizedBox(width: 3),
          // −N line count
          Text(
            '\u2212$deletions',
            style: TextStyle(
              color: c.error,
              fontSize: ThemeConstants.uiFontSizeLabel,
              fontFamily: ThemeConstants.editorFontFamily,
            ),
          ),
          const SizedBox(width: 6),
          // Revert button
          GestureDetector(
            onTap: _handleRevert,
            child: Icon(AppIcons.revert, size: 12, color: c.mutedFg),
          ),
        ],
      ),
    );
  }
}
