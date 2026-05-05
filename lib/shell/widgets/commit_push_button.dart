import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/utils/instant_menu.dart';
import '../../data/project/models/project.dart';
import '../../features/chat/notifiers/create_pr_actions.dart';
import '../../features/chat/widgets/commit_dialog.dart';
import '../../features/chat/widgets/create_pr_dialog.dart';
import '../../features/project_sidebar/notifiers/project_sidebar_actions.dart';
import '../notifiers/commit_message_actions.dart';
import '../notifiers/commit_message_failure.dart';
import '../notifiers/pr_preflight_result.dart';
import '../notifiers/commit_push_button_notifier.dart';
import '../notifiers/git_actions.dart';
import '../notifiers/git_actions_failure.dart';
import '../notifiers/git_remotes_notifier.dart';
import 'project_guard.dart';

/// Split button: left half commits, right half opens Push / Pull / PR dropdown.
///
/// All display state (can-flags, badge label, remote list) comes from
/// [commitPushButtonStateProvider]. The widget keeps only [_pushing] and
/// [_pulling] to label the busy state correctly ("Pushing…" vs "Pulling…").
class CommitPushButton extends ConsumerStatefulWidget {
  const CommitPushButton({super.key, required this.project});

  final Project project;

  @override
  ConsumerState<CommitPushButton> createState() => _CommitPushButtonState();
}

class _CommitPushButtonState extends ConsumerState<CommitPushButton> {
  bool _pushing = false;
  bool _pulling = false;

  Future<void> _doCommit() async {
    if (!ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
    final (:message, :autoCommit) = await ref.read(commitMessageActionsProvider.notifier).prepareCommit();
    if (autoCommit) {
      await _runCommit(message);
      return;
    }
    if (!mounted) return;
    final confirmed = await CommitDialog.show(context, message, projectPath: widget.project.path);
    if (confirmed != null) await _runCommit(confirmed);
  }

  Future<void> _runCommit(String message) async {
    final sha = await ref.read(gitActionsProvider.notifier).commit(widget.project.path, message);
    if (ref.read(gitActionsProvider).hasError) return;
    if (mounted) {
      AppSnackBar.show(context, 'Committed — $sha', type: AppSnackBarType.success);
      ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.project.path);
    }
  }

  Future<void> _doPush(CommitPushButtonState s) async {
    if (!ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
    setState(() => _pushing = true);
    try {
      final git = ref.read(gitActionsProvider.notifier);
      final String target;
      if (s.remotes.length <= 1) {
        final branch = await git.push(widget.project.path);
        target = 'origin/$branch';
      } else {
        await git.pushToRemote(widget.project.path, s.selectedRemote);
        final branch = await git.currentBranch(widget.project.path);
        target = (branch == null || branch.isEmpty) ? s.selectedRemote : '${s.selectedRemote}/$branch';
      }
      if (!ref.read(gitActionsProvider).hasError && mounted) {
        AppSnackBar.show(context, 'Pushed to $target', type: AppSnackBarType.success);
        ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.project.path);
      }
    } finally {
      if (mounted) setState(() => _pushing = false);
    }
  }

  Future<void> _doPushAll(CommitPushButtonState s) async {
    if (!ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
    if (s.remotes.isEmpty) return;
    setState(() => _pushing = true);
    final (:pushed, :failed) = await ref
        .read(gitActionsProvider.notifier)
        .pushAllRemotes(widget.project.path, s.remotes)
        .whenComplete(() {
          if (mounted) setState(() => _pushing = false);
        });
    if (!mounted) return;
    final parts = <String>[];
    if (pushed.isNotEmpty) parts.add('Pushed: ${pushed.join(", ")}');
    if (failed.isNotEmpty) parts.add('Failed: ${failed.join(", ")}');
    AppSnackBar.show(
      context,
      parts.join(' · '),
      type: failed.isEmpty ? AppSnackBarType.success : AppSnackBarType.error,
    );
    if (pushed.isNotEmpty) ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.project.path);
  }

