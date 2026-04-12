import 'dart:async';

import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_icons.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/instant_menu.dart';
import '../../data/models/chat_session.dart';
import '../../data/models/project.dart';
import '../../data/models/project_action.dart';
import '../../features/chat/chat_notifier.dart';
import '../../features/chat/notifiers/create_pr_actions.dart';
import '../../features/chat/widgets/commit_dialog.dart';
import '../../features/project_sidebar/project_sidebar_notifier.dart';
import '../notifiers/action_output_notifier.dart';
import '../notifiers/ide_launch_actions.dart';
import '../../services/ai/ai_service_factory.dart';
import '../../services/git/git_live_state_provider.dart';
import '../../services/git/git_service.dart' show GitRemote;
import '../notifiers/git_actions.dart';
import '../notifiers/git_actions_failure.dart';
import '../../data/datasources/local/general_preferences.dart';
import '../../features/chat/widgets/create_pr_dialog.dart';
import '../../features/project_sidebar/project_sidebar_actions.dart';

/// Returns `true` if the project folder exists on disk. If the folder is
/// missing, shows a snackbar, kicks off a targeted status refresh so the
/// sidebar flips to the "missing" visual state, and returns `false`.
/// Checks the filesystem directly — does NOT rely on cached
/// `project.status` which may be stale.
bool _ensureProjectAvailable(BuildContext context, WidgetRef ref, String projectId, String projectPath) {
  if (ref.read(projectSidebarActionsProvider.notifier).projectExistsOnDisk(projectPath)) return true;
  // Fire-and-forget: the snackbar should show immediately; the sidebar
  // re-render follows on the next Drift stream emission.
  // Notifier already logs its own failures; swallow here so this
  // background refresh cannot surface as an uncaught exception.
  unawaited(ref.read(projectSidebarActionsProvider.notifier).refreshProjectStatus(projectId).catchError((Object _) {}));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'This project folder is missing. Right-click the project in the '
        'sidebar to Relocate or Remove it.',
      ),
      duration: Duration(seconds: 4),
    ),
  );
  return false;
}

class TopActionBar extends ConsumerWidget {
  const TopActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionId = ref.watch(activeSessionIdProvider);
    final projectId = ref.watch(activeProjectIdProvider);
    final sessionsAsync = ref.watch(chatSessionsProvider);
    final projectsAsync = ref.watch(projectsProvider);

    final sessionTitle =
        sessionsAsync.whenOrNull(
          data: (List<ChatSession> list) {
            if (sessionId == null) return 'Code Bench';
            return list.firstWhereOrNull((s) => s.sessionId == sessionId)?.title ?? 'New Chat';
          },
        ) ??
        'Code Bench';

    final project = projectsAsync.whenOrNull(
      data: (List<Project> list) {
        if (projectId == null) return null;
        return list.firstWhereOrNull((p) => p.id == projectId);
      },
    );

