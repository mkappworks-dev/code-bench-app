import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/core/errors/app_exception.dart';
import 'package:code_bench_app/data/github/repository/github_repository.dart';
import 'package:code_bench_app/data/github/repository/github_repository_impl.dart';
import 'package:code_bench_app/features/chat/notifiers/pr_notifier.dart';

// ── Fake GitHubRepository ─────────────────────────────────────────────────────

class _FakeGitHubRepository extends Fake implements GitHubRepository {
  Object? _approveError;
  Object? _mergeError;

  void throwOnApprove(Object error) => _approveError = error;
  void throwOnMerge(Object error) => _mergeError = error;

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<void> approvePullRequest(String owner, String repo, int prNumber) async {
    if (_approveError != null) throw _approveError!;
  }

  @override
  Future<void> mergePullRequest(String owner, String repo, int prNumber) async {
    if (_mergeError != null) throw _mergeError!;
  }

  @override
  Future<Map<String, dynamic>> getPullRequest(String owner, String repo, int prNumber) async {
    return {
      'number': prNumber,
      'title': 'Test PR',
      'merged': false,
      'merged_at': null,
      'head': {'sha': 'abc123'},
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getCheckRuns(String owner, String repo, String sha) async {
    return [];
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer(_FakeGitHubRepository fakeRepo) {
  final c = ProviderContainer(overrides: [githubRepositoryProvider.overrideWith((_) async => fakeRepo)]);
  addTearDown(c.dispose);
  return c;
}

const _owner = 'acme';
const _repo = 'widgets';
const _prNumber = 42;

void main() {
  late _FakeGitHubRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeGitHubRepository();
  });

  // ── approve() ───────────────────────────────────────────────────────────────

  group('approve()', () {
    test('happy path — approved is true, actionError is null', () async {
      final c = _makeContainer(fakeRepo);
      // Initialise the notifier.
      await c.read(prCardProvider(_owner, _repo, _prNumber).future);

      await c.read(prCardProvider(_owner, _repo, _prNumber).notifier).approve();

      final s = c.read(prCardProvider(_owner, _repo, _prNumber));
      expect(s, isA<AsyncData<PrCardState>>());
      expect(s.value!.approved, isTrue);
      expect(s.value!.actionError, isNull);
    });

    test('failure — state stays AsyncData, actionError is non-null', () async {
      fakeRepo.throwOnApprove(const NetworkException('Forbidden', statusCode: 403));

      final c = _makeContainer(fakeRepo);
      await c.read(prCardProvider(_owner, _repo, _prNumber).future);

      await c.read(prCardProvider(_owner, _repo, _prNumber).notifier).approve();

      final s = c.read(prCardProvider(_owner, _repo, _prNumber));
      expect(s, isA<AsyncData<PrCardState>>());
      expect(s.value!.actionError, isNotNull);
    });
  });

  // ── merge() ─────────────────────────────────────────────────────────────────

  group('merge()', () {
    test('failure — state stays AsyncData, actionError is non-null', () async {
      fakeRepo.throwOnMerge(const NetworkException('Conflict', statusCode: 409));

      final c = _makeContainer(fakeRepo);
      await c.read(prCardProvider(_owner, _repo, _prNumber).future);

      await c.read(prCardProvider(_owner, _repo, _prNumber).notifier).merge();

      final s = c.read(prCardProvider(_owner, _repo, _prNumber));
      expect(s, isA<AsyncData<PrCardState>>());
      expect(s.value!.actionError, isNotNull);
    });
  });
}
