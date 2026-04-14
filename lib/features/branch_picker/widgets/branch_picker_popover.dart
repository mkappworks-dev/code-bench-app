import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../features/project_sidebar/notifiers/project_sidebar_actions.dart';
import '../notifiers/branch_picker_failure.dart';
import '../notifiers/branch_picker_notifier.dart';

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

  bool _createMode = false;

  @override
  void initState() {
    super.initState();
    _filterController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _filterController.dispose();
    _createController.dispose();
    _filterFocus.dispose();
    _createFocus.dispose();
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

  Future<void> _createBranch() async {
    final name = _createController.text.trim();
    await ref.read(branchPickerProvider(widget.projectPath).notifier).createBranch(name);
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

  List<String> _filtered(List<String> branches) {
    final q = _filterController.text.toLowerCase();
    if (q.isEmpty) return branches;
    return branches.where((b) => b.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(branchPickerProvider(widget.projectPath));

    return Stack(
      children: [
        // Dismiss on outside tap
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // Popover
        CompositedTransformFollower(
          link: widget.layerLink,
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.bottomRight,
          offset: const Offset(0, -8),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {}, // stop propagation
              child: Container(
                width: 280,
                constraints: const BoxConstraints(maxHeight: 380),
                decoration: BoxDecoration(
                  color: ThemeConstants.panelBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ThemeConstants.deepBorder),
                  boxShadow: const [
                    BoxShadow(color: ThemeConstants.shadowMedium, blurRadius: 20, offset: Offset(0, -4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SearchBar(controller: _filterController, focusNode: _filterFocus),
                    Flexible(
                      child: switch (asyncState) {
                        AsyncLoading() => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)),
                          ),
                        ),
                        AsyncError(:final error) => Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            _errorMessage(error),
                            style: const TextStyle(
                              color: ThemeConstants.warning,
                              fontSize: ThemeConstants.uiFontSizeLabel,
                            ),
                          ),
                        ),
                        AsyncData(:final value) => Builder(
                          builder: (context) {
                            // Request focus after the first successful data load.
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && !_filterFocus.hasFocus && !_createFocus.hasFocus) {
                                _filterFocus.requestFocus();
                              }
                            });
                            final filtered = _filtered(value.branches);
                            return ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final branch = filtered[i];
                                final isCurrent = branch == widget.currentBranch;
                                final worktreePath = value.worktreePaths[branch];
                                final isWorktree = worktreePath != null;
                                final VoidCallback? onTap;
                                if (isCurrent) {
                                  onTap = null;
                                } else if (isWorktree) {
                                  onTap = () => _switchToWorktree(worktreePath);
                                } else {
                                  onTap = () => _checkout(branch);
                                }
                                return _BranchRow(
                                  branch: branch,
                                  isCurrent: isCurrent,
                                  isWorktree: isWorktree,
                                  onTap: onTap,
                                );
                              },
                            );
                          },
                        ),
                      },
                    ),
                    _Footer(
                      createMode: _createMode,
                      controller: _createController,
                      focusNode: _createFocus,
                      currentBranch: widget.currentBranch,
                      onEnterCreateMode: () {
                        setState(() => _createMode = true);
                        WidgetsBinding.instance.addPostFrameCallback((_) => _createFocus.requestFocus());
                      },
                      onCreateSubmit: _createBranch,
                      onCreateCancel: () {
                        setState(() {
                          _createMode = false;
                          _createController.clear();
                        });
                        _filterFocus.requestFocus();
                      },
                    ),
                  ],
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
        BranchPickerUnknownError() => 'Could not read branches — is git installed and the folder available?',
      };
    }
    return 'Could not read branches — is git installed and the folder available?';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSizeLabel),
        decoration: InputDecoration(
          hintText: 'Filter branches…',
          hintStyle: const TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 6, right: 4),
            child: Icon(LucideIcons.search, size: 11, color: ThemeConstants.faintFg),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          filled: true,
          fillColor: ThemeConstants.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: ThemeConstants.deepBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: ThemeConstants.deepBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: ThemeConstants.accent),
          ),
        ),
      ),
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
    final canTap = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        color: isCurrent ? ThemeConstants.success.withValues(alpha: 0.07) : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent ? ThemeConstants.success : Colors.transparent,
                border: isCurrent ? null : Border.all(color: ThemeConstants.faintFg),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                branch,
                style: TextStyle(
                  color: isCurrent
                      ? ThemeConstants.success
                      : canTap
                      ? ThemeConstants.textSecondary
                      : ThemeConstants.faintFg,
                  fontSize: ThemeConstants.uiFontSizeLabel,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrent) const Icon(LucideIcons.check, size: 10, color: ThemeConstants.success),
            if (isWorktree)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: ThemeConstants.worktreeBadgeBg,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text('worktree', style: TextStyle(color: ThemeConstants.worktreeBadgeFg, fontSize: 9)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.createMode,
    required this.controller,
    required this.focusNode,
    required this.currentBranch,
    required this.onEnterCreateMode,
    required this.onCreateSubmit,
    required this.onCreateCancel,
  });

  final bool createMode;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? currentBranch;
  final VoidCallback onEnterCreateMode;
  final VoidCallback onCreateSubmit;
  final VoidCallback onCreateCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ThemeConstants.borderColor)),
      ),
      child: createMode ? _createInput() : _createButton(),
    );
  }

  Widget _createButton() {
    return InkWell(
      onTap: onEnterCreateMode,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: const [
            Icon(LucideIcons.plus, size: 11, color: ThemeConstants.faintFg),
            SizedBox(width: 6),
            Text(
              'Create new branch…',
              style: TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _createInput() {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            onCreateCancel();
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.gitBranch, size: 11, color: ThemeConstants.success),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onSubmitted: (_) => onCreateSubmit(),
                    style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSizeLabel),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.only(bottom: 2),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: ThemeConstants.success)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ThemeConstants.success)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: ThemeConstants.success)),
                      hintText: 'branch-name',
                      hintStyle: TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('↵ create · esc cancel', style: TextStyle(color: ThemeConstants.faintFg, fontSize: 9)),
              ],
            ),
            if (currentBranch != null) ...[
              const SizedBox(height: 3),
              Text('from $currentBranch', style: const TextStyle(color: ThemeConstants.faintFg, fontSize: 9)),
            ],
          ],
        ),
      ),
    );
  }
}
