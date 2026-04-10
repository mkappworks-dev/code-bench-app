import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/chat_session.dart';
import '../../data/models/project.dart';
import '../../data/models/project_action.dart';
import '../../features/chat/chat_notifier.dart';
import '../../features/chat/widgets/commit_dialog.dart';
import '../../features/project_sidebar/project_sidebar_notifier.dart';
import '../../services/actions/action_runner_service.dart';
import '../../services/ai/ai_service_factory.dart';
import '../../services/git/git_service.dart';
import '../../services/ide/ide_launch_service.dart';
import '../../data/datasources/local/general_preferences.dart';
import '../../data/datasources/local/secure_storage_source.dart';
import '../../features/chat/widgets/create_pr_dialog.dart';
import '../../services/github/github_api_service.dart';
import '../../services/project/project_service.dart';

class TopActionBar extends ConsumerWidget {
  const TopActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionId = ref.watch(activeSessionIdProvider);
    final projectId = ref.watch(activeProjectIdProvider);
    final sessionsAsync = ref.watch(chatSessionsProvider);
    final projectsAsync = ref.watch(projectsProvider);

    final sessionTitle = sessionsAsync.whenOrNull(
          data: (List<ChatSession> list) {
            if (sessionId == null) return 'Code Bench';
            try {
              return list.firstWhere((s) => s.sessionId == sessionId).title;
            } catch (_) {
              return 'New Chat';
            }
          },
        ) ??
        'Code Bench';

    final project = projectsAsync.whenOrNull(
      data: (List<Project> list) {
        if (projectId == null) return null;
        try {
          return list.firstWhere((p) => p.id == projectId);
        } catch (_) {
          return null;
        }
      },
    );

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
              decoration: BoxDecoration(
                color: ThemeConstants.inputSurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                project.name,
                style: const TextStyle(
                  color: ThemeConstants.mutedFg,
                  fontSize: ThemeConstants.uiFontSizeLabel,
                ),
              ),
            ),
            // No Git badge (only when not a git repo)
            if (!project.isGit) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1F0A),
                  borderRadius: BorderRadius.circular(4),
                ),
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
          if (project != null) _ActionsDropdown(project: project),
          const SizedBox(width: 5),
          if (project != null) _VsCodeDropdown(projectPath: project.path),
          const SizedBox(width: 5),
          // Git action: Commit & Push (git) or Initialize Git (no git)
          if (project != null && project.isGit)
            _CommitPushButton(project: project)
          else if (project != null && !project.isGit)
            _InitGitButton(project: project),
        ],
      ),
    );
  }
}

// ── VS Code dropdown ─────────────────────────────────────────────────────────

