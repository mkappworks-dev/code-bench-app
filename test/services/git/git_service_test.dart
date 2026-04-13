import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/git/datasource/git_datasource_process.dart';
import 'package:code_bench_app/data/git/datasource/git_live_state_datasource.dart';
import 'package:code_bench_app/data/git/models/git_live_state.dart';
import 'package:code_bench_app/data/git/repository/git_repository.dart';
import 'package:code_bench_app/services/git/git_service.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class FakeGitRepository implements GitRepository {
  bool _isGit = false;
  String? _branch;
  String? _originUrl;

  void setIsGit(bool v) => _isGit = v;
  void setBranch(String? v) => _branch = v;
  void setOriginUrl(String? v) => _originUrl = v;

  @override
  bool isGitRepo(String projectPath) => _isGit;

  @override
  Future<String?> currentBranch(String projectPath) async => _branch;

  @override
  Future<String?> getOriginUrl(String projectPath) async => _originUrl;

  @override
  Future<void> initGit(String projectPath) async {}
}

class FakeGitLiveStateDatasource implements GitLiveStateDatasource {
  GitLiveState _state = GitLiveState.notGit;
  int? _behindCount;
  bool _isGit = false;

  void setState(GitLiveState s) => _state = s;
  void setBehindCount(int? v) => _behindCount = v;
  void setIsGit(bool v) => _isGit = v;

  @override
  Future<GitLiveState> fetchLiveState(String projectPath) async => _state;

  @override
  Future<int?> fetchBehindCount(String projectPath) async => _behindCount;

  @override
  bool isGitRepo(String projectPath) => _isGit;
}

// ── GitService unit tests ─────────────────────────────────────────────────────

void main() {
  group('GitService', () {
    late FakeGitRepository fakeRepo;
    late FakeGitLiveStateDatasource fakeLiveState;
    late GitService svc;

    setUp(() {
      fakeRepo = FakeGitRepository();
      fakeLiveState = FakeGitLiveStateDatasource();
      svc = GitService(repo: fakeRepo, liveState: fakeLiveState);
    });

    group('primitives delegate to GitRepository', () {
      test('isGitRepo returns value from repository', () {
        fakeRepo.setIsGit(true);
        expect(svc.isGitRepo('/some/path'), isTrue);
      });

      test('currentBranch returns value from repository', () async {
        fakeRepo.setBranch('main');
        expect(await svc.currentBranch('/some/path'), 'main');
      });

      test('getOriginUrl returns value from repository', () async {
        fakeRepo.setOriginUrl('https://github.com/owner/repo.git');
        expect(await svc.getOriginUrl('/some/path'), 'https://github.com/owner/repo.git');
      });
    });

    group('fetchLiveState', () {
      test('delegates to injected liveState datasource', () async {
        final expected = const GitLiveState(
          isGit: true,
          branch: 'main',
          hasUncommitted: false,
          aheadCount: 0,
          isOnDefaultBranch: true,
        );
        fakeLiveState.setState(expected);

        final result = await svc.fetchLiveState('/some/path');
        expect(result.isGit, isTrue);
        expect(result.branch, 'main');
        expect(result.isOnDefaultBranch, isTrue);
      });
    });

    group('behindCount', () {
      test('delegates to injected liveState datasource', () async {
        fakeLiveState.setBehindCount(3);

        final result = await svc.behindCount('/some/path');
        expect(result, 3);
      });

      test('returns null when datasource returns null (no upstream)', () async {
        fakeLiveState.setBehindCount(null);

        final result = await svc.behindCount('/some/path');
        expect(result, isNull);
      });
    });

    group('liveState null fallback', () {
      test('assert fires in debug mode when liveState is not injected', () {
        final svcNoLiveState = GitService(repo: fakeRepo);
        // In debug mode, assert fires and throws AssertionError.
        // In release mode the fallback constructs a real GitLiveStateDatasourceProcess.
        expect(
          () => svcNoLiveState.fetchLiveState('/some/path'),
          // AssertionError in debug builds; no throw in release builds.
          // We only verify behavior in test (debug) mode here.
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });

  // ── GitDatasourceProcess integration tests ────────────────────────────────
  // These exercise the datasource layer directly with real git processes.

  group('GitDatasourceProcess', () {
    late Directory tempDir;

    Future<void> configureIdentity(String path) async {
      await Process.run('git', ['config', 'user.email', 'test@test.com'], workingDirectory: path);
      await Process.run('git', ['config', 'user.name', 'Test'], workingDirectory: path);
    }

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('git_service_test_');
      await Process.run('git', ['init'], workingDirectory: tempDir.path);
      await configureIdentity(tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('initGit creates .git directory', () async {
      final dir = await Directory.systemTemp.createTemp('git_init_test_');
      addTearDown(() => dir.delete(recursive: true));
      final ds = GitDatasourceProcess(dir.path);
      await ds.initGit();
      expect(Directory('${dir.path}/.git').existsSync(), isTrue);
    });

    test('commit stages and commits a file (root commit path)', () async {
      File('${tempDir.path}/hello.txt').writeAsStringSync('hi');
      final ds = GitDatasourceProcess(tempDir.path);
      final sha = await ds.commit('test: initial commit');
      expect(sha, isNotEmpty);
      expect(sha.length, greaterThanOrEqualTo(7));
    });

    test('commit parses SHA on a feature branch containing `-`', () async {
      File('${tempDir.path}/one.txt').writeAsStringSync('one');
      final ds = GitDatasourceProcess(tempDir.path);
      await ds.commit('feat: initial');
      await Process.run('git', ['checkout', '-b', 'feat/2026-04-10-foo'], workingDirectory: tempDir.path);
      File('${tempDir.path}/two.txt').writeAsStringSync('two');
      final sha = await ds.commit('feat: second commit');
      expect(sha, isNotEmpty);
      expect(sha, matches(RegExp(r'^[a-f0-9]+$')));
    });

    test('fetchBehindCount returns null when no upstream is configured', () async {
      final ds = GitDatasourceProcess(tempDir.path);
      final count = await ds.fetchBehindCount();
      expect(count, isNull);
    });

    test('currentBranch returns null outside a git repo', () async {
      final dir = await Directory.systemTemp.createTemp('no_git_');
      addTearDown(() => dir.delete(recursive: true));
      final ds = GitDatasourceProcess(dir.path);
      expect(await ds.currentBranch(), isNull);
    });

    test('getOriginUrl returns null when no origin is configured', () async {
      final ds = GitDatasourceProcess(tempDir.path);
      expect(await ds.getOriginUrl(), isNull);
    });

    test('listRemotes returns empty list when no remotes configured', () async {
      final ds = GitDatasourceProcess(tempDir.path);
      final remotes = await ds.listRemotes();
      expect(remotes, isEmpty);
    });

    test('pushToRemote rejects a remote name that looks like a flag', () async {
      final ds = GitDatasourceProcess(tempDir.path);
      expect(() => ds.pushToRemote('-d'), throwsA(isA<GitException>()));
    });
  });
}
