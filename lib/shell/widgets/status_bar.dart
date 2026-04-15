import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/project/models/project.dart';
import '../../features/chat/notifiers/chat_notifier.dart';
import '../../features/branch_picker/widgets/branch_picker_popover.dart';
import '../../data/git/models/git_live_state.dart';
import '../notifiers/status_bar_notifier.dart';
import 'working_pill.dart';

export '../notifiers/status_bar_notifier.dart' show activeWorktreePathProvider;

class StatusBar extends ConsumerStatefulWidget {
  const StatusBar({super.key});

  @override
  ConsumerState<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends ConsumerState<StatusBar> {
  final _branchLabelLink = LayerLink();
  OverlayEntry? _pickerEntry;

  void closePicker() {
    _pickerEntry?.remove();
    _pickerEntry = null;
  }

  @override
  void dispose() {
    _pickerEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(statusBarStateProvider);
    final activeProject = s.activeProject;
    final changeCount = s.changeCount;
    final liveState = s.liveState;
    final panelVisible = ref.watch(changesPanelVisibleProvider);

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? ThemeConstants.background
            : ThemeConstants.lightStatusBar,
      ),
      child: Row(
        children: [
          const Spacer(),
          // Working pill — shown while the agent is running tool calls.
          Consumer(
            builder: (context, ref, child) {
              final sessionId = ref.watch(activeSessionIdProvider);
              if (sessionId == null) return const SizedBox.shrink();
              final messageId = ref.watch(activeMessageIdProvider);
              if (messageId == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: WorkingPill(sessionId: sessionId, messageId: messageId),
              );
            },
          ),
          // Centre-right: N changes indicator (hidden when 0)
          if (changeCount > 0) ...[
            GestureDetector(
              onTap: () => ref.read(changesPanelVisibleProvider.notifier).toggle(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: panelVisible ? ThemeConstants.accent : ThemeConstants.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$changeCount ${changeCount == 1 ? 'change' : 'changes'}',
                    style: TextStyle(
                      color: panelVisible ? ThemeConstants.accent : ThemeConstants.warning,
                      fontSize: ThemeConstants.uiFontSizeLabel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Right: Git branch (live)
          if (activeProject != null && liveState != null && liveState.isGit) ...[
            CompositedTransformTarget(
              link: _branchLabelLink,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  hoverColor: ThemeConstants.success.withValues(alpha: 0.1),
                  onTap: () => _openPicker(activeProject, liveState),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.gitBranch, size: 10, color: ThemeConstants.success),
                        const SizedBox(width: 4),
                        Text(
                          liveState.branch ?? '(detached)',
                          style: const TextStyle(
                            color: ThemeConstants.success,
                            fontSize: ThemeConstants.uiFontSizeLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else if (activeProject != null && liveState != null) ...[
            Text(
              'Not git',
              style: const TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
          ],
        ],
      ),
    );
  }

  void _openPicker(Project project, GitLiveState liveState) {
    if (_pickerEntry != null) {
      closePicker();
      return;
    }
    // Use the per-session worktree override if one is set.
    final sessionId = ref.read(activeSessionIdProvider);
    final overrides = ref.read(activeWorktreePathProvider);
    final effectivePath = (sessionId != null ? overrides[sessionId] : null) ?? project.path;
    _pickerEntry = OverlayEntry(
      builder: (ctx) => BranchPickerPopover(
        layerLink: _branchLabelLink,
        projectPath: effectivePath,
        currentBranch: liveState.branch,
        onClose: closePicker,
      ),
    );
    Overlay.of(context).insert(_pickerEntry!);
    setState(() {}); // rebuild so the branch label stays visible under the overlay
  }
}
