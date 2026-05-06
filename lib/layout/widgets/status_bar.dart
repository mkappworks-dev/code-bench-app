import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/project/models/project.dart';
import '../../features/chat/notifiers/chat_notifier.dart';
import '../../features/branch_picker/widgets/branch_picker_popover.dart';
import '../../data/git/models/git_live_state.dart';
import '../notifiers/status_bar_notifier.dart';
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
    final c = AppColors.of(context);
    final s = ref.watch(statusBarStateProvider);
    final activeProject = s.activeProject;
    final changeCount = s.changeCount;
    final liveState = s.liveState;
    final panelVisible = ref.watch(changesPanelVisibleProvider);

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: c.statusBarFill),
      child: Row(
        children: [
          const Spacer(),
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
                    decoration: BoxDecoration(color: panelVisible ? c.accent : c.warning, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$changeCount ${changeCount == 1 ? 'change' : 'changes'}',
                    style: TextStyle(
                      color: panelVisible ? c.accent : c.warning,
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
                  hoverColor: c.success.withValues(alpha: 0.1),
                  onTap: () => _openPicker(activeProject, liveState),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.gitBranch, size: 10, color: c.success),
                        const SizedBox(width: 4),
                        Text(
                          liveState.branch ?? '(detached)',
                          style: TextStyle(color: c.success, fontSize: ThemeConstants.uiFontSizeLabel),
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
              style: TextStyle(color: c.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
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