class _VsCodeDropdown extends ConsumerWidget {
  const _VsCodeDropdown({required this.projectPath});
  final String projectPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(ideLaunchServiceProvider);
    return PopupMenuButton<String>(
      tooltip: 'Open in…',
      color: ThemeConstants.inputSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: ThemeConstants.deepBorder),
      ),
      itemBuilder: (_) => [
        _menuItem('vscode', LucideIcons.code, 'VS Code'),
        _menuItem('cursor', LucideIcons.zap, 'Cursor'),
        const PopupMenuDivider(),
        _menuItem('finder', LucideIcons.folderOpen, 'Open in Finder'),
        _menuItem('terminal', LucideIcons.terminal, 'Open in Terminal'),
      ],
      onSelected: (action) async {
        String? error;
        switch (action) {
          case 'vscode':
            error = await svc.openVsCode(projectPath);
          case 'cursor':
            error = await svc.openCursor(projectPath);
          case 'finder':
            await svc.openInFinder(projectPath);
          case 'terminal':
            await svc.openInTerminal(projectPath);
        }
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), duration: const Duration(seconds: 4)),
          );
        }
      },
      child: _ActionButton(
        icon: LucideIcons.code,
        label: 'VS Code',
        trailingCaret: true,
        onTap: () {}, // tap handled by PopupMenuButton
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
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
    return _ActionButton(
      icon: LucideIcons.gitMerge,
      label: 'Initialize Git',
      onTap: () async {
        try {
          final gitSvc = GitService(project.path);
          await gitSvc.initGit();
          await ref.read(projectServiceProvider).refreshGitStatus(project.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Git repository initialized')),
            );
          }
        } catch (e, st) {
          if (kDebugMode) debugPrint('[_InitGitButton] initGit failed: $e\n$st');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to initialize git')),
            );
          }
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
  int _behindCount = 0;

  @override
  void initState() {
    super.initState();
    _checkBehindCount();
  }

  Future<void> _checkBehindCount() async {
    final count = await GitService(widget.project.path).fetchBehindCount();
    if (mounted) setState(() => _behindCount = count);
  }

  Future<void> _doCommit() async {
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
    final prompt = 'Write a conventional commit message (subject line only, max 72 chars) '
        'summarising these file changes: ${changedFiles.isEmpty ? "general changes" : changedFiles.join(", ")}. '
        'Reply with only the commit message, no explanation.';

    String message = 'chore: update files';
    if (aiSvc != null) {
      try {
        final response = await aiSvc.sendMessage(
          history: const [],
          prompt: prompt,
          model: model,
        );
        final text = response.content;
        if (text.isNotEmpty) {
          message = text.trim().replaceAll('"', '').split('\n').first.trim();
        }
      } catch (e, st) {
        if (kDebugMode) debugPrint('[_CommitPushButton] AI commit message failed: $e\n$st');
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
    try {
      final sha = await GitService(widget.project.path).commit(message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Committed — $sha')),
        );
      }
    } on GitException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Commit failed: ${e.message}')));
      }
    }
  }

  Future<void> _doPush() async {
    setState(() => _pushing = true);
    try {
      final branch = await GitService(widget.project.path).push();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pushed to origin/$branch')));
      }
    } on GitNoUpstreamException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No upstream branch. Run `git push -u origin <branch>` in your terminal.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } on GitAuthException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Push failed — check your git credentials.')),
        );
      }
    } on GitException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Push failed: ${e.message}')));
      }
    } finally {
      if (mounted) setState(() => _pushing = false);
    }
  }

  Future<void> _doPull() async {
    setState(() => _pulling = true);
    try {
      final n = await GitService(widget.project.path).pull();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pulled — $n new commit(s) from origin')),
        );
        setState(() => _behindCount = 0);
      }
    } on GitConflictException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pull failed — merge conflict detected. Resolve conflicts in your editor.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } on GitNoUpstreamException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No upstream branch set.')));
      }
    } on GitException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pull failed: ${e.message}')));
      }
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeLabel = _behindCount > 0 ? ' ↓$_behindCount' : '';
    final busy = _pushing || _pulling;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left: Commit
        GestureDetector(
          onTap: busy ? null : _doCommit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: busy ? ThemeConstants.accentDark : ThemeConstants.accent,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.gitCommitHorizontal, size: 12, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  _pushing
                      ? '● Pushing…'
                      : _pulling
                          ? '● Pulling…'
                          : 'Commit',
                  style: const TextStyle(color: Colors.white, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
              ],
            ),
          ),
        ),
        // Right: dropdown
        PopupMenuButton<String>(
          tooltip: 'Git actions',
          color: ThemeConstants.inputSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: ThemeConstants.deepBorder),
          ),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'push',
              child: Text(
                _pushing ? '● Pushing…' : 'Push ↑',
                style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ),
            PopupMenuItem(
              value: 'pull',
              child: Text(
                _behindCount > 0 ? 'Pull ↓$_behindCount' : 'Pull',
                style: TextStyle(
                  color: _behindCount > 0 ? ThemeConstants.accent : ThemeConstants.textSecondary,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                ),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'create_pr',
              child: Text(
                'Create PR',
                style: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ),
          ],
          onSelected: (action) {
            switch (action) {
              case 'push':
                _doPush();
              case 'pull':
                _doPull();
              case 'create_pr':
                _showCreatePrDialog();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeConstants.accentLight,
              border: const Border(left: BorderSide(color: ThemeConstants.accentDark)),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
            ),
            child: Row(
              children: [
                if (badgeLabel.isNotEmpty)
                  Text(badgeLabel,
                      style: const TextStyle(color: Colors.white, fontSize: ThemeConstants.uiFontSizeLabel)),
                const Icon(LucideIcons.chevronDown, size: 11, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreatePrDialog() async {
    // 1. Check GitHub token.
    final storage = ref.read(secureStorageSourceProvider);
    final token = await storage.readGitHubToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connect GitHub in Settings → Providers')),
        );
      }
      return;
    }

    // 2. Ensure we're not on the default branch.
    final branchResult = await Process.run(
      'git',
      ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: widget.project.path,
    );
    final currentBranch = (branchResult.stdout as String).trim();
    if (currentBranch == 'main' || currentBranch == 'master') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're on the default branch — create a feature branch first.")),
        );
      }
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
      try {
        final prompt = 'Generate a PR title (max 70 chars) and bullet-point body for these '
            'changes: ${changedFiles.isEmpty ? "general changes" : changedFiles.join(", ")}. '
            'Reply in this format:\nTITLE: <title>\nBODY:\n<bullets>';
        final response = await aiSvc.sendMessage(history: const [], prompt: prompt, model: model);
        final text = response.content;
        final titleMatch = RegExp(r'TITLE:\s*(.+)').firstMatch(text);
        final bodyMatch = RegExp(r'BODY:\n([\s\S]+)').firstMatch(text);
        if (titleMatch != null) prTitle = titleMatch.group(1)!.trim();
        if (bodyMatch != null) prBody = bodyMatch.group(1)!.trim();
      } catch (e, st) {
        if (kDebugMode) debugPrint('[_CommitPushButton] AI PR title/body failed: $e\n$st');
      }
    }

    // 4. Parse owner/repo from git remote URL.
    final remoteResult = await Process.run(
      'git',
      ['remote', 'get-url', 'origin'],
      workingDirectory: widget.project.path,
    );
    final remoteUrl = (remoteResult.stdout as String).trim();
    final repoMatch = RegExp(r'github\.com[:/]([^/]+)/([^/\.]+)').firstMatch(remoteUrl);
    if (repoMatch == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect GitHub owner/repo from remote')),
        );
      }
      return;
    }
    final owner = repoMatch.group(1)!;
    final repo = repoMatch.group(2)!;

    // 5. Fetch branches from GitHub.
    List<String> branches = ['main', 'master'];
    try {
      branches = await GitHubApiService(token).listRepoBranches(owner, repo);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[_CommitPushButton] listRepoBranches failed: $e\n$st');
    }

    if (!mounted) return;

    // 6. Show dialog.
    final result = await CreatePrDialog.show(
      context,
      initialTitle: prTitle,
      initialBody: prBody,
      branches: branches,
    );
    if (result == null) return;

    // 7. Create PR and open in browser.
    try {
      final prUrl = await GitHubApiService(token).createPullRequest(
        owner: owner,
        repo: repo,
        title: result.title,
        body: result.body,
        head: currentBranch,
        base: result.base,
        draft: result.draft,
      );
      await Process.run('open', [prUrl]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pull request created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create PR: $e')),
        );
      }
    }
  }
}

