import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/github/models/device_code_response.dart';
import 'package:code_bench_app/data/github/models/repository.dart';
import 'package:code_bench_app/data/github/repository/github_repository.dart';
import 'package:code_bench_app/data/github/repository/github_repository_impl.dart';
import 'package:code_bench_app/features/github/notifiers/github_auth_failure.dart';
import 'package:code_bench_app/features/github/notifiers/github_auth_notifier.dart';

// ── Fake GitHubRepository ────────────────────────────────────────────────────

class _FakeGitHubRepository extends Fake implements GitHubRepository {
  Object? _signOutError;
  Object? _pollError;
  Object? _requestDeviceCodeError;
  GitHubAccount? _pollResult;
  GitHubAccount? _storedAccount;
  // Background validateStoredToken behaviour: if [_validateError] is set
  // it rethrows; otherwise returns [_validateResult]. Tracked separately
  // so a transient validation failure doesn't change the cached account.
  Object? _validateError;
  bool _validateResult = true;
  int signOutCalls = 0;
  int validateCalls = 0;
  DeviceCodeResponse _deviceCode = const DeviceCodeResponse(
    userCode: 'WDJB-MJHT',
    verificationUri: 'https://github.com/login/device',
    deviceCode: 'dev-xyz',
    interval: 0,
    expiresIn: 900,
  );

  void throwOnSignOut(Object error) => _signOutError = error;
  void throwOnPoll(Object error) => _pollError = error;
  void throwOnRequestDeviceCode(Object error) => _requestDeviceCodeError = error;
  void setPollResult(GitHubAccount account) => _pollResult = account;
  void setStoredAccount(GitHubAccount? account) => _storedAccount = account;
  void setDeviceCode(DeviceCodeResponse code) => _deviceCode = code;
  void setValidateResult(bool result) => _validateResult = result;
  void throwOnValidateStoredToken(Object error) => _validateError = error;

  @override
  Future<GitHubAccount?> getStoredAccount() async => _storedAccount;

  @override
  Future<bool> validateStoredToken() async {
    validateCalls++;
    if (_validateError != null) throw _validateError!;
    return _validateResult;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (_signOutError != null) throw _signOutError!;
  }

  @override
  Future<DeviceCodeResponse> requestDeviceCode() async {
    if (_requestDeviceCodeError != null) throw _requestDeviceCodeError!;
    return _deviceCode;
  }

