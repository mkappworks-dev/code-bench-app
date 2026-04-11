import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../project/git_detector.dart';
import 'git_live_state.dart';
import 'git_service.dart';

part 'git_live_state_provider.g.dart';

/// Live git state for [projectPath]. Covers cheap, local-only operations.
/// Refresh triggers: window focus (via [AppLifecycleObserver]) and after
/// every in-app git mutation (commit, push, pull, checkout, init-git).
///
/// Probe failures are surfaced as `null` fields in [GitLiveState] — **not**
/// as falsy defaults — so the UI never silently dims a button when git
/// actually crashed. Every `null` is also logged via `sLog` so the cause is
/// attributable from the platform log.
@riverpod
Future<GitLiveState> gitLiveState(Ref ref, String projectPath) async {
  if (!GitDetector.isGitRepo(projectPath)) return GitLiveState.notGit;

  final gitSvc = GitService(projectPath);

  final results = await Future.wait([gitSvc.currentBranch(), _hasUncommitted(projectPath), _aheadCount(projectPath)]);

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

/// Behind count for [projectPath]. Runs `git fetch` — network call.
/// Refreshes on a 5-minute timer and after post-push/pull mutations.
///
/// The `isGitRepo` gate sits **above** the timer setup so non-git projects
/// don't pay for a perpetual self-invalidating timer.
@riverpod
Future<int?> behindCount(Ref ref, String projectPath) async {
  if (!GitDetector.isGitRepo(projectPath)) return null;

  final timer = Timer.periodic(const Duration(minutes: 5), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return GitService(projectPath).fetchBehindCount();
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
        '[gitLiveState] git status --porcelain exit=${result.exitCode} '
        'stderr=${(result.stderr as String).trim()}',
      );
      return null;
    }
    return (result.stdout as String).trim().isNotEmpty;
  } on ProcessException catch (e) {
    sLog('[gitLiveState] git status --porcelain threw: ${e.message}');
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
    final result = await Process.run('git', ['rev-list', '--count', '@{u}..HEAD', '--'], workingDirectory: projectPath);
    if (result.exitCode != 0) {
      final stderr = (result.stderr as String);
      // `git rev-list @{u}` fails loudly when there's no upstream. Treat
      // those stderr signatures as a known zero, so the button stays
      // dimmed rather than flipping to "unknown" for every fresh repo.
      if (stderr.contains('no upstream') || stderr.contains('unknown revision') || stderr.contains('@{u}')) {
        return 0;
      }
      sLog(
        '[gitLiveState] git rev-list exit=${result.exitCode} '
        'stderr=${stderr.trim()}',
      );
      return null;
    }
    return int.tryParse((result.stdout as String).trim()) ?? 0;
  } on ProcessException catch (e) {
    sLog('[gitLiveState] git rev-list threw: ${e.message}');
    return null;
  }
}
