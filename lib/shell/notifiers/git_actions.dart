import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../services/git/git_service.dart';

part 'git_actions.g.dart';

@Riverpod(keepAlive: true)
class GitActions extends _$GitActions {
  @override
  void build() {}

  GitService _git(String projectPath) => ref.read(gitServiceProvider(projectPath));

  Future<void> initGit(String projectPath) => _git(projectPath).initGit();

  Future<String> commit(String projectPath, String message) => _git(projectPath).commit(message);

  Future<String> push(String projectPath) => _git(projectPath).push();

  Future<void> pushToRemote(String projectPath, String remote) => _git(projectPath).pushToRemote(remote);

  /// Sequential push to each remote; returns which succeeded and which failed.
  Future<({List<String> pushed, List<String> failed})> pushAllRemotes(
    String projectPath,
    List<GitRemote> remotes,
  ) async {
    final pushed = <String>[];
    final failed = <String>[];
    for (final remote in remotes) {
      try {
        await _git(projectPath).pushToRemote(remote.name);
        pushed.add(remote.name);
      } on Exception catch (e) {
        dLog('[GitActions] pushToRemote(${remote.name}) failed: ${e.runtimeType}');
        failed.add(remote.name);
      }
    }
    return (pushed: pushed, failed: failed);
  }

  Future<int> pull(String projectPath) => _git(projectPath).pull();

  Future<List<GitRemote>> listRemotes(String projectPath) => _git(projectPath).listRemotes();

  Future<String?> currentBranch(String projectPath) => _git(projectPath).currentBranch();

  Future<String?> getOriginUrl(String projectPath) => _git(projectPath).getOriginUrl();
}
