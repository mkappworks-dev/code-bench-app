import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../features/project_sidebar/notifiers/project_sidebar_actions.dart';
import '../notifiers/branch_picker_failure.dart';
import '../notifiers/branch_picker_notifier.dart';
import '../notifiers/branch_picker_state.dart';

class BranchPickerPopover extends ConsumerStatefulWidget {
  const BranchPickerPopover({
    super.key,
    required this.layerLink,
    required this.projectPath,
    required this.currentBranch,
    required this.onClose,
  });

  final LayerLink layerLink;
  final String projectPath;
  final String? currentBranch;
  final VoidCallback onClose;

  @override
  ConsumerState<BranchPickerPopover> createState() => _BranchPickerPopoverState();
}

class _BranchPickerPopoverState extends ConsumerState<BranchPickerPopover> {
  final _filterController = TextEditingController();
  final _createController = TextEditingController();
  final _filterFocus = FocusNode();
  final _createFocus = FocusNode();
  final _worktreePathController = TextEditingController();

  bool _createMode = false;
  bool _worktreeMode = false;

  @override
  void initState() {
    super.initState();
    _filterController.addListener(() => setState(() {}));
    _createController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _filterController.dispose();
    _createController.dispose();
    _filterFocus.dispose();
    _createFocus.dispose();
    _worktreePathController.dispose();
    super.dispose();
  }

