import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../services/git/git_service.dart';
import 'git_actions_failure.dart';

part 'git_actions.g.dart';

@Riverpod(keepAlive: true)
class GitActions extends _$GitActions {
  @override
  FutureOr<void> build() {}

  GitService _git() => ref.read(gitServiceProvider);

  GitActionsFailure _asFailure(Object e) => switch (e) {
    GitNoUpstreamException(:final message) => GitActionsFailure.noUpstream(message),
    GitAuthException() => const GitActionsFailure.authFailed(),
    GitConflictException() => const GitActionsFailure.conflict(),
    GitException(:final message) => GitActionsFailure.gitError(message),
    _ => GitActionsFailure.unknown(e),
  };

  Future<void> initGit(String projectPath) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await _git().initGit(projectPath);
      } catch (e, st) {
        dLog('[GitActions] initGit failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<String> commit(String projectPath, String message) async {
    state = const AsyncLoading();
    String? sha;
    state = await AsyncValue.guard(() async {
      try {
        sha = await _git().commit(projectPath, message);
      } catch (e, st) {
        dLog('[GitActions] commit failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return sha ?? '';
  }

  Future<String> push(String projectPath) async {
    state = const AsyncLoading();
    String? branch;
    state = await AsyncValue.guard(() async {
      try {
        branch = await _git().push(projectPath);
      } catch (e, st) {
        dLog('[GitActions] push failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return branch ?? '';
  }

  Future<void> pushToRemote(String projectPath, String remote) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await _git().pushToRemote(projectPath, remote);
      } catch (e, st) {
        dLog('[GitActions] pushToRemote($remote) failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  // Individual remote failures are swallowed — state stays AsyncData so the caller can inspect pushed/failed.
  Future<({List<String> pushed, List<String> failed})> pushAllRemotes(
    String projectPath,
    List<GitRemote> remotes,
  ) async {
    state = const AsyncLoading();
    final pushed = <String>[];
    final failed = <String>[];
    state = await AsyncValue.guard(() async {
      for (final remote in remotes) {
        try {
          await _git().pushToRemote(projectPath, remote.name);
          pushed.add(remote.name);
        } on Exception catch (e) {
          dLog('[GitActions] pushToRemote(${remote.name}) failed: ${e.runtimeType}');
          failed.add(remote.name);
        }
      }
    });
    return (pushed: pushed, failed: failed);
  }

  Future<int> pull(String projectPath) async {
    state = const AsyncLoading();
    int? count;
    state = await AsyncValue.guard(() async {
      try {
        count = await _git().pull(projectPath);
      } catch (e, st) {
        dLog('[GitActions] pull failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return count ?? 0;
  }

  Future<List<GitRemote>> listRemotes(String projectPath) async {
    state = const AsyncLoading();
    List<GitRemote>? remotes;
    state = await AsyncValue.guard(() async {
      try {
        remotes = await _git().listRemotes(projectPath);
      } catch (e, st) {
        dLog('[GitActions] listRemotes failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return remotes ?? [];
  }

  Future<String?> currentBranch(String projectPath) async {
    try {
      return await _git().currentBranch(projectPath);
    } catch (e) {
      dLog('[GitActions] currentBranch failed: ${e.runtimeType}');
      return null;
    }
  }

  Future<String?> getOriginUrl(String projectPath) async {
    try {
      return await _git().getOriginUrl(projectPath);
    } catch (e) {
      dLog('[GitActions] getOriginUrl failed: ${e.runtimeType}');
      return null;
    }
  }

  bool isGitRepo(String path) => _git().isGitRepo(path);

  Future<List<GitChangedFile>> fetchChangedFiles(String projectPath) async {
    try {
      return await _git().getChangedFiles(projectPath);
    } catch (e) {
      dLog('[GitActions] fetchChangedFiles failed: $e');
      return [];
    }
  }

  Future<List<String>> getBranchChangedFiles(String projectPath) async {
    try {
      return await _git().getBranchChangedFiles(projectPath);
    } catch (e) {
      dLog('[GitActions] getBranchChangedFiles failed: $e');
      return [];
    }
  }
}
