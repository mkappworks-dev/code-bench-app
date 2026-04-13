import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasource/git_datasource_process.dart';
import '../datasource/git_live_state_datasource.dart';
import '../datasource/git_live_state_datasource_process.dart';
import 'git_repository.dart';

part 'git_repository_impl.g.dart';

@Riverpod(keepAlive: true)
GitRepository gitRepository(Ref ref) {
  return GitRepositoryImpl(liveState: ref.watch(gitLiveStateDatasourceProvider));
}

class GitRepositoryImpl implements GitRepository {
  GitRepositoryImpl({required GitLiveStateDatasource liveState}) : _liveState = liveState;

  final GitLiveStateDatasource _liveState;

  @override
  Future<void> initGit(String path) => GitDatasourceProcess(path).initGit();

  @override
  Future<String?> currentBranch(String path) => GitDatasourceProcess(path).currentBranch();

  @override
  Future<String?> getOriginUrl(String path) => GitDatasourceProcess(path).getOriginUrl();

  @override
  bool isGitRepo(String path) => _liveState.isGitRepo(path);
}