  Future<void> _doPull() async {
    if (!ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
    setState(() => _pulling = true);
    try {
      final n = await ref.read(gitActionsProvider.notifier).pull(widget.project.path);
      if (!ref.read(gitActionsProvider).hasError && mounted) {
        AppSnackBar.show(context, 'Pulled — $n new commit(s) from origin', type: AppSnackBarType.success);
        ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.project.path);
      }
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  void _snack(
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    AppSnackBar.show(
      context,
      message,
      type: AppSnackBarType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  Future<void> _showCreatePrDialog() async {
    if (!ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;

    // Phase 1: fast checks — token, branch, remote, existing PR (~200 ms).
    final preflight = await ref.read(createPrActionsProvider.notifier).fastPreflight(widget.project.path);
    switch (preflight) {
      case PrPreflightFailed(:final message, :final actionUrl, :final actionLabel):
        _snack(
          message,
          duration: const Duration(seconds: 8),
          actionLabel: actionLabel,
          onAction: actionUrl == null
              ? null
              : () => unawaited(launchUrl(Uri.parse(actionUrl), mode: LaunchMode.externalApplication)),
        );
        return;
      case PrPreflightPassed(:final owner, :final repo, :final currentBranch):
        if (!mounted) return;
        // Phase 2: open dialog immediately; AI + branch list load in parallel.
        final contentFuture = ref
            .read(createPrActionsProvider.notifier)
            .loadContent(widget.project.path, owner, repo, currentBranch);
        final result = await CreatePrDialog.show(context, contentFuture: contentFuture);
        if (result == null) return;
        final prUrl = await ref
            .read(createPrActionsProvider.notifier)
            .createPullRequest(
              owner: owner,
              repo: repo,
              title: result.title,
              body: result.body,
              head: currentBranch,
              base: result.base,
              draft: result.draft,
            );
        if (prUrl == null) {
          _snack('Failed to create pull request — check your GitHub token and repo access.');
          return;
        }
        final canAutoOpen = prUrl.startsWith('https://github.com/');
        _snack(
          'Pull request created: $prUrl',
          duration: const Duration(seconds: 8),
          actionLabel: canAutoOpen ? 'Open' : null,
          onAction: canAutoOpen
              ? () => unawaited(launchUrl(Uri.parse(prUrl), mode: LaunchMode.externalApplication))
              : null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    ref.listen(gitActionsProvider, (prev, next) {
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      if (failure is! GitActionsFailure) return;
      final msg = switch (failure) {
        GitActionsNoUpstream(:final branch) =>
          'No upstream branch for $branch. Run `git push -u origin <branch>` in your terminal.',
        GitActionsAuthFailed() => 'Push failed — check your git credentials.',
        GitActionsConflict() => 'Pull failed — merge conflict detected. Resolve conflicts in your editor.',
        GitActionsGitError(:final message) => message,
        GitActionsUnknownError() => 'Git operation failed.',
      };
      AppSnackBar.show(context, msg, type: AppSnackBarType.error);
    });

    ref.listen(commitMessageActionsProvider, (prev, next) {
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      if (failure is! CommitMessageFailure) return;
      final msg = switch (failure) {
        CommitMessageUnavailable() => 'AI commit message unavailable — using default.',
        CommitMessageUnknown() => 'AI unavailable — using a default. Check your API key and model provider.',
      };
      AppSnackBar.show(context, msg, type: AppSnackBarType.warning);
    });

    final s = ref.watch(commitPushButtonStateProvider(widget.project.path));
    final busy = _pushing || _pulling;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left: Commit
        Tooltip(
          message: s.hasUnknownProbe
              ? 'Git status unavailable — run `git status` in a terminal to diagnose'
              : s.canCommit
              ? 'Commit staged & unstaged changes'
              : 'No changes to commit',
          child: GestureDetector(
            onTap: (busy || !s.canCommit) ? null : _doCommit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              constraints: const BoxConstraints.tightFor(height: ThemeConstants.actionButtonHeight),
              decoration: BoxDecoration(
                gradient: (busy || !s.canCommit)
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.accent, c.accentHover],
                      ),
                color: busy
                    ? c.accentHover
                    : s.canCommit
                    ? null
                    : c.inputSurface,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                boxShadow: (busy || !s.canCommit)
                    ? null
                    : [BoxShadow(color: c.sendGlow, blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Center(
                widthFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.gitCommit, size: 12, color: s.canCommit ? c.onAccent : c.mutedFg),
                    const SizedBox(width: 5),
                    Text(
                      _pushing
                          ? '● Pushing…'
                          : _pulling
                          ? '● Pulling…'
                          : 'Commit',
                      style: TextStyle(
                        color: s.canCommit ? c.onAccent : c.mutedFg,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right: dropdown
        Tooltip(
          message: 'Git actions',
          child: Builder(
            builder: (btnContext) => GestureDetector(
              onTap: s.canDropdown
                  ? () async {
                      final bc = AppColors.of(btnContext);
                      final action = await showInstantMenuAnchoredTo<String>(
                        buttonContext: btnContext,
                        color: bc.panelBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                          side: BorderSide(color: bc.faintFg),
                        ),
                        items: [
                          if (s.remotes.length > 1) ...[
                            for (final remote in s.remotes)
                              CheckedPopupMenuItem<String>(
                                value: 'select_${remote.name}',
                                checked: s.selectedRemote == remote.name,
                                height: 40,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      remote.name,
                                      style: TextStyle(
                                        color: bc.textSecondary,
                                        fontSize: ThemeConstants.uiFontSizeSmall,
                                      ),
                                    ),
                                    Text(
                                      remote.url,
                                      style: TextStyle(color: bc.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'push_all',
                              height: 32,
                              child: Text(
                                'Push to all remotes',
                                style: TextStyle(color: bc.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                              ),
                            ),
                            const PopupMenuDivider(),
                          ],
                          PopupMenuItem(
                            value: 'push',
                            height: 32,
                            enabled: s.canPush && !busy,
                            child: Row(
                              children: [
                                Icon(
                                  AppIcons.cloudUpload,
                                  size: 12,
                                  color: (s.canPush && !busy) ? bc.textSecondary : bc.faintFg,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _pushing ? '● Pushing…' : 'Push',
                                  style: TextStyle(
                                    color: (s.canPush && !busy) ? bc.textSecondary : bc.faintFg,
                                    fontSize: ThemeConstants.uiFontSizeSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'create_pr',
                            height: 32,
                            enabled: s.canPr && !busy,
                            child: Row(
                              children: [
                                Icon(
                                  AppIcons.gitPullRequest,
                                  size: 12,
                                  color: (s.canPr && !busy) ? bc.textSecondary : bc.faintFg,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Create PR',
                                  style: TextStyle(
                                    color: (s.canPr && !busy) ? bc.textSecondary : bc.faintFg,
                                    fontSize: ThemeConstants.uiFontSizeSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'pull',
                            height: 32,
                            enabled: s.canPull && !busy,
                            child: Text(
                              _pulling
                                  ? '● Pulling…'
                                  : s.canPull
                                  ? 'Pull${s.badgeLabel}'
                                  : 'Pull',
                              style: TextStyle(
                                color: s.canPull ? bc.accent : bc.faintFg,
                                fontSize: ThemeConstants.uiFontSizeSmall,
                              ),
                            ),
                          ),
                        ],
                      );
                      if (action == null) return;
                      switch (action) {
                        case 'push_all':
                          unawaited(_doPushAll(s));
                        case 'push':
                          unawaited(_doPush(s));
                        case 'create_pr':
                          unawaited(_showCreatePrDialog());
                        case 'pull':
                          unawaited(_doPull());
                        case final String sel when sel.startsWith('select_'):
                          ref
                              .read(gitRemotesProvider(widget.project.path).notifier)
                              .selectRemote(sel.substring('select_'.length));
                      }
                    }
                  : null,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  constraints: const BoxConstraints.tightFor(height: ThemeConstants.actionButtonHeight),
                  decoration: BoxDecoration(
                    color: s.canDropdown ? c.accentHover : c.inputSurface,
                    border: Border(left: BorderSide(color: s.canDropdown ? c.accentDark : c.deepBorder)),
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (s.badgeLabel.isNotEmpty)
                          Text(
                            s.badgeLabel,
                            style: TextStyle(
                              color: s.canDropdown ? c.onAccent : c.mutedFg,
                              fontSize: ThemeConstants.uiFontSizeLabel,
                            ),
                          ),
                        Icon(AppIcons.chevronDown, size: 11, color: s.canDropdown ? c.onAccent : c.mutedFg),
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
}
