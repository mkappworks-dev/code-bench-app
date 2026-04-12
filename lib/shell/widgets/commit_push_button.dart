import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/instant_menu.dart';
import '../../data/models/project.dart';
import '../../data/datasources/local/general_preferences.dart';
import '../../features/chat/notifiers/chat_notifier.dart';
import '../../features/chat/notifiers/create_pr_actions.dart';
import '../../features/chat/widgets/commit_dialog.dart';
import '../../features/chat/widgets/create_pr_dialog.dart';
import '../../features/project_sidebar/notifiers/project_sidebar_actions.dart';
import '../../services/git/git_live_state_provider.dart';
import '../../services/git/git_service.dart' show GitRemote;
import '../notifiers/commit_message_actions.dart';
import '../notifiers/commit_message_failure.dart';
import '../notifiers/git_actions.dart';
import '../notifiers/git_actions_failure.dart';
import 'project_guard.dart';

/// Split button that handles Commit, Push, Pull, and Create PR for the
/// active project. Remote list is loaded once on [initState] and drives
/// the multi-remote picker in the dropdown.
class CommitPushButton extends ConsumerStatefulWidget {
  const CommitPushButton({super.key, required this.project});

  final Project project;

  @override
  ConsumerState<CommitPushButton> createState() => _CommitPushButtonState();
}

class _CommitPushButtonState extends ConsumerState<CommitPushButton> {
  bool _pushing = false;
  bool _pulling = false;

  // Configured remotes for this repo. Empty list = single-origin (or
  // non-git) project; the dropdown collapses to the classic Push/Pull
  // items without a remote picker. `_selectedRemote` is the one the
  // next `Push` click targets — defaults to `origin` so first render
  // matches the pre-multi-remote behaviour.
  List<GitRemote> _remotes = const [];
  String _selectedRemote = 'origin';

  @override
  void initState() {
    super.initState();
    unawaited(_loadRemotes());
  }

  Future<void> _loadRemotes() async {
    // `listRemotes` already swallows a non-zero exit code into `[]`, so
    // the only thing that can throw here is a missing git binary or a
    // deleted working directory. Mirror that soft-failure behaviour: leave
    // `_remotes` as the empty list so the UI falls back to classic
    // single-remote Push.
    final remotes = await ref.read(gitActionsProvider.notifier).listRemotes(widget.project.path);
    if (ref.read(gitActionsProvider).hasError) return;
    if (!mounted) return;
    setState(() {
      _remotes = remotes;
      if (remotes.isNotEmpty && !remotes.any((r) => r.name == _selectedRemote)) {
        _selectedRemote = remotes.first.name;
      }
    });
  }

