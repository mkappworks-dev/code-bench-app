import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../models/git_live_state.dart';
import 'git_datasource_process.dart';
import 'git_live_state_datasource.dart';

part 'git_live_state_datasource_process.g.dart';

@Riverpod(keepAlive: true)
GitLiveStateDatasource gitLiveStateDatasource(Ref ref) => GitLiveStateDatasourceProcess();

class GitLiveStateDatasourceProcess implements GitLiveStateDatasource {
  /// Returns `true` when [projectPath] is a git repository.
  ///
  /// Handles both cases:
  /// - Normal clone: `.git` is a **directory**.
  /// - Linked worktree: `.git` is a **file** (`gitdir: /path/to/main/.git/worktrees/<name>`).
  @override
  bool isGitRepo(String projectPath) {
    final type = FileSystemEntity.typeSync('$projectPath/.git');
    return type == FileSystemEntityType.directory || type == FileSystemEntityType.file;
  }

  /// Fetches the live git state for [projectPath].
  ///
  /// Probe failures are surfaced as `null` fields — not as falsy defaults —
  /// so the UI never silently dims a button when git actually crashed.
  @override
  Future<GitLiveState> fetchLiveState(String projectPath) async {
    if (!isGitRepo(projectPath)) return GitLiveState.notGit;

    final ds = GitDatasourceProcess(projectPath);

    final results = await Future.wait([ds.currentBranch(), _hasUncommitted(projectPath), _aheadCount(projectPath)]);

    final branch = results[0] as String?;
    final hasUncommitted = results[1] as bool?;
    final aheadCount = results[2] as int?;

    return GitLiveState(
      isGit: true,
      branch: branch,
      hasUncommitted: hasUncommitted,
      aheadCount: aheadCount,
      // Detached HEAD (branch == null) is never "on the default branch".
      isOnDefaultBranch: branch == 'main' || branch == 'master',
    );
  }

  /// Fetches how many commits HEAD is behind the remote for [projectPath].
  /// Returns `null` when not a git repo or when the count cannot be
  /// determined (offline, no remote, fetch failed).
  @override
  Future<int?> fetchBehindCount(String projectPath) async {
    if (!isGitRepo(projectPath)) return null;
    return GitDatasourceProcess(projectPath).fetchBehindCount();
  }

  /// Runs `git status --porcelain`. Returns `true`/`false` for a known dirty/
  /// clean state, or `null` when the probe itself failed (binary missing,
  /// cwd deleted, permission denied, unexpected non-zero exit). The `null`
  /// is logged so a UI that renders "status unknown" is still attributable.
  Future<bool?> _hasUncommitted(String projectPath) async {
    try {
      final result = await Process.run('git', ['status', '--porcelain'], workingDirectory: projectPath);
      if (result.exitCode != 0) {
        sLog(
          '[GitLiveStateDatasourceProcess] git status --porcelain exit=${result.exitCode} '
          'stderr=${(result.stderr as String).trim()}',
        );
        return null;
      }
      return (result.stdout as String).trim().isNotEmpty;
    } on ProcessException catch (e) {
      sLog('[GitLiveStateDatasourceProcess] git status --porcelain threw: ${e.message}');
      return null;
    }
  }

  /// Returns commits ahead of upstream (`@{u}..HEAD`).
  /// Distinguishes:
  ///   * known `0` — no upstream set, or upstream exists and HEAD is at tip
  ///   * known `N` — upstream exists and HEAD is N commits ahead
  ///   * `null`   — probe failed (binary missing, cwd deleted, etc.)
  /// "No upstream" is a legitimate zero, not an unknown, so the Push button
  /// stays dimmed for a repo that simply hasn't been pushed yet.
  Future<int?> _aheadCount(String projectPath) async {
    try {
      final result = await Process.run('git', [
        'rev-list',
        '--count',
        '@{u}..HEAD',
        '--',
      ], workingDirectory: projectPath);
      if (result.exitCode != 0) {
        final stderr = (result.stderr as String);
        // `git rev-list @{u}` fails loudly when there's no upstream. Treat
        // those stderr signatures as a known zero, so the button stays
        // dimmed rather than flipping to "unknown" for every fresh repo.
        if (stderr.contains('no upstream') || stderr.contains('unknown revision') || stderr.contains('@{u}')) {
          return 0;
        }
        sLog(
          '[GitLiveStateDatasourceProcess] git rev-list exit=${result.exitCode} '
          'stderr=${stderr.trim()}',
        );
        return null;
      }
      return int.tryParse((result.stdout as String).trim()) ?? 0;
    } on ProcessException catch (e) {
      sLog('[GitLiveStateDatasourceProcess] git rev-list threw: ${e.message}');
      return null;
    }
  }
}
