import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/github/models/device_code_response.dart';
import 'package:code_bench_app/data/github/repository/github_repository.dart';
import 'package:code_bench_app/data/github/repository/github_repository_impl.dart';
import 'package:code_bench_app/data/github/models/repository.dart';
import 'package:code_bench_app/features/onboarding/notifiers/github_auth_notifier.dart';

// ── Fake GitHubRepository ────────────────────────────────────────────────────

class _FakeGitHubRepository extends Fake implements GitHubRepository {
  Object? _signOutError;
  Object? _pollError;
  GitHubAccount? _pollResult;
  GitHubAccount? _storedAccount;
  DeviceCodeResponse _deviceCode = const DeviceCodeResponse(
    userCode: 'WDJB-MJHT',
    verificationUri: 'https://github.com/login/device',
    deviceCode: 'dev-xyz',
    interval: 0,
    expiresIn: 900,
  );

  void throwOnSignOut(Object error) => _signOutError = error;
  void throwOnPoll(Object error) => _pollError = error;
  void setPollResult(GitHubAccount account) => _pollResult = account;
  void setStoredAccount(GitHubAccount? account) => _storedAccount = account;
  void setDeviceCode(DeviceCodeResponse code) => _deviceCode = code;

  @override
  Future<GitHubAccount?> getStoredAccount() async => _storedAccount;

  @override
  Future<void> signOut() async {
    if (_signOutError != null) throw _signOutError!;
  }

  @override
  Future<DeviceCodeResponse> requestDeviceCode() async => _deviceCode;

  @override
  Future<GitHubAccount?> pollForUserToken(String deviceCode, int intervalSeconds, {Future<void>? cancelSignal}) async {
    if (_pollError != null) throw _pollError!;
    return _pollResult;
  }

  @override
  Future<GitHubAccount> signInWithPat(String token) async {
    return _pollResult!;
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

  group('startDeviceFlow', () {
    test('returns the device code from the service', () async {
      fakeRepo.setStoredAccount(null);
      fakeRepo.setPollResult(_fakeAccount());

      final c = makeContainer();
      await c.read(gitHubAuthProvider.future);

      final code = await c.read(gitHubAuthProvider.notifier).startDeviceFlow();

      expect(code.userCode, 'WDJB-MJHT');
    });

    test('background polling sets AsyncData with account on success', () async {
      fakeRepo.setStoredAccount(null);
      fakeRepo.setPollResult(_fakeAccount());

      final c = makeContainer();
      await c.read(gitHubAuthProvider.future);

      await c.read(gitHubAuthProvider.notifier).startDeviceFlow();
      // Yield to let the background poll Future complete.
      await Future<void>.delayed(Duration.zero);

      final result = c.read(gitHubAuthProvider);
      expect(result, isA<AsyncData<GitHubAccount?>>());
      expect(result.value?.username, equals('testuser'));
    });

    test('background polling failure sets AsyncError state', () async {
      fakeRepo.setStoredAccount(null);
      fakeRepo.throwOnPoll(Exception('device flow failed'));

      final c = makeContainer();
      await c.read(gitHubAuthProvider.future);

      await c.read(gitHubAuthProvider.notifier).startDeviceFlow();
      await Future<void>.delayed(Duration.zero);

      expect(c.read(gitHubAuthProvider), isA<AsyncError<GitHubAccount?>>());
    });
  });

  group('cancelDeviceFlow', () {
    test('sets state to AsyncData(null)', () async {
      fakeRepo.setStoredAccount(null);
      fakeRepo.setPollResult(_fakeAccount());

      final c = makeContainer();
      await c.read(gitHubAuthProvider.future);

      await c.read(gitHubAuthProvider.notifier).startDeviceFlow();
      c.read(gitHubAuthProvider.notifier).cancelDeviceFlow();

      final result = c.read(gitHubAuthProvider);
      expect(result, isA<AsyncData<GitHubAccount?>>());
      expect(result.value, isNull);
    });
  });
}
