import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/git/datasource/git_datasource.dart';
import '../../data/git/datasource/git_datasource_process.dart';
import '../../data/git/datasource/git_live_state_datasource.dart';
import '../../data/git/datasource/git_live_state_datasource_process.dart';
import '../../data/git/repository/git_repository.dart';
import '../../data/git/repository/git_repository_impl.dart';

export '../../data/git/git_exceptions.dart';
export '../../data/git/datasource/git_datasource.dart' show GitRemote;

part 'git_service.g.dart';

@Riverpod(keepAlive: true)
GitService gitService(Ref ref) {
  return GitService(repo: ref.watch(gitRepositoryProvider), liveState: ref.watch(gitLiveStateDatasourceProvider));
}

/// Owns all git business logic: composite operations, live-state queries, and
/// branch management. [GitRepository] is reduced to 4 primitives only.
///
/// The per-call [_ds] factory mirrors the pattern that existed in
/// [GitRepositoryImpl] and is explicitly sanctioned — [GitDatasourceProcess]
/// is this feature's own datasource.
class GitService {
  GitService({required GitRepository repo, GitLiveStateDatasource? liveState}) : _repo = repo, _liveState = liveState;

  final GitRepository _repo;
  final GitLiveStateDatasource? _liveState;

  // ── Primitives (delegate to repository) ───────────────────────────────────

  Future<void> initGit(String path) => _repo.initGit(path);
  bool isGitRepo(String path) => _repo.isGitRepo(path);
  Future<String?> currentBranch(String path) => _repo.currentBranch(path);
  Future<String?> getOriginUrl(String path) => _repo.getOriginUrl(path);

  // ── Compositions (previously on GitRepository, now owned by service) ──────

  GitDatasource _ds(String path) => GitDatasourceProcess(path);

  Future<String> commit(String path, String message) => _ds(path).commit(message);
  Future<String> push(String path) => _ds(path).push();
  Future<void> pushToRemote(String path, String remote) => _ds(path).pushToRemote(remote);
  Future<int> pull(String path) => _ds(path).pull();
  Future<int?> fetchBehindCount(String path) => _ds(path).fetchBehindCount();
  Future<List<GitRemote>> listRemotes(String path) => _ds(path).listRemotes();
  Future<List<String>> listLocalBranches(String path) => _ds(path).listLocalBranches();
  Future<Set<String>> worktreeBranches(String path) => _ds(path).worktreeBranches();
  Future<void> checkout(String path, String branch) => _ds(path).checkout(branch);
  Future<void> createBranch(String path, String name) => _ds(path).createBranch(name);

  Future<GitLiveState> fetchLiveState(String path) =>
      (_liveState ?? GitLiveStateDatasourceProcess()).fetchLiveState(path);

  Future<int?> behindCount(String path) => (_liveState ?? GitLiveStateDatasourceProcess()).fetchBehindCount(path);
}
