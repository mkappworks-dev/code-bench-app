import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/git/git_live_state.dart';
import 'package:code_bench_app/data/git/repository/git_repository.dart';
import 'package:code_bench_app/data/git/repository/git_repository_impl.dart';
import 'package:code_bench_app/shell/notifiers/git_actions.dart';
import 'package:code_bench_app/shell/notifiers/git_actions_failure.dart';

// ── Fake GitRepository ─────────────────────────────────────────────────────────

class _FakeGitRepository extends Fake implements GitRepository {
  Object? _commitError;
  final String _commitSha = 'abc1234';

  Object? _pushError;
  final String _pushBranch = 'main';

  Object? _pullError;
  final int _pullCount = 3;

  void throwOnCommit(Object error) => _commitError = error;
  void throwOnPush(Object error) => _pushError = error;
  void throwOnPull(Object error) => _pullError = error;

  @override
  Future<String> commit(String projectPath, String message) async {
    if (_commitError != null) throw _commitError!;
    return _commitSha;
  }

  @override
  Future<String> push(String projectPath) async {
    if (_pushError != null) throw _pushError!;
    return _pushBranch;
  }

  @override
  Future<int> pull(String projectPath) async {
    if (_pullError != null) throw _pullError!;
    return _pullCount;
  }

  @override
  Future<void> initGit(String projectPath) async {}

  @override
  Future<void> pushToRemote(String projectPath, String remote) async {}

  @override
  Future<List<GitRemote>> listRemotes(String projectPath) async => [];

  @override
  Future<String?> currentBranch(String projectPath) async => 'main';

  @override
  Future<String?> getOriginUrl(String projectPath) async => null;

  @override
  Future<int?> fetchBehindCount(String projectPath) async => null;

  @override
  Future<List<String>> listLocalBranches(String projectPath) async => [];

  @override
  Future<Set<String>> worktreeBranches(String projectPath) async => {};

  @override
  Future<void> checkout(String projectPath, String branch) async {}

  @override
  Future<void> createBranch(String projectPath, String name) async {}

  @override
  Future<GitLiveState> fetchLiveState(String projectPath) async => GitLiveState.notGit;

  @override
  Future<int?> behindCount(String projectPath) async => null;

  @override
  bool isGitRepo(String projectPath) => false;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _kPath = '/fake/project';

void main() {
  late _FakeGitRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeGitRepository();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [gitRepositoryProvider.overrideWithValue(fakeRepo)]);
    addTearDown(c.dispose);
    return c;
  }

  // ── commit ─────────────────────────────────────────────────────────────────

  group('commit', () {
    test('happy path — returns sha and state becomes AsyncData', () async {
      final c = makeContainer();
      final sha = await c.read(gitActionsProvider.notifier).commit(_kPath, 'init');
      expect(sha, equals('abc1234'));
      expect(c.read(gitActionsProvider), isA<AsyncData<void>>());
    });

    test('GitException → GitActionsGitError', () async {
      fakeRepo.throwOnCommit(const GitException('git commit failed'));

      final c = makeContainer();
      await c.read(gitActionsProvider.notifier).commit(_kPath, 'init');
      expect(c.read(gitActionsProvider).error, isA<GitActionsGitError>());
    });

    test('unknown exception → GitActionsUnknownError', () async {
      fakeRepo.throwOnCommit(Exception('unexpected'));

      final c = makeContainer();
      await c.read(gitActionsProvider.notifier).commit(_kPath, 'init');
      expect(c.read(gitActionsProvider).error, isA<GitActionsUnknownError>());
    });
  });

  // ── push ───────────────────────────────────────────────────────────────────

  group('push', () {
    test('happy path — returns branch and state becomes AsyncData', () async {
      final c = makeContainer();
      final branch = await c.read(gitActionsProvider.notifier).push(_kPath);
      expect(branch, equals('main'));
      expect(c.read(gitActionsProvider), isA<AsyncData<void>>());
    });

    test('GitNoUpstreamException → GitActionsNoUpstream', () async {
      fakeRepo.throwOnPush(const GitNoUpstreamException('main'));

      final c = makeContainer();
      await c.read(gitActionsProvider.notifier).push(_kPath);
      expect(c.read(gitActionsProvider).error, isA<GitActionsNoUpstream>());
    });

    test('GitAuthException → GitActionsAuthFailed', () async {
      fakeRepo.throwOnPush(const GitAuthException());

      final c = makeContainer();
      await c.read(gitActionsProvider.notifier).push(_kPath);
      expect(c.read(gitActionsProvider).error, isA<GitActionsAuthFailed>());
    });

    test('GitException → GitActionsGitError', () async {
      fakeRepo.throwOnPush(const GitException('remote rejected'));

      final c = makeContainer();
      await c.read(gitActionsProvider.notifier).push(_kPath);
      expect(c.read(gitActionsProvider).error, isA<GitActionsGitError>());
    });
  });

  // ── pull ───────────────────────────────────────────────────────────────────

  group('pull', () {
    test('happy path — returns commit count and state becomes AsyncData', () async {
      final c = makeContainer();
      final count = await c.read(gitActionsProvider.notifier).pull(_kPath);
      expect(count, equals(3));
      expect(c.read(gitActionsProvider), isA<AsyncData<void>>());
    });

    test('GitConflictException → GitActionsConflict', () async {
      fakeRepo.throwOnPull(const GitConflictException());

      final c = makeContainer();
      await c.read(gitActionsProvider.notifier).pull(_kPath);
      expect(c.read(gitActionsProvider).error, isA<GitActionsConflict>());
    });

    test('GitNoUpstreamException → GitActionsNoUpstream', () async {
      fakeRepo.throwOnPull(const GitNoUpstreamException(''));

      final c = makeContainer();
      await c.read(gitActionsProvider.notifier).pull(_kPath);
      expect(c.read(gitActionsProvider).error, isA<GitActionsNoUpstream>());
    });
  });
}