  Future<void> _checkout(String branch) async {
    await ref.read(branchPickerProvider(widget.projectPath).notifier).checkout(branch);
    if (!mounted) return;
    final state = ref.read(branchPickerProvider(widget.projectPath));
    if (state.hasError) {
      final failure = state.error;
      if (failure is! BranchPickerFailure) return;
      switch (failure) {
        case BranchPickerInvalidName(:final reason):
          AppSnackBar.show(context, reason, type: AppSnackBarType.error);
        case BranchPickerCheckoutConflict(:final message):
          AppSnackBar.show(context, message, type: AppSnackBarType.error, duration: const Duration(seconds: 4));
          // Reload so the branch list is restored from the error state.
          ref.read(branchPickerProvider(widget.projectPath).notifier).reload();
        case BranchPickerCreateFailed(:final message):
          AppSnackBar.show(context, 'Checkout failed: $message', type: AppSnackBarType.error);
        case BranchPickerCreateWorktreeFailed(:final message):
          AppSnackBar.show(context, 'Checkout failed: $message', type: AppSnackBarType.error);
        case BranchPickerGitUnavailable():
          AppSnackBar.show(context, 'Checkout failed — git binary unavailable.', type: AppSnackBarType.error);
        case BranchPickerUnknownError():
          AppSnackBar.show(context, 'Checkout failed — project folder unavailable.', type: AppSnackBarType.error);
      }
    } else {
      ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.projectPath);
      widget.onClose();
    }
  }

  Future<void> _switchToWorktree(String worktreePath) async {
    await ref.read(projectSidebarActionsProvider.notifier).switchWorktreePath(worktreePath);
    widget.onClose();
  }

  Future<void> _createBranch(String baseBranch) async {
    final name = _createController.text.trim();
    await ref.read(branchPickerProvider(widget.projectPath).notifier).createBranch(name, baseBranch: baseBranch);
    if (!mounted) return;
    final state = ref.read(branchPickerProvider(widget.projectPath));
    if (state.hasError) {
      final failure = state.error;
      if (failure is! BranchPickerFailure) return;
      switch (failure) {
        case BranchPickerInvalidName(:final reason):
          AppSnackBar.show(context, reason, type: AppSnackBarType.error);
        case BranchPickerCreateFailed(:final message):
          AppSnackBar.show(context, 'Failed: $message', type: AppSnackBarType.error);
        case BranchPickerCheckoutConflict(:final message):
          AppSnackBar.show(context, message, type: AppSnackBarType.error);
        case BranchPickerCreateWorktreeFailed(:final message):
          AppSnackBar.show(context, 'Failed: $message', type: AppSnackBarType.error);
        case BranchPickerGitUnavailable():
          AppSnackBar.show(context, 'Create branch failed — git binary unavailable.', type: AppSnackBarType.error);
        case BranchPickerUnknownError():
          AppSnackBar.show(context, 'Create branch failed — project folder unavailable.', type: AppSnackBarType.error);
      }
    } else {
      ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.projectPath);
      widget.onClose();
    }
  }

  Future<void> _createWorktree(String baseBranch) async {
    final branch = _createController.text.trim();
    final path = _worktreePathController.text.trim();
    if (branch.isEmpty || path.isEmpty) return;
    await ref
        .read(branchPickerProvider(widget.projectPath).notifier)
        .createWorktree(branch, path, baseBranch: baseBranch);
    if (!mounted) return;
    final s = ref.read(branchPickerProvider(widget.projectPath));
    if (s.hasError) {
      final failure = s.error;
      if (failure is! BranchPickerFailure) return;
      switch (failure) {
        case BranchPickerCreateWorktreeFailed(:final message):
          AppSnackBar.show(context, 'Worktree failed: $message', type: AppSnackBarType.error);
        case BranchPickerInvalidName(:final reason):
          AppSnackBar.show(context, reason, type: AppSnackBarType.error);
        case BranchPickerCheckoutConflict(:final message):
        case BranchPickerCreateFailed(:final message):
          AppSnackBar.show(context, 'Create worktree failed: $message', type: AppSnackBarType.error);
        case BranchPickerGitUnavailable():
          AppSnackBar.show(context, 'Create worktree failed — git binary unavailable.', type: AppSnackBarType.error);
        case BranchPickerUnknownError():
          AppSnackBar.show(
            context,
            'Create worktree failed — project folder unavailable.',
            type: AppSnackBarType.error,
          );
      }
    } else {
      ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.projectPath);
      widget.onClose();
    }
  }

  List<String> _filtered(List<String> branches) {
    final q = _filterController.text.toLowerCase();
    if (q.isEmpty) return branches;
    return branches.where((b) => b.toLowerCase().contains(q)).toList();
  }

  String _defaultWorktreePath() {
    final branch = _createController.text.trim();
    if (branch.isEmpty) return '';
    final parent = widget.projectPath.contains('/')
        ? widget.projectPath.substring(0, widget.projectPath.lastIndexOf('/'))
        : widget.projectPath;
    return '$parent/.worktrees/$branch';
  }

  Widget _buildList(AsyncValue<BranchPickerState> asyncState) {
    return switch (asyncState) {
      AsyncLoading() => Builder(
        builder: (context) {
          final c = AppColors.of(context);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: c.accent),
              ),
            ),
          );
        },
      ),
      AsyncError(:final error) => Builder(
        builder: (context) {
          final c = AppColors.of(context);
          return Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              _errorMessage(error),
              style: TextStyle(color: c.warning, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
          );
        },
      ),
      AsyncData(:final value) => Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_filterFocus.hasFocus && !_createFocus.hasFocus) {
              _filterFocus.requestFocus();
            }
          });
          final filtered = _filtered(value.branches).where((b) => !value.staleBranches.contains(b)).toList();
          final branches = filtered.where((b) => !value.worktreePaths.containsKey(b)).toList();
          final worktrees = filtered.where((b) => value.worktreePaths.containsKey(b)).toList();
          return SizedBox(
            height: 240,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                if (branches.isNotEmpty) ...[
                  const _SectionHeader(label: 'BRANCHES'),
                  for (final b in branches)
                    _BranchRow(
                      branch: b,
                      isCurrent: b == widget.currentBranch,
                      isWorktree: false,
                      onTap: b == widget.currentBranch ? null : () => _checkout(b),
                    ),
                ],
                if (worktrees.isNotEmpty) ...[
                  const _SectionHeader(label: 'WORKTREES'),
                  for (final b in worktrees)
                    _BranchRow(
                      branch: b,
                      isCurrent: b == widget.currentBranch,
                      isWorktree: true,
                      onTap: b == widget.currentBranch ? null : () => _switchToWorktree(value.worktreePaths[b]!),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(branchPickerProvider(widget.projectPath));
    final stale = asyncState.value?.staleBranches ?? const {};
    // All local branches minus any locked to a prunable (stale) worktree.
    final allBranches = (asyncState.value?.branches ?? const []).where((b) => !stale.contains(b)).toList();
    // Worktree source list: root project (currentBranch) + active worktrees only.
    // Stale worktrees are already absent from worktreePaths by the datasource.
    final worktreeSources = [
      if (widget.currentBranch != null) widget.currentBranch!,
      ...?asyncState.value?.worktreePaths.keys,
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(color: AppColors.of(context).scrimColor),
          ),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    width: 440,
                    constraints: const BoxConstraints(maxHeight: 560),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).dialogFill,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: AppColors.of(context).subtleBorder),
                      boxShadow: [
                        BoxShadow(color: AppColors.of(context).shadowDeep, blurRadius: 64, offset: const Offset(0, 24)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DialogHeader(
                          currentBranch: widget.currentBranch,
                          onClose: widget.onClose,
                          createMode: _createMode,
                          worktreeMode: _worktreeMode,
                          onBack: _createMode
                              ? () => setState(() {
                                  _createMode = false;
                                  _worktreeMode = false;
                                  _createController.clear();
                                  _worktreePathController.clear();
                                })
                              : null,
                        ),
                        if (!_createMode) _SearchBar(controller: _filterController, focusNode: _filterFocus),
                        if (!_createMode) ...[
                          Flexible(child: _buildList(asyncState)),
                          _DialogFooter(
                            onNewBranch: () => setState(() {
                              _createMode = true;
                              _worktreeMode = false;
                            }),
                            onNewWorktree: () => setState(() {
                              _createMode = true;
                              _worktreeMode = true;
                            }),
                          ),
                        ] else if (_worktreeMode) ...[
                          _WorktreeCreateForm(
                            branchController: _createController,
                            pathController: _worktreePathController,
                            defaultPath: _defaultWorktreePath(),
                            branches: worktreeSources,
                            currentBranch: widget.currentBranch,
                            onSubmit: _createWorktree,
                          ),
                        ] else ...[
                          _BranchCreateForm(
                            controller: _createController,
                            focusNode: _createFocus,
                            branches: allBranches,
                            currentBranch: widget.currentBranch,
                            onSubmit: _createBranch,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _errorMessage(Object? error) {
    if (error is BranchPickerFailure) {
      return switch (error) {
        BranchPickerGitUnavailable() => 'Could not read branches — is git installed and the folder available?',
        BranchPickerInvalidName(:final reason) => reason,
        BranchPickerCheckoutConflict(:final message) => message,
        BranchPickerCreateFailed(:final message) => message,
        BranchPickerCreateWorktreeFailed(:final message) => message,
        BranchPickerUnknownError() => 'Could not read branches — is git installed and the folder available?',
      };
    }
    return 'Could not read branches — is git installed and the folder available?';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.currentBranch,
    required this.onClose,
    required this.createMode,
    required this.worktreeMode,
    required this.onBack,
  });

  final String? currentBranch;
  final VoidCallback onClose;
  final bool createMode;
  final bool worktreeMode;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final title = createMode ? (worktreeMode ? 'New Worktree' : 'New Branch') : 'Switch Branch';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.faintBorder)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Icon(LucideIcons.arrowLeft, size: 14, color: c.textSecondary),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (!createMode && currentBranch != null)
                  Text(
                    currentBranch!,
                    style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Icon(LucideIcons.x, size: 14, color: c.mutedFg),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: AppSearchField(controller: controller, focusNode: focusNode, hintText: 'Search branches…'),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(label, style: TextStyle(color: c.mutedFg, fontSize: 8, letterSpacing: 0.5)),
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({required this.branch, required this.isCurrent, required this.isWorktree, required this.onTap});

  final String branch;
  final bool isCurrent;
  final bool isWorktree;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final canTap = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        color: isCurrent ? c.success.withValues(alpha: 0.07) : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent ? c.success : Colors.transparent,
                border: isCurrent ? null : Border.all(color: c.faintFg),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                branch,
                style: TextStyle(
                  color: isCurrent
                      ? c.success
                      : canTap
                      ? c.textSecondary
                      : c.faintFg,
                  fontSize: ThemeConstants.uiFontSizeLabel,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrent) Icon(LucideIcons.check, size: 10, color: c.success),
            if (isWorktree)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: c.worktreeBadgeBg, borderRadius: BorderRadius.circular(3)),
                child: Text('worktree', style: TextStyle(color: c.worktreeBadgeFg, fontSize: 9)),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter({required this.onNewBranch, required this.onNewWorktree});
  final VoidCallback onNewBranch;
  final VoidCallback onNewWorktree;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.faintBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FooterButton(
              icon: LucideIcons.gitBranch,
              label: 'New Branch',
              iconColor: c.accent,
              borderColor: c.accentBorderTeal,
              onTap: onNewBranch,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FooterButton(
              icon: LucideIcons.layers,
              label: 'New Worktree',
              iconColor: c.worktreeBadgeFg,
              borderColor: c.accentBorderAmber,
              onTap: onNewWorktree,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.of(context).chipFill,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchCreateForm extends StatefulWidget {
  const _BranchCreateForm({
    required this.controller,
    required this.focusNode,
    required this.branches,
    required this.currentBranch,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> branches;
  final String? currentBranch;

  /// Called with the selected base branch name when the user taps Create.
  final void Function(String baseBranch) onSubmit;

  @override
  State<_BranchCreateForm> createState() => _BranchCreateFormState();
}

class _BranchCreateFormState extends State<_BranchCreateForm> {
  late String _base;

  @override
  void initState() {
    super.initState();
    _base = widget.currentBranch ?? (widget.branches.isNotEmpty ? widget.branches.first : '');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Branch name', style: TextStyle(color: c.textSecondary, fontSize: 10)),
          const SizedBox(height: 4),
          AppTextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autofocus: true,
            onSubmitted: (_) => widget.onSubmit(_base),
            hintText: 'branch-name',
          ),
          const SizedBox(height: 10),
          Text('From', style: TextStyle(color: c.textSecondary, fontSize: 10)),
          const SizedBox(height: 4),
          if (widget.branches.isNotEmpty)
            _SourceDropdown(
              value: widget.branches.contains(_base) ? _base : widget.branches.first,
              items: widget.branches,
              onChanged: (v) => setState(() => _base = v),
            ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => widget.onSubmit(_base),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.accent, c.accentHover]),
                borderRadius: BorderRadius.circular(7),
                boxShadow: [BoxShadow(color: c.sendGlow, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Center(
                child: Text(
                  'Create Branch',
                  style: TextStyle(color: c.onAccent, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorktreeCreateForm extends StatefulWidget {
  const _WorktreeCreateForm({
    required this.branchController,
    required this.pathController,
    required this.defaultPath,
    required this.branches,
    required this.currentBranch,
    required this.onSubmit,
  });
  final TextEditingController branchController;
  final TextEditingController pathController;
  final String defaultPath;
  final List<String> branches;
  final String? currentBranch;

  /// Called with the selected base branch name when the user taps Create.
  final void Function(String baseBranch) onSubmit;

  @override
  State<_WorktreeCreateForm> createState() => _WorktreeCreateFormState();
}

class _WorktreeCreateFormState extends State<_WorktreeCreateForm> {
  late String _base;

  @override
  void initState() {
    super.initState();
    _base = widget.currentBranch ?? (widget.branches.isNotEmpty ? widget.branches.first : '');
    if (widget.pathController.text.isEmpty && widget.defaultPath.isNotEmpty) {
      widget.pathController.text = widget.defaultPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Branch name', style: TextStyle(color: c.textSecondary, fontSize: 10)),
          const SizedBox(height: 4),
          AppTextField(controller: widget.branchController, autofocus: true, hintText: 'feat/my-feature'),
          const SizedBox(height: 8),
          Text('Path', style: TextStyle(color: c.textSecondary, fontSize: 10)),
          const SizedBox(height: 4),
          AppTextField(controller: widget.pathController, hintText: '.worktrees/feat-my-feature'),
          const SizedBox(height: 8),
          Text('From worktree', style: TextStyle(color: c.textSecondary, fontSize: 10)),
          const SizedBox(height: 4),
          if (widget.branches.isNotEmpty)
            _SourceDropdown(
              value: widget.branches.contains(_base) ? _base : widget.branches.first,
              items: widget.branches,
              onChanged: (v) => setState(() => _base = v),
            ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => widget.onSubmit(_base),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: c.warningTintBg,
                border: Border.all(color: c.accentBorderAmber),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
                  'Create Worktree',
                  style: TextStyle(color: c.worktreeBadgeFg, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay dropdown using [CompositedTransformFollower] + [LayerLink].
///
/// The panel floats above the dialog in the [Overlay] layer, anchored
/// directly below the trigger with matching width — no Navigator route
/// machinery and no layout expansion of the parent dialog.
class _SourceDropdown extends StatefulWidget {
  const _SourceDropdown({required this.value, required this.items, required this.onChanged});

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  State<_SourceDropdown> createState() => _SourceDropdownState();
}

class _SourceDropdownState extends State<_SourceDropdown> {
  final _link = LayerLink();
  OverlayEntry? _overlay;

  bool get _isOpen => _overlay != null;

  void _openOverlay(BuildContext context) {
    final renderBox = context.findRenderObject()! as RenderBox;
    final size = renderBox.size;
    _overlay = OverlayEntry(
      builder: (_) => _DropdownPanel(
        link: _link,
        triggerHeight: size.height,
        width: size.width,
        value: widget.value,
        items: widget.items,
        onChanged: (v) {
          widget.onChanged(v);
          _closeOverlay();
        },
        onDismiss: _closeOverlay,
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _closeOverlay() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effective = widget.items.contains(widget.value)
        ? widget.value
        : (widget.items.isNotEmpty ? widget.items.first : '');

    final c = AppColors.of(context);
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: () => _isOpen ? _closeOverlay() : _openOverlay(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: c.fieldFill,
            border: Border.all(color: _isOpen ? c.accent : c.fieldStroke, width: _isOpen ? 1.5 : 1.0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  effective,
                  style: TextStyle(color: c.textPrimary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(_isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 12, color: c.mutedFg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating panel inserted into the [Overlay] by [_SourceDropdown].
class _DropdownPanel extends StatelessWidget {
  const _DropdownPanel({
    required this.link,
    required this.triggerHeight,
    required this.width,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.onDismiss,
  });

  final LayerLink link;
  final double triggerHeight;
  final double width;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    // Material resets DefaultTextStyle so Overlay-inherited underline decoration
    // doesn't bleed onto the panel's text items.
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Full-screen dismiss layer — opaque so the dialog's own dismiss
          // gesture doesn't fire; one tap closes the dropdown first.
          Positioned.fill(
            child: GestureDetector(onTap: onDismiss, behavior: HitTestBehavior.opaque),
          ),
          // Panel anchored just below the trigger.
          CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            offset: Offset(0, triggerHeight + 2),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: Builder(
                    builder: (context) {
                      final c = AppColors.of(context);
                      return Container(
                        decoration: BoxDecoration(
                          color: c.panelBackground,
                          border: Border.all(color: c.subtleBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: items.map((item) {
                              final selected = item == value;
                              return GestureDetector(
                                onTap: () => onChanged(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: selected ? BoxDecoration(color: c.accent.withValues(alpha: 0.08)) : null,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: TextStyle(color: selected ? c.accent : c.textSecondary, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (selected) Icon(LucideIcons.check, size: 10, color: c.accent),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
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
