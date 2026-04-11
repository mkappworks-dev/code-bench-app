import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'git_live_state.dart';
import 'git_service.dart';
import '../project/git_detector.dart';

part 'git_live_state_provider.g.dart';

/// Live git state for [projectPath]. Covers cheap, local-only operations.
/// Refresh triggers: window focus (via [AppLifecycleObserver]) and after
/// every in-app git mutation (commit, push, pull, checkout, init-git).
@riverpod
Future<GitLiveState> gitLiveState(Ref ref, String projectPath) async {
  if (!GitDetector.isGitRepo(projectPath)) return GitLiveState.notGit;

  final gitSvc = GitService(projectPath);

  final results = await Future.wait([gitSvc.currentBranch(), _hasUncommitted(projectPath), _aheadCount(projectPath)]);

  final branch = results[0] as String?;
  final hasUncommitted = results[1] as bool;
  final aheadCount = results[2] as int;

  return GitLiveState(
    isGit: true,
    branch: branch,
    hasUncommitted: hasUncommitted,
    aheadCount: aheadCount,
    isOnDefaultBranch: branch == 'main' || branch == 'master',
  );
}

/// Behind count for [projectPath]. Runs `git fetch` — network call.
/// Refreshes on a 5-minute timer and after post-push/pull mutations.
@riverpod
Future<int?> behindCount(Ref ref, String projectPath) async {
  final timer = Timer.periodic(const Duration(minutes: 5), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  if (!GitDetector.isGitRepo(projectPath)) return null;
  return GitService(projectPath).fetchBehindCount();
}

Future<bool> _hasUncommitted(String projectPath) async {
  final result = await Process.run('git', ['status', '--porcelain'], workingDirectory: projectPath);
  if (result.exitCode != 0) return false;
  return (result.stdout as String).trim().isNotEmpty;
}

/// Returns commits ahead of upstream. Returns 0 if no upstream is set
/// (git exits non-zero in that case).
Future<int> _aheadCount(String projectPath) async {
  final result = await Process.run('git', ['rev-list', '--count', '@{u}..HEAD', '--'], workingDirectory: projectPath);
  if (result.exitCode != 0) return 0;
  return int.tryParse((result.stdout as String).trim()) ?? 0;
}