  Future<void> _doCommit() async {
    if (!ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
    final prefs = ref.read(generalPreferencesProvider);
    final autoCommit = await prefs.getAutoCommit();

    final sessionId = ref.read(activeSessionIdProvider);
    final changedFiles = sessionId != null
        ? ref.read(appliedChangesProvider.notifier).changesForSession(sessionId).map((c) => c.filePath).toList()
        : <String>[];

    final message = await ref.read(commitMessageActionsProvider.notifier).generateCommitMessage(changedFiles);

    if (autoCommit) {
      await _runCommit(message);
      return;
    }

    if (!mounted) return;
    final confirmed = await CommitDialog.show(context, message);
    if (confirmed != null) {
      await _runCommit(confirmed);
    }
  }

  Future<void> _runCommit(String message) async {
    final sha = await ref.read(gitActionsProvider.notifier).commit(widget.project.path, message);
    if (ref.read(gitActionsProvider).hasError) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Committed — $sha')));
      ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.project.path);
    }
  }

  Future<void> _doPush() async {
    if (!ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
    setState(() => _pushing = true);
    try {
      final git = ref.read(gitActionsProvider.notifier);
      final String target;
      if (_remotes.length <= 1) {
        final branch = await git.push(widget.project.path);
        target = 'origin/$branch';
      } else {
        await git.pushToRemote(widget.project.path, _selectedRemote);
        final branch = await git.currentBranch(widget.project.path);
        target = (branch == null || branch.isEmpty) ? _selectedRemote : '$_selectedRemote/$branch';
      }
      if (!ref.read(gitActionsProvider).hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pushed to $target')));
        ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.project.path);
      }
    } finally {
      if (mounted) setState(() => _pushing = false);
    }
  }

  Future<void> _doPushAll() async {
    if (!ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
    if (_remotes.isEmpty) return;
    setState(() => _pushing = true);
    final (:pushed, :failed) = await ref
        .read(gitActionsProvider.notifier)
        .pushAllRemotes(widget.project.path, _remotes)
        .whenComplete(() {
          if (mounted) setState(() => _pushing = false);
        });
    if (!mounted) return;
    final parts = <String>[];
    if (pushed.isNotEmpty) parts.add('Pushed: ${pushed.join(", ")}');
    if (failed.isNotEmpty) parts.add('Failed: ${failed.join(", ")}');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(parts.join(' · '))));
    if (pushed.isNotEmpty) {
      ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.project.path);
    }
  }

  Future<void> _doPull() async {
    if (!ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
    setState(() => _pulling = true);
    try {
      final n = await ref.read(gitActionsProvider.notifier).pull(widget.project.path);
      if (!ref.read(gitActionsProvider).hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pulled — $n new commit(s) from origin')));
        ref.read(projectSidebarActionsProvider.notifier).refreshGitState(widget.project.path);
      }
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  void _snack(String message, {Duration duration = const Duration(seconds: 4), SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: duration, action: action));
  }

  Future<void> _showCreatePrDialog() async {
    if (!ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
    final git = ref.read(gitActionsProvider.notifier);
    final prActions = ref.read(createPrActionsProvider.notifier);

    if (!await prActions.hasToken()) {
      _snack('Connect GitHub in Settings → Providers');
      return;
    }

    final currentBranch = await git.currentBranch(widget.project.path);
    if (currentBranch == null) {
      _snack('Could not read current branch — is this a valid git repo?');
      return;
    }
    if (currentBranch == 'main' || currentBranch == 'master') {
      _snack("You're on the default branch — create a feature branch first.");
      return;
    }

    final sessionId = ref.read(activeSessionIdProvider);
    final changedFiles = sessionId != null
        ? ref.read(appliedChangesProvider.notifier).changesForSession(sessionId).map((c) => c.filePath).toList()
        : <String>[];

    final (:title, :body) = await ref
        .read(commitMessageActionsProvider.notifier)
        .generatePrContent(changedFiles: changedFiles, branch: currentBranch);

    final remoteUrl = await git.getOriginUrl(widget.project.path);
    if (remoteUrl == null) {
      _snack("No `origin` remote configured — run `git remote add origin <url>` first.");
      return;
    }
    final repoMatch = RegExp(r'github\.com[:/]([^/]+)/([^/\.]+)').firstMatch(remoteUrl);
    if (repoMatch == null) {
      _snack('Could not detect GitHub owner/repo from remote');
      return;
    }
    final owner = repoMatch.group(1)!;
    final repo = repoMatch.group(2)!;

    final branches = await prActions.listBranches(owner, repo);
    if (branches == null) {
      _snack('Could not list branches for $owner/$repo — check your GitHub token and repo access.');
      return;
    }

    if (!mounted) return;

    final result = await CreatePrDialog.show(context, initialTitle: title, initialBody: body, branches: branches);
    if (result == null) return;

    final prUrl = await prActions.createPullRequest(
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
    // Only offer auto-open for canonical github.com URLs; otherwise just
    // show the text so the user can copy it manually.
    final canAutoOpen = prUrl.startsWith('https://github.com/');
    _snack(
      'Pull request created: $prUrl',
      duration: const Duration(seconds: 8),
      action: canAutoOpen
          ? SnackBarAction(
              label: 'Open',
              onPressed: () {
                unawaited(launchUrl(Uri.parse(prUrl), mode: LaunchMode.externalApplication));
              },
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    });

    ref.listen(commitMessageActionsProvider, (prev, next) {
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      if (failure is! CommitMessageFailure) return;
      final msg = switch (failure) {
        CommitMessageUnavailable() => 'AI commit message unavailable — using default.',
        PrContentUnavailable() => 'AI title/body unavailable — using a default. Check your model provider.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    });

    final liveStateAsync = ref.watch(gitLiveStateProvider(widget.project.path));
    final behindAsync = ref.watch(behindCountProvider(widget.project.path));

    final liveState = liveStateAsync.value;
    final behind = behindAsync.value;

    final canCommit = liveState?.hasUncommitted == true;
    final canPush = (liveState?.aheadCount ?? 0) > 0;
    final canPull = (behind ?? 0) > 0;
    final canPr = liveState?.branch != null && !(liveState?.isOnDefaultBranch ?? true);
    final hasRemotes = _remotes.isNotEmpty;
    final canDropdown = canPush || canPull || canPr || hasRemotes;

    final bool hasUnknownProbe =
        liveState?.isGit == true && (liveState?.hasUncommitted == null || liveState?.aheadCount == null);
    final String badgeLabel;
    if (hasUnknownProbe) {
      badgeLabel = ' !';
    } else if (behind == null) {
      badgeLabel = ' ↓?';
    } else if (behind > 0) {
      badgeLabel = ' ↓$behind';
    } else {
      badgeLabel = '';
    }
    final busy = _pushing || _pulling;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left: Commit
        Tooltip(
          message: hasUnknownProbe
              ? 'Git status unavailable — run `git status` in a terminal to diagnose'
              : canCommit
              ? 'Commit staged & unstaged changes'
              : 'No changes to commit',
          child: GestureDetector(
            onTap: (busy || !canCommit) ? null : _doCommit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              constraints: const BoxConstraints.tightFor(height: ThemeConstants.actionButtonHeight),
              decoration: BoxDecoration(
                color: busy
                    ? ThemeConstants.accentDark
                    : canCommit
                    ? ThemeConstants.accent
                    : ThemeConstants.inputSurface,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
              ),
              child: Center(
                widthFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.gitCommit, size: 12, color: canCommit ? Colors.white : ThemeConstants.mutedFg),
                    const SizedBox(width: 5),
                    Text(
                      _pushing
                          ? '● Pushing…'
                          : _pulling
                          ? '● Pulling…'
                          : 'Commit',
                      style: TextStyle(
                        color: canCommit ? Colors.white : ThemeConstants.mutedFg,
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
              onTap: canDropdown
                  ? () async {
                      final action = await showInstantMenuAnchoredTo<String>(
                        buttonContext: btnContext,
                        color: ThemeConstants.panelBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                          side: const BorderSide(color: ThemeConstants.faintFg),
                        ),
                        items: [
                          if (_remotes.length > 1) ...[
                            for (final remote in _remotes)
                              CheckedPopupMenuItem<String>(
                                value: 'select_${remote.name}',
                                checked: _selectedRemote == remote.name,
                                height: 40,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      remote.name,
                                      style: const TextStyle(
                                        color: ThemeConstants.textSecondary,
                                        fontSize: ThemeConstants.uiFontSizeSmall,
                                      ),
                                    ),
                                    Text(
                                      remote.url,
                                      style: const TextStyle(
                                        color: ThemeConstants.faintFg,
                                        fontSize: ThemeConstants.uiFontSizeLabel,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'push_all',
                              height: 32,
                              child: Text(
                                'Push to all remotes',
                                style: TextStyle(
                                  color: ThemeConstants.textSecondary,
                                  fontSize: ThemeConstants.uiFontSizeSmall,
                                ),
                              ),
                            ),
                            const PopupMenuDivider(),
                          ],
                          PopupMenuItem(
                            value: 'push',
                            height: 32,
                            enabled: canPush && !busy,
                            child: Text(
                              _pushing
                                  ? '● Pushing…'
                                  : _remotes.length > 1
                                  ? 'Push ↑ ($_selectedRemote)'
                                  : 'Push ↑',
                              style: TextStyle(
                                color: (canPush && !busy) ? ThemeConstants.textSecondary : ThemeConstants.faintFg,
                                fontSize: ThemeConstants.uiFontSizeSmall,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'pull',
                            height: 32,
                            enabled: canPull && !busy,
                            child: Text(
                              canPull ? 'Pull ↓${behind ?? ''}' : 'Pull',
                              style: TextStyle(
                                color: canPull ? ThemeConstants.accent : ThemeConstants.faintFg,
                                fontSize: ThemeConstants.uiFontSizeSmall,
                              ),
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'create_pr',
                            height: 32,
                            enabled: canPr,
                            child: Text(
                              'Create PR',
                              style: TextStyle(
                                color: canPr ? ThemeConstants.textSecondary : ThemeConstants.faintFg,
                                fontSize: ThemeConstants.uiFontSizeSmall,
                              ),
                            ),
                          ),
                        ],
                      );
                      if (action == null) return;
                      switch (action) {
                        case 'push':
                          unawaited(_doPush());
                        case 'push_all':
                          unawaited(_doPushAll());
                        case 'pull':
                          unawaited(_doPull());
                        case 'create_pr':
                          unawaited(_showCreatePrDialog());
                        case final String s when s.startsWith('select_'):
                          setState(() => _selectedRemote = s.substring('select_'.length));
                      }
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                constraints: const BoxConstraints.tightFor(height: ThemeConstants.actionButtonHeight),
                decoration: BoxDecoration(
                  color: canDropdown ? ThemeConstants.accentLight : ThemeConstants.inputSurface,
                  border: Border(
                    left: BorderSide(color: canDropdown ? ThemeConstants.accentDark : ThemeConstants.deepBorder),
                  ),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badgeLabel.isNotEmpty)
                        Text(
                          badgeLabel,
                          style: TextStyle(
                            color: canDropdown ? Colors.white : ThemeConstants.mutedFg,
                            fontSize: ThemeConstants.uiFontSizeLabel,
                          ),
                        ),
                      Icon(AppIcons.chevronDown, size: 11, color: canDropdown ? Colors.white : ThemeConstants.mutedFg),
                    ],
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
