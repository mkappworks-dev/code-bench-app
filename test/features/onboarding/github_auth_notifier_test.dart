import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/github/repository/github_repository.dart';
import 'package:code_bench_app/data/github/repository/github_repository_impl.dart';
import 'package:code_bench_app/data/models/repository.dart';
import 'package:code_bench_app/features/onboarding/notifiers/github_auth_notifier.dart';

// ── Fake GitHubRepository ────────────────────────────────────────────────────

class _FakeGitHubRepository extends Fake implements GitHubRepository {
  Object? _signOutError;
  Object? _authenticateError;
  GitHubAccount? _authenticateResult;
  GitHubAccount? _storedAccount;

  void throwOnSignOut(Object error) => _signOutError = error;
  void throwOnAuthenticate(Object error) => _authenticateError = error;
  void setAuthenticateResult(GitHubAccount account) => _authenticateResult = account;
  void setStoredAccount(GitHubAccount? account) => _storedAccount = account;

  @override
  Future<GitHubAccount?> getStoredAccount() async => _storedAccount;

  @override
  Future<void> signOut() async {
    if (_signOutError != null) throw _signOutError!;
  }

  @override
  Future<GitHubAccount> authenticate() async {
    if (_authenticateError != null) throw _authenticateError!;
    return _authenticateResult!;
  }

  @override
  Future<GitHubAccount> signInWithPat(String token) async {
    return _authenticateResult!;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

GitHubAccount _fakeAccount() => const GitHubAccount(username: 'testuser', avatarUrl: 'https://example.com/avatar.png');

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _FakeGitHubRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeGitHubRepository();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [githubRepositoryProvider.overrideWith((_) async => fakeRepo)]);
    addTearDown(c.dispose);
    return c;
  }

  group('signOut', () {
    test('surfaces AsyncError when service throws', () async {
      fakeRepo.setStoredAccount(null);
      fakeRepo.throwOnSignOut(Exception('token delete failed'));

      final c = makeContainer();
      // Wait for build() to complete.
      await c.read(gitHubAuthProvider.future);

      await c.read(gitHubAuthProvider.notifier).signOut();

      final result = c.read(gitHubAuthProvider);
      expect(result, isA<AsyncError<GitHubAccount?>>());
      expect(result.error, isA<Exception>());
    });

    test('sets state to AsyncData(null) on success', () async {
      fakeRepo.setStoredAccount(_fakeAccount());

      final c = makeContainer();
      await c.read(gitHubAuthProvider.future);

      await c.read(gitHubAuthProvider.notifier).signOut();

      final result = c.read(gitHubAuthProvider);
      expect(result, isA<AsyncData<GitHubAccount?>>());
      expect(result.value, isNull);
    });
  });

  group('authenticate', () {
    test('failure sets AsyncError state', () async {
      fakeRepo.setStoredAccount(null);
      fakeRepo.throwOnAuthenticate(Exception('oauth failed'));

      final c = makeContainer();
      await c.read(gitHubAuthProvider.future);

      await c.read(gitHubAuthProvider.notifier).authenticate();

      expect(c.read(gitHubAuthProvider), isA<AsyncError<GitHubAccount?>>());
    });

    test('success sets AsyncData with account', () async {
      fakeRepo.setStoredAccount(null);
      fakeRepo.setAuthenticateResult(_fakeAccount());

      final c = makeContainer();
      await c.read(gitHubAuthProvider.future);

      await c.read(gitHubAuthProvider.notifier).authenticate();

      final result = c.read(gitHubAuthProvider);
      expect(result, isA<AsyncData<GitHubAccount?>>());
      expect(result.value?.username, equals('testuser'));
    });
  });
}
