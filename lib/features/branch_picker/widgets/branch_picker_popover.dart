import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../features/project_sidebar/project_sidebar_actions.dart';
import '../../../services/git/git_service.dart';
import '../branch_picker_notifier.dart';

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

  List<String> _branches = [];
  Set<String> _worktreeBranches = {};
  bool _loading = true;
  String? _loadError;
  bool _createMode = false;

  @override
  void initState() {
    super.initState();
    _filterController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _filterController.dispose();
    _createController.dispose();
    _filterFocus.dispose();
    _createFocus.dispose();
    super.dispose();
  }

  /// Loads local and worktree branch lists. Wrapped in try/catch so a
  /// synchronous `Process.run` throw (git binary missing, cwd deleted)
  /// cannot escape `initState`'s async zone and leave `_loading == true`
  /// forever — the popover would otherwise be stuck at an infinite spinner
  /// with no way to recover short of closing and reopening.
  Future<void> _load() async {
    final notifier = ref.read(branchPickerProvider(widget.projectPath));
    try {
      final branches = await notifier.listLocalBranches();
      final wtBranches = await notifier.worktreeBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
          _worktreeBranches = wtBranches;
          _loading = false;
          _loadError = null;
        });
        _filterFocus.requestFocus();
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _branches = const [];
          _worktreeBranches = const {};
          _loading = false;
          _loadError = 'Could not read branches — is git installed and the folder available?';
        });
      }
    }
  }

  Future<void> _checkout(String branch) async {
    try {
      await ref.read(branchPickerProvider(widget.projectPath)).checkout(branch);
      if (mounted) {
        ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.projectPath);
        widget.onClose();
      }
    } on ArgumentError catch (e) {
      // Leading-dash / empty branch guard from BranchPickerNotifier —
      // surface as a snackbar rather than letting it crash the zone.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message.toString())));
      }
    } on GitException catch (e) {
      if (mounted) {
        final msg = e.message.contains('would be overwritten')
            ? 'Checkout failed — stash or commit your changes first.'
            : 'Checkout failed: ${e.message}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));
        // Reload the branch list so "current branch" highlighting reflects
        // reality (another worktree may have moved the ref between _load
        // and tap, and the stale list would mislead the next click).
        unawaited(_load());
      }
    } on ProcessException {
      // Thrown when `git` isn't on PATH or the cwd was deleted out from
      // under us. The notifier logs the underlying ProcessException; we
      // keep the typed catch here purely to route to the right snackbar.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Checkout failed — git binary unavailable.')));
      }
    } on FileSystemException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Checkout failed — project folder unavailable.')));
      }
    }
  }

  Future<void> _createBranch() async {
    final name = _createController.text.trim();
    try {
      await ref.read(branchPickerProvider(widget.projectPath)).createBranch(name);
      if (mounted) {
        ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.projectPath);
        widget.onClose();
      }
    } on ArgumentError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message.toString())));
      }
    } on GitException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
      }
    } on ProcessException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Create branch failed — git binary unavailable.')));
      }
    } on FileSystemException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Create branch failed — project folder unavailable.')));
      }
    }
  }

  List<String> get _filtered {
    final q = _filterController.text.toLowerCase();
    if (q.isEmpty) return _branches;
    return _branches.where((b) => b.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          offset: const Offset(0, -4),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {}, // stop propagation
              child: Container(
                width: 250,
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: ThemeConstants.panelBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ThemeConstants.deepBorder),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, -4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SearchBar(controller: _filterController, focusNode: _filterFocus),
                    Flexible(
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 1.5),
                                ),
                              ),
                            )
                          : _loadError != null
                          ? Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                _loadError!,
                                style: const TextStyle(
                                  color: ThemeConstants.warning,
                                  fontSize: ThemeConstants.uiFontSizeLabel,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) {
                                final branch = _filtered[i];
                                final isCurrent = branch == widget.currentBranch;
                                final isWorktree = _worktreeBranches.contains(branch);
                                return _BranchRow(
                                  branch: branch,
                                  isCurrent: isCurrent,
                                  isWorktree: isWorktree,
                                  onTap: (isCurrent || isWorktree) ? null : () => _checkout(branch),
                                );
                              },
                            ),
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
    return Tooltip(
      message: isWorktree ? 'Checked out in another worktree' : '',
      child: InkWell(
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
                  decoration: BoxDecoration(color: const Color(0xFF2A1F0A), borderRadius: BorderRadius.circular(3)),
                  child: const Text('worktree', style: TextStyle(color: Color(0xFFE8A228), fontSize: 9)),
                ),
            ],
          ),
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
