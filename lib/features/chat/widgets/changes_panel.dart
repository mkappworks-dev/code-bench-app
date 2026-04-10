import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/applied_change.dart';
import '../../../data/models/project.dart';
import '../../../features/project_sidebar/project_sidebar_notifier.dart';
import '../../../services/apply/apply_service.dart';
import '../chat_notifier.dart';

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

    // Resolve active project for isGit + path
    final projectId = ref.watch(activeProjectIdProvider);
    final project = ref.watch(projectsProvider).valueOrNull?.firstWhereOrNull((proj) => proj.id == projectId);

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
              border: Border(
                bottom: BorderSide(color: ThemeConstants.borderColor),
              ),
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
                      style: TextStyle(
                        color: ThemeConstants.mutedFg,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                      ),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: grouped.entries.expand((entry) {
                      return [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                          child: Text(
                            'Message',
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
                            onRevert: () => ref.read(applyServiceProvider).revertChange(
                                  change: change,
                                  isGit: project?.isGit ?? false,
                                  projectPath: project?.path ?? '',
                                ),
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
              border: Border(
                top: BorderSide(color: ThemeConstants.borderColor),
              ),
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
                    style: TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 11,
                    color: ThemeConstants.textSecondary,
                  ),
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

class _ChangeEntry extends StatelessWidget {
  const _ChangeEntry({
    required this.change,
    required this.project,
    required this.onRevert,
  });

  final AppliedChange change;
  final Project? project;
  final VoidCallback onRevert;

  /// Compute +N −N from original vs new content (line-count delta).
  (int additions, int deletions) get _lineCounts {
    final originalLines = (change.originalContent ?? '').split('\n').length;
    final newLines = change.newContent.split('\n').length;
    final delta = newLines - originalLines;
    return delta >= 0 ? (delta, 0) : (0, -delta);
  }

  @override
  Widget build(BuildContext context) {
    final filename = p.basename(change.filePath);
    final relativePath = project != null ? p.relative(change.filePath, from: project!.path) : change.filePath;

    final (additions, deletions) = _lineCounts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        children: [
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: const TextStyle(
                    fontFamily: ThemeConstants.editorFontFamily,
                    color: ThemeConstants.textPrimary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  relativePath,
                  style: const TextStyle(
                    color: ThemeConstants.mutedFg,
                    fontSize: ThemeConstants.uiFontSizeLabel,
                  ),
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
            onTap: onRevert,
            child: const Icon(
              LucideIcons.undo2,
              size: 12,
              color: ThemeConstants.mutedFg,
            ),
          ),
        ],
      ),
    );
  }
}
