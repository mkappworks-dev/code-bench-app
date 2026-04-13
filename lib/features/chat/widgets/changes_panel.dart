import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/snackbar_helper.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/applied_change.dart';
import '../../../data/models/project.dart';
import '../../../features/project_sidebar/notifiers/project_sidebar_notifier.dart';
import '../../../services/apply/apply_service.dart';
import '../../../data/git/repository/git_repository_impl.dart';
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

    return Container(
      decoration: const BoxDecoration(
        color: ThemeConstants.sidebarBackground,
        border: Border(left: BorderSide(color: ThemeConstants.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
            ),
            child: const Text(
              'Changes',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: ThemeConstants.uiFontSizeSmall,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Change entries
          Expanded(
            child: changes.isEmpty
                ? const Center(
                    child: Text(
                      'No changes yet',
                      style: TextStyle(color: ThemeConstants.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
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
                            style: const TextStyle(
                              color: ThemeConstants.faintFg,
                              fontSize: ThemeConstants.uiFontSizeLabel,
                            ),
                          ),
                        ),
                        ...entry.value.map((change) => _ChangeEntry(change: change, project: project)),
                      ];
                    }).toList(),
                  ),
          ),
          // Footer — stub "Commit all" button (Phase 3 wires this to git flow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: ThemeConstants.borderColor)),
            ),
            child: GestureDetector(
              onTap: () {
                // Phase 3: wire to git commit flow
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Commit all',
                    style: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                  ),
                  SizedBox(width: 4),
                  Icon(AppIcons.arrowRight, size: 11, color: ThemeConstants.textSecondary),
                ],
              ),
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
        : ApplyService.isExternallyModified(widget.change.filePath, checksum);
  }

  Future<void> _handleRevert() async {
    final project = widget.project;
    if (project == null) return;

    final isEdited = await _editedFuture;
    if (!mounted) return;

    if (!isEdited) {
      // No conflict — revert directly.
      final isGit = ref.read(gitRepositoryProvider).isGitRepo(project.path);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read current file contents — try again after resolving file access.')),
      );
      return;
    }

    final isGit = ref.read(gitRepositoryProvider).isGitRepo(project.path);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: ThemeConstants.inputSurface,
        title: const Text(
          'File externally modified',
          style: TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize),
        ),
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
        CodeApplyDiskWrite(:final message) => 'Could not write file: $message',
        CodeApplyFileRead(:final path) => 'Could not read file: $path',
        CodeApplyUnknownError() => 'Revert failed. Please try again.',
      });
    });

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
                        style: const TextStyle(
                          fontFamily: ThemeConstants.editorFontFamily,
                          color: ThemeConstants.textPrimary,
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
                        return Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: ThemeConstants.editedBadgeBg,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: ThemeConstants.editedBadgeBorder),
                          ),
                          child: const Text(
                            'edited',
                            style: TextStyle(color: ThemeConstants.pendingAmber, fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  relativePath,
                  style: const TextStyle(color: ThemeConstants.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // +N line count
          Text(
            '+$additions',
            style: const TextStyle(
              color: ThemeConstants.success,
              fontSize: ThemeConstants.uiFontSizeLabel,
              fontFamily: ThemeConstants.editorFontFamily,
            ),
          ),
          const SizedBox(width: 3),
          // −N line count
          Text(
            '\u2212$deletions',
            style: const TextStyle(
              color: ThemeConstants.error,
              fontSize: ThemeConstants.uiFontSizeLabel,
              fontFamily: ThemeConstants.editorFontFamily,
            ),
          ),
          const SizedBox(width: 6),
          // Revert button
          GestureDetector(
            onTap: _handleRevert,
            child: const Icon(AppIcons.revert, size: 12, color: ThemeConstants.mutedFg),
          ),
        ],
      ),
    );
  }
}