    final liveStateAsync = project != null ? ref.watch(gitLiveStateProvider(project.path)) : null;
    // Tri-state: `true` = known git repo, `false` = known non-git, `null` =
    // loading OR error. We only flip to the "No Git" badge / Init Git button
    // when we've **observed** a non-git state — loading and error keep the
    // bar neutral so it doesn't flicker to "Init Git" on every refocus.
    final bool? isGit = liveStateAsync?.value?.isGit;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: ThemeConstants.inputBackground,
        border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
      ),
      child: Row(
        children: [
          // ── Left: title + badges ──────────────────────────────────────────
          Text(
            sessionTitle,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: ThemeConstants.uiFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (project != null) ...[
            const SizedBox(width: 8),
            // Project name badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: ThemeConstants.inputSurface, borderRadius: BorderRadius.circular(4)),
              child: Text(
                project.name,
                style: const TextStyle(color: ThemeConstants.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
              ),
            ),
            // No Git badge (only when we've definitively observed the path
            // is not a git repo — skipped during loading/error).
            if (isGit == false) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF2A1F0A), borderRadius: BorderRadius.circular(4)),
                child: const Text(
                  'No Git',
                  style: TextStyle(
                    color: Color(0xFFE8A228),
                    fontSize: ThemeConstants.uiFontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
          const Spacer(),
          // ── Right: action buttons ─────────────────────────────────────────
          if (project != null)
            Opacity(
              opacity: project.status == ProjectStatus.missing ? 0.4 : 1.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionsDropdown(project: project),
                  const SizedBox(width: 5),
                  _VsCodeDropdown(projectId: project.id, projectPath: project.path),
                  const SizedBox(width: 5),
                  // Git action: Commit & Push (git) or Initialize Git
                  // (confirmed non-git). During loading/error (isGit == null)
                  // render a spacer so the layout doesn't jump and the user
                  // is never offered "Init Git" on a repo that already exists.
                  if (isGit == true)
                    _CommitPushButton(project: project)
                  else if (isGit == false)
                    _InitGitButton(project: project)
                  else
                    const SizedBox(width: 1, height: ThemeConstants.actionButtonHeight),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── VS Code dropdown ─────────────────────────────────────────────────────────

class _VsCodeDropdown extends ConsumerWidget {
  const _VsCodeDropdown({required this.projectId, required this.projectPath});
  final String projectId;
  final String projectPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Open in…',
      child: Builder(
        builder: (btnContext) => _ActionButton(
          icon: AppIcons.code,
          label: 'VS Code',
          trailingCaret: true,
          onTap: () async {
            final action = await showInstantMenuAnchoredTo<String>(
              buttonContext: btnContext,
              color: ThemeConstants.panelBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
                side: const BorderSide(color: Color(0xFF333333)),
              ),
              items: [
                _menuItem('vscode', AppIcons.code, 'VS Code'),
                _menuItem('cursor', AppIcons.aiMode, 'Cursor'),
                const PopupMenuDivider(),
                _menuItem('finder', AppIcons.folderOpen, 'Open in Finder'),
                _menuItem('terminal', AppIcons.terminal, 'Open in Terminal'),
              ],
            );
            if (action == null) return;
            if (!btnContext.mounted) return;
            final launcher = ref.read(ideLaunchActionsProvider.notifier);
            String? error;
            switch (action) {
              case 'vscode':
                if (!_ensureProjectAvailable(btnContext, ref, projectId, projectPath)) return;
                error = await launcher.openVsCode(projectPath);
              case 'cursor':
                if (!_ensureProjectAvailable(btnContext, ref, projectId, projectPath)) return;
                error = await launcher.openCursor(projectPath);
              case 'finder':
                error = await launcher.openInFinder(projectPath);
              case 'terminal':
                error = await launcher.openInTerminal(projectPath);
            }
            if (error != null && btnContext.mounted) {
              ScaffoldMessenger.of(
                btnContext,
              ).showSnackBar(SnackBar(content: Text(error), duration: const Duration(seconds: 4)));
            }
          },
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      height: 32,
      child: Row(
        children: [
          Icon(icon, size: 12, color: ThemeConstants.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Initialize Git button ─────────────────────────────────────────────────────

class _InitGitButton extends ConsumerWidget {
  const _InitGitButton({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(gitActionsProvider, (prev, next) {
      if (next is! AsyncError || !context.mounted) return;
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

    return _ActionButton(
      icon: AppIcons.gitMerge,
      label: 'Initialize Git',
      onTap: () async {
        if (!_ensureProjectAvailable(context, ref, project.id, project.path)) return;
        await ref.read(gitActionsProvider.notifier).initGit(project.path);

        if (ref.read(gitActionsProvider).hasError) return;

        ref.read(projectSidebarActionsProvider.notifier).refreshGitState(project.path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Git repository initialized')));
        }
      },
    );
  }
}

// ── Commit & Push split button ───────────────────────────────────────────────

class _CommitPushButton extends ConsumerStatefulWidget {
  const _CommitPushButton({required this.project});
  final Project project;

  @override
  ConsumerState<_CommitPushButton> createState() => _CommitPushButtonState();
}

class _CommitPushButtonState extends ConsumerState<_CommitPushButton> {
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
    // deleted working directory — same failure modes as
    // `_checkBehindCount`. Mirror that soft-failure behaviour: leave
    // `_remotes` as the empty list so the UI falls back to classic
    // single-remote Push.
    final remotes = await ref.read(gitActionsProvider.notifier).listRemotes(widget.project.path);
    // Notifier already logged the underlying cause and set AsyncError state;
    // the ref.listen in build() will surface it. Return early without
    // updating _remotes so the UI falls back to single-remote Push.
    if (ref.read(gitActionsProvider).hasError) return;
    if (!mounted) return;
    setState(() {
      _remotes = remotes;
      // If `origin` isn't one of the configured remotes (fork-first
      // workflows, custom names), fall back to the first remote so
      // `_doPush` has something valid to target.
      if (remotes.isNotEmpty && !remotes.any((r) => r.name == _selectedRemote)) {
        _selectedRemote = remotes.first.name;
      }
    });
  }

  Future<void> _doCommit() async {
    if (!_ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
    final prefs = ref.read(generalPreferencesProvider);
    final autoCommit = await prefs.getAutoCommit();

    // Collect file paths from applied changes for the active session.
    final sessionId = ref.read(activeSessionIdProvider);
    final changedFiles = sessionId != null
        ? ref.read(appliedChangesProvider.notifier).changesForSession(sessionId).map((c) => c.filePath).toList()
        : <String>[];

    // Generate commit message via AI.
    final model = ref.read(selectedModelProvider);
    final aiSvc = await ref.read(aiServiceProvider(model.provider).future);
    final prompt =
        'Write a conventional commit message (subject line only, max 72 chars) '
        'summarising these file changes: ${changedFiles.isEmpty ? "general changes" : changedFiles.join(", ")}. '
        'Reply with only the commit message, no explanation.';

    String message = 'chore: update files';
    if (aiSvc != null) {
      // ARCH-NOTE: Deliberate exception to the no-widget-catch rule.
      // Swallows NetworkException from a non-critical AI commit-message call.
      // Moving this into a notifier is tracked as a follow-up.
      try {
        final response = await aiSvc.sendMessage(history: const [], prompt: prompt, model: model);
        final text = response.content;
        if (text.isNotEmpty) {
          message = text.trim().replaceAll('"', '').split('\n').first.trim();
        }
      } on NetworkException {
        // Only swallow provider-side failures (offline, bad key, rate limit).
        // A TypeError from malformed provider JSON, or any other
        // `Error`/`Exception`, is a real bug and should propagate so we
        // see it instead of masking it as "provider unavailable".
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('AI commit message unavailable — using default.')));
        }
      }
    }

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
    if (!_ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
    setState(() => _pushing = true);
    try {
      final git = ref.read(gitActionsProvider.notifier);
      // Single-remote (or unknown) repos keep the classic `push()` path
      // because it also handles the "set upstream on first push" nicety.
      // A multi-remote repo explicitly targets `_selectedRemote` — the
      // one the user picked in the dropdown (or defaulted to `origin`).
      final String target;
      if (_remotes.length <= 1) {
        final branch = await git.push(widget.project.path);
        target = 'origin/$branch';
      } else {
        await git.pushToRemote(widget.project.path, _selectedRemote);
        // `currentBranch()` can return null in detached-HEAD or transient
        // git failure modes. Show the remote on its own rather than a
        // dangling "remote/" with empty suffix.
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
    if (!_ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
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
    if (!_ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
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

    final liveStateAsync = ref.watch(gitLiveStateProvider(widget.project.path));
    final behindAsync = ref.watch(behindCountProvider(widget.project.path));

    final liveState = liveStateAsync.value;
    final behind = behindAsync.value;

    // Nullable probe fields from [GitLiveState] mean "unknown" — never
    // treat them as falsy defaults. `hasUncommitted == null` or
    // `aheadCount == null` disables the action and triggers a "?" badge,
    // so a failing `git status` never deceptively dims the Commit button
    // on a dirty repo. See the class-level docs on [GitLiveState].
    final canCommit = liveState?.hasUncommitted == true;
    final canPush = (liveState?.aheadCount ?? 0) > 0;
    final canPull = (behind ?? 0) > 0;
    // Open PR requires a real branch that isn't the default. Detached HEAD
    // (branch == null) and unknown branch both fall through to `false`.
    final canPr = liveState?.branch != null && !(liveState?.isOnDefaultBranch ?? true);
    final hasRemotes = _remotes.isNotEmpty;
    final canDropdown = canPush || canPull || canPr || hasRemotes;

    // Probe-state badges on the dropdown. `↓?` signals "behind count
    // unknown" (offline/fetch failed), `!` signals "one of the local
    // probes failed" so the user can tell a disabled Commit/Push apart
    // from a genuinely clean/up-to-date repo.
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
                          side: const BorderSide(color: Color(0xFF333333)),
                        ),
                        items: [
                          // Multi-remote picker. Only rendered when the repo
                          // has more than one remote — single-origin repos
                          // keep the flat Push/Pull/Create-PR menu unchanged.
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
                        // Remote picker entries carry a dynamic `select_<name>`
                        // value so the switch pattern uses a guarded wildcard
                        // rather than a literal case per remote.
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

  void _snack(String message, {Duration duration = const Duration(seconds: 4), SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: duration, action: action));
  }

  Future<void> _showCreatePrDialog() async {
    if (!_ensureProjectAvailable(context, ref, widget.project.id, widget.project.path)) return;
    final git = ref.read(gitActionsProvider.notifier);
    final prActions = ref.read(createPrActionsProvider.notifier);

    // 1. Check GitHub token. The notifier resolves it via the shared
    //    githubApiServiceProvider so the raw PAT never crosses this layer.
    if (!await prActions.hasToken()) {
      _snack('Connect GitHub in Settings → Providers');
      return;
    }

    // 2. Ensure we're not on the default branch.
    final currentBranch = await git.currentBranch(widget.project.path);
    if (currentBranch == null) {
      _snack('Could not read current branch — is this a valid git repo?');
      return;
    }
    if (currentBranch == 'main' || currentBranch == 'master') {
      _snack("You're on the default branch — create a feature branch first.");
      return;
    }

    // 3. Generate PR title + body via AI.
    final sessionId = ref.read(activeSessionIdProvider);
    final changedFiles = sessionId != null
        ? ref.read(appliedChangesProvider.notifier).changesForSession(sessionId).map((c) => c.filePath).toList()
        : <String>[];
    final model = ref.read(selectedModelProvider);
    final aiSvc = await ref.read(aiServiceProvider(model.provider).future);

    String prTitle = currentBranch.replaceAll('-', ' ');
    String prBody = '';
    if (aiSvc != null) {
      // ARCH-NOTE: Deliberate exception to the no-widget-catch rule.
      // Swallows NetworkException from a non-critical AI PR title/body call.
      // Moving this into a notifier is tracked as a follow-up.
      try {
        final prompt =
            'Generate a PR title (max 70 chars) and bullet-point body for these '
            'changes: ${changedFiles.isEmpty ? "general changes" : changedFiles.join(", ")}. '
            'Reply in this format:\nTITLE: <title>\nBODY:\n<bullets>';
        final response = await aiSvc.sendMessage(history: const [], prompt: prompt, model: model);
        final text = response.content;
        final titleMatch = RegExp(r'TITLE:\s*(.+)').firstMatch(text);
        final bodyMatch = RegExp(r'BODY:\n([\s\S]+)').firstMatch(text);
        if (titleMatch != null) prTitle = titleMatch.group(1)!.trim();
        if (bodyMatch != null) prBody = bodyMatch.group(1)!.trim();
      } on NetworkException {
        // As in `_doCommit`: narrow to provider-side failures so a real
        // bug in the regex / response shape propagates instead of being
        // explained away as "AI unavailable".
        _snack('AI title/body unavailable — using a default. Check your model provider.');
      }
    }

    // 4. Parse owner/repo from git remote URL.
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

    // 5. Fetch branches from GitHub. If this fails, surface the failure
    //    instead of silently defaulting to ['main', 'master'] — otherwise
    //    the user's real problem (bad token, 404, offline) is masked until
    //    the PR submission fails with an opaque error.
    final branches = await prActions.listBranches(owner, repo);
    if (branches == null) {
      _snack('Could not list branches for $owner/$repo — check your GitHub token and repo access.');
      return;
    }

    if (!mounted) return;

    // 6. Show dialog.
    final result = await CreatePrDialog.show(context, initialTitle: prTitle, initialBody: prBody, branches: branches);
    if (result == null) return;

    // 7. Create PR and surface the URL to the user.
    {
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
      // Defence-in-depth on the GitHub API response: `prUrl` comes from
      // `data['html_url']` and is sent to `open`. The `--` separator
      // already blocks flag parsing, but it does NOT constrain URL
      // schemes (`file://`, `x-apple-…://`, etc.). Only offer the
      // "Open" action for canonical github.com URLs; otherwise just
      // show the text so the user can copy it manually.
      final canAutoOpen = prUrl.startsWith('https://github.com/');
      // Always surface the URL so the user can reach their PR even if
      // `open` fails (browser misconfigured, headless CI, etc).
      _snack(
        'Pull request created: $prUrl',
        duration: const Duration(seconds: 8),
        action: canAutoOpen
            ? SnackBarAction(
                label: 'Open',
                onPressed: () {
                  // Fire-and-forget. `launchUrl` works cross-platform and
                  // does not depend on the `open` binary being available.
                  unawaited(launchUrl(Uri.parse(prUrl), mode: LaunchMode.externalApplication));
                },
              )
            : null,
      );
      // Note: no eager auto-open. The SnackBarAction is the single
      // source of truth so the user isn't surprised by a browser launch,
      // and we don't double-fire `open` on a successful create.
    }
  }
}

// ── Shared action button ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, this.onTap, this.trailingCaret = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool trailingCaret;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      constraints: const BoxConstraints.tightFor(height: ThemeConstants.actionButtonHeight),
      decoration: BoxDecoration(
        color: ThemeConstants.inputSurface,
        border: Border.all(color: ThemeConstants.deepBorder),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        widthFactor: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: ThemeConstants.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
            if (trailingCaret) ...[
              const SizedBox(width: 4),
              const Icon(AppIcons.chevronDown, size: 10, color: ThemeConstants.faintFg),
            ],
          ],
        ),
      ),
    );

    // When used as a PopupMenuButton child, onTap is null and the outer
    // PopupMenuButton wraps us in its own InkWell — don't double-wrap,
    // or the inner InkWell swallows the tap before the menu can open.
    if (onTap == null) return content;

    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(5), child: content);
  }
}

// ── Actions dropdown ─────────────────────────────────────────────────────────

class _ActionsDropdown extends ConsumerWidget {
  const _ActionsDropdown({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Actions',
      child: Builder(
        builder: (btnContext) => _ActionButton(
          icon: AppIcons.add,
          label: 'Actions',
          trailingCaret: true,
          onTap: () async {
            final value = await showInstantMenuAnchoredTo<Object>(
              buttonContext: btnContext,
              color: ThemeConstants.panelBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
                side: const BorderSide(color: Color(0xFF333333)),
              ),
              items: [
                for (final action in project.actions)
                  PopupMenuItem<Object>(
                    value: action,
                    height: 32,
                    child: Row(
                      children: [
                        const Icon(AppIcons.run, size: 12, color: ThemeConstants.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          action.name,
                          style: const TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: ThemeConstants.uiFontSizeSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (project.actions.isNotEmpty) const PopupMenuDivider(),
                PopupMenuItem<Object>(
                  value: '__add__',
                  height: 32,
                  child: Row(
                    children: const [
                      Icon(AppIcons.add, size: 12, color: ThemeConstants.textSecondary),
                      SizedBox(width: 6),
                      Text(
                        'Add action',
                        style: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                      ),
                    ],
                  ),
                ),
              ],
            );
            if (value == null) return;
            if (!btnContext.mounted) return;
            if (!_ensureProjectAvailable(btnContext, ref, project.id, project.path)) return;
            if (value == '__add__') {
              if (!btnContext.mounted) return;
              final action = await _showAddActionDialog(btnContext);
              if (action != null) {
                final newActions = [...project.actions, action];
                await ref.read(projectSidebarActionsProvider.notifier).updateProjectActions(project.id, newActions);
              }
            } else if (value is ProjectAction) {
              await ref.read(actionOutputProvider.notifier).run(value, project.path);
            }
          },
        ),
      ),
    );
  }

  Future<ProjectAction?> _showAddActionDialog(BuildContext context) {
    return showDialog<ProjectAction>(context: context, builder: (_) => const _AddActionDialog());
  }
}

class _AddActionDialog extends StatefulWidget {
  const _AddActionDialog();

  @override
  State<_AddActionDialog> createState() => _AddActionDialogState();
}

class _AddActionDialogState extends State<_AddActionDialog> {
  final _nameController = TextEditingController();
  final _commandController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ThemeConstants.inputSurface,
      title: const Text('Add Action', style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 14)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Name (e.g. Run tests)',
              labelStyle: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
            style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commandController,
            decoration: const InputDecoration(
              labelText: 'Command (e.g. flutter test)',
              labelStyle: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              helperText: 'Arguments are split on whitespace. Quoted args are not supported.',
              helperStyle: TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
            style: TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: ThemeConstants.uiFontSize,
              fontFamily: ThemeConstants.editorFontFamily,
            ),
          ),
          const SizedBox(height: 10),
          // Security: the app runs without macOS App Sandbox (see
          // macos/Runner/README.md), so user-defined actions execute
          // with the user's full privileges. Make that visible.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(AppIcons.warning, size: 12, color: Color(0xFFE8A228)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Commands run with your full user privileges. Only add actions '
                  'you would run in a terminal yourself.',
                  style: TextStyle(color: Color(0xFFE8A228), fontSize: ThemeConstants.uiFontSizeLabel),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: ThemeConstants.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final command = _commandController.text.trim();
            if (name.isEmpty || command.isEmpty) return;
            Navigator.of(context).pop(ProjectAction(name: name, command: command));
          },
          child: const Text('Save', style: TextStyle(color: ThemeConstants.accent)),
        ),
      ],
    );
  }
}