  @override
  Future<GitHubAccount?> pollForUserToken(
    String deviceCode,
    int intervalSeconds,
    int expiresIn, {
    Future<void>? cancelSignal,
  }) async {
    if (_pollError != null) throw _pollError!;
    if (cancelSignal == null) return _pollResult;

    // Honor cancellation: whichever future completes first wins. If a poll
    // result is configured we resolve it on a microtask so callers can race
    // cancel against it.
    final completer = Completer<GitHubAccount?>();
    cancelSignal.then((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    if (_pollResult != null) {
      Future<void>.microtask(() {
        if (!completer.isCompleted) completer.complete(_pollResult);
      });
    }
    return completer.future;
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
      // Cancel pending poll to avoid touching the provider after teardown.
      c.read(gitHubAuthProvider.notifier).cancelDeviceFlow();
      await Future<void>.delayed(Duration.zero);

      expect(code, isNotNull);
      expect(code!.userCode, 'WDJB-MJHT');
    });

    test('returns null and sets AsyncError when requestDeviceCode throws', () async {
      fakeRepo.setStoredAccount(null);
      fakeRepo.throwOnRequestDeviceCode(Exception('network down'));

      final c = makeContainer();
      await c.read(gitHubAuthProvider.future);

      final code = await c.read(gitHubAuthProvider.notifier).startDeviceFlow();

      expect(code, isNull);
      final result = c.read(gitHubAuthProvider);
      expect(result, isA<AsyncError<GitHubAccount?>>());
      expect(result.error, isA<GitHubAuthRequestFailed>());
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

  group('build — background token validation', () {
    test('keeps cached account when validateStoredToken returns true', () async {
      final existing = _fakeAccount();
      fakeRepo.setStoredAccount(existing);
      fakeRepo.setValidateResult(true);

      final c = makeContainer();
      final initial = await c.read(gitHubAuthProvider.future);
      expect(initial, equals(existing));
      // Yield so the background validation completes.
      await Future<void>.delayed(Duration.zero);

      expect(fakeRepo.validateCalls, 1);
      expect(fakeRepo.signOutCalls, 0);
      final result = c.read(gitHubAuthProvider);
      expect(result, isA<AsyncData<GitHubAccount?>>());
      expect(result.value, equals(existing));
    });

    test('signs out when validateStoredToken returns false', () async {
      fakeRepo.setStoredAccount(_fakeAccount());
      fakeRepo.setValidateResult(false);

      final c = makeContainer();
      final initial = await c.read(gitHubAuthProvider.future);
      expect(initial, isNotNull);
      // Yield so background validation runs and signOut completes.
      await Future<void>.delayed(Duration.zero);

      expect(fakeRepo.validateCalls, 1);
      expect(fakeRepo.signOutCalls, 1);
      final result = c.read(gitHubAuthProvider);
      expect(result, isA<AsyncError<GitHubAccount?>>());
      expect(result.error, isA<GitHubAuthTokenRevoked>());
    });

    test('leaves cached account intact when validateStoredToken throws (transient)', () async {
      final existing = _fakeAccount();
      fakeRepo.setStoredAccount(existing);
      fakeRepo.throwOnValidateStoredToken(Exception('network down'));

      final c = makeContainer();
      final initial = await c.read(gitHubAuthProvider.future);
      expect(initial, equals(existing));
      await Future<void>.delayed(Duration.zero);

      expect(fakeRepo.validateCalls, 1);
      expect(fakeRepo.signOutCalls, 0);
      final result = c.read(gitHubAuthProvider);
      expect(result, isA<AsyncData<GitHubAccount?>>());
      expect(result.value, equals(existing));
    });

    test('does not validate when no stored account', () async {
      fakeRepo.setStoredAccount(null);

      final c = makeContainer();
      await c.read(gitHubAuthProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(fakeRepo.validateCalls, 0);
    });
  });

  group('cancelDeviceFlow', () {
    test('collapses AsyncLoading to AsyncData(null) and unblocks the poller', () async {
      // Intentionally do NOT seed a poll result — the fake's pollForUserToken
      // will only resolve when cancelSignal fires, so this test would hang
      // forever if cancellation logic were removed from the notifier.
      fakeRepo.setStoredAccount(null);

      final c = makeContainer();
      await c.read(gitHubAuthProvider.future);

      await c.read(gitHubAuthProvider.notifier).startDeviceFlow();
      c.read(gitHubAuthProvider.notifier).cancelDeviceFlow();

      // Yield so the awaiting poller can observe the cancel signal and
      // return without overwriting the state set by cancelDeviceFlow.
      await Future<void>.delayed(Duration.zero);

      final result = c.read(gitHubAuthProvider);
      expect(result, isA<AsyncData<GitHubAccount?>>());
      expect(result.value, isNull);
    });

    test('preserves a pre-existing signed-in account when cancelling re-auth', () async {
      // User is already signed in and triggers a re-auth via device flow,
      // then cancels. The cancel must NOT clobber the existing account —
      // that would falsely sign the user out client-side.
      final existingAccount = _fakeAccount();
      fakeRepo.setStoredAccount(existingAccount);

      final c = makeContainer();
      // Wait for build() to load the stored account.
      await c.read(gitHubAuthProvider.future);
      expect(c.read(gitHubAuthProvider).value, equals(existingAccount));

      await c.read(gitHubAuthProvider.notifier).startDeviceFlow();
      // startDeviceFlow set state to AsyncLoading(value: existingAccount).
      c.read(gitHubAuthProvider.notifier).cancelDeviceFlow();
      await Future<void>.delayed(Duration.zero);

      final result = c.read(gitHubAuthProvider);
      expect(result, isA<AsyncData<GitHubAccount?>>());
      expect(result.value, equals(existingAccount));
    });
  });
}