// ── Shared action button ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingCaret = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool trailingCaret;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: ThemeConstants.inputSurface,
          border: Border.all(color: ThemeConstants.deepBorder),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: ThemeConstants.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: ThemeConstants.uiFontSizeSmall,
              ),
            ),
            if (trailingCaret) ...[
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronDown, size: 10, color: ThemeConstants.faintFg),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Actions dropdown ─────────────────────────────────────────────────────────

class _ActionsDropdown extends ConsumerWidget {
  const _ActionsDropdown({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<Object>(
      tooltip: 'Actions',
      color: ThemeConstants.inputSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: ThemeConstants.deepBorder),
      ),
      itemBuilder: (_) => [
        for (final action in project.actions)
          PopupMenuItem<Object>(
            value: action,
            child: Row(
              children: [
                const Icon(LucideIcons.play, size: 12, color: ThemeConstants.textSecondary),
                const SizedBox(width: 6),
                Text(action.name,
                    style:
                        const TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall)),
              ],
            ),
          ),
        if (project.actions.isNotEmpty) const PopupMenuDivider(),
        PopupMenuItem<Object>(
          value: '__add__',
          child: Row(
            children: const [
              Icon(LucideIcons.plus, size: 12, color: ThemeConstants.textSecondary),
              SizedBox(width: 6),
              Text('+ Add action',
                  style: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall)),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == '__add__') {
          final action = await _showAddActionDialog(context);
          if (action != null) {
            final newActions = [...project.actions, action];
            await ref.read(projectServiceProvider).updateProjectActions(project.id, newActions);
          }
        } else if (value is ProjectAction) {
          await ref.read(actionOutputNotifierProvider.notifier).run(value, project.path);
        }
      },
      child: _ActionButton(
        icon: LucideIcons.plus,
        label: 'Actions',
        trailingCaret: true,
        onTap: () {},
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
            ),
            style: TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: ThemeConstants.uiFontSize,
              fontFamily: ThemeConstants.editorFontFamily,
            ),
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
