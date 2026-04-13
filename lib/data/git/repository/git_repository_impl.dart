import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasource/git_datasource.dart';
import '../datasource/git_datasource_process.dart';
import '../datasource/git_live_state_datasource.dart';
import '../datasource/git_live_state_datasource_process.dart';
import 'git_repository.dart';

part 'git_repository_impl.g.dart';

@Riverpod(keepAlive: true)
GitRepository gitRepository(Ref ref) {
  return GitRepositoryImpl(liveState: ref.watch(gitLiveStateDatasourceProvider));
}

/// Convenience provider: replaces gitLiveStateProvider(path) family.
@riverpod
Future<GitLiveState> gitLiveState(Ref ref, String projectPath) =>
    ref.watch(gitRepositoryProvider).fetchLiveState(projectPath);

/// Replaces behindCountProvider(path) family — includes the 5-minute
/// self-invalidating timer.
@riverpod
Future<int?> behindCount(Ref ref, String projectPath) async {
  final timer = Timer.periodic(const Duration(minutes: 5), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return ref.watch(gitRepositoryProvider).behindCount(projectPath);
}

class GitRepositoryImpl implements GitRepository {
  GitRepositoryImpl({required GitLiveStateDatasource liveState}) : _liveState = liveState;

  final GitLiveStateDatasource _liveState;

  // For process operations, create datasource per-call (matches old family pattern).
  GitDatasource _ds(String projectPath) => GitDatasourceProcess(projectPath);

  @override
  Future<void> initGit(String p) => _ds(p).initGit();

  @override
  Future<String> commit(String p, String msg) => _ds(p).commit(msg);

  @override
  Future<String> push(String p) => _ds(p).push();

  @override
  Future<void> pushToRemote(String p, String remote) => _ds(p).pushToRemote(remote);

  @override
  Future<int> pull(String p) => _ds(p).pull();

  @override
  Future<int?> fetchBehindCount(String p) => _ds(p).fetchBehindCount();

  @override
  Future<String?> currentBranch(String p) => _ds(p).currentBranch();

  @override
  Future<String?> getOriginUrl(String p) => _ds(p).getOriginUrl();

  @override
  Future<List<GitRemote>> listRemotes(String p) => _ds(p).listRemotes();

  @override
  Future<List<String>> listLocalBranches(String p) => _ds(p).listLocalBranches();

  @override
  Future<Set<String>> worktreeBranches(String p) => _ds(p).worktreeBranches();

  @override
  Future<void> checkout(String p, String branch) => _ds(p).checkout(branch);

  @override
  Future<void> createBranch(String p, String name) => _ds(p).createBranch(name);

  @override
  Future<GitLiveState> fetchLiveState(String p) => _liveState.fetchLiveState(p);

  @override
  Future<int?> behindCount(String p) => _liveState.fetchBehindCount(p);

  @override
  bool isGitRepo(String p) => _liveState.isGitRepo(p);
}
