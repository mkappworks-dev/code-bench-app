import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/snackbar_helper.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/theme_constants.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/models/applied_change.dart';
import '../../../data/models/project.dart';
import '../../../features/project_sidebar/project_sidebar_notifier.dart';
import '../../../services/apply/apply_service.dart';
import '../../../services/git/git_live_state_provider.dart';
import '../chat_notifier.dart';
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

    // Resolve active project for path
    final projectId = ref.watch(activeProjectIdProvider);
    final project = ref.watch(projectsProvider).value?.firstWhereOrNull((proj) => proj.id == projectId);
    final isGit = project != null ? (ref.watch(gitLiveStateProvider(project.path)).value?.isGit ?? false) : false;

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
                        ...entry.value.map(
                          (change) => _ChangeEntry(
                            change: change,
                            project: project,
                            onRevert: () async {
                              if (project == null) throw StateError('No active project');
                              await ref
                                  .read(applyServiceProvider)
                                  .revertChange(change: change, isGit: isGit, projectPath: project.path);
                            },
                          ),
                        ),
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

class _ChangeEntry extends StatefulWidget {
  const _ChangeEntry({required this.change, required this.project, required this.onRevert});

  final AppliedChange change;
  final Project? project;
  final Future<void> Function() onRevert;

  @override
  State<_ChangeEntry> createState() => _ChangeEntryState();
}

class _ChangeEntryState extends State<_ChangeEntry> {
  // Cached once per widget lifecycle so the badge doesn't flicker between
  // rebuilds. The entry is short-lived — it goes away as soon as revert
  // succeeds — so a stale result is acceptable.
  late final Future<bool> _editedFuture;

  @override
  void initState() {
    super.initState();
    final checksum = widget.change.contentChecksum;
    _editedFuture = checksum == null
        ? Future.value(false)
        : ApplyService.isExternallyModified(widget.change.filePath, checksum);
  }

  Future<void> _handleRevert() async {
    final isEdited = await _editedFuture;
    if (!mounted) return;
    if (!isEdited) {
      // No conflict — delegate straight to the service-backed revert.
      try {
        await widget.onRevert();
      } catch (e, st) {
        dLog('[revert] error: $e\n$st');
        if (mounted) showErrorSnackBar(context, 'Revert failed. Please try again.');
      }
      return;
    }

    // File was modified out-of-band. Read the current content and show
    // the three-way merge view so the user can decide.
    String currentContent;
    try {
      currentContent = await File(widget.change.filePath).readAsString();
    } on FileSystemException catch (e) {
      dLog('[revert] could not read current content: $e');
      currentContent = '(file unreadable)';
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'File externally modified',
          style: TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize),
        ),
        content: ConflictMergeView(
          change: widget.change,
          currentContent: currentContent,
          onAcceptRevert: () async {
            Navigator.of(dialogCtx).pop();
            try {
              await widget.onRevert();
            } catch (e, st) {
              dLog('[revert] error after accept: $e\n$st');
              if (mounted) showErrorSnackBar(context, 'Revert failed. Please try again.');
            }
          },
          onKeepCurrent: () => Navigator.of(dialogCtx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                            color: const Color(0xFF3D2900),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0xFFAA7700)),
                          ),
                          child: const Text('edited', style: TextStyle(color: Color(0xFFFFAA00), fontSize: 9)),
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
