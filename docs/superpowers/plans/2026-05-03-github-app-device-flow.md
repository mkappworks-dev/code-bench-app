# GitHub App + Device Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing PKCE/web-flow GitHub auth with GitHub Device Flow on the `Benchlabs Codebench` GitHub App, eliminating the need for any embedded `client_secret`.

**Architecture:** A new `AppDialog`-based dialog displays an 8-character code received from `https://github.com/login/device/code`. The notifier polls `https://github.com/login/oauth/access_token` in the background until the user authorizes via browser. Token is non-expiring, stored in `SecureStorage`. The PAT fallback (`signInWithPat`) and the PKCE infrastructure files (`env.json`, `.vscode/launch.json`) stay; only the auth flow itself changes.

**Tech Stack:** Flutter/Dart, Dio, Riverpod, freezed, `flutter_secure_storage`, `url_launcher`, `package:flutter/services.dart` (Clipboard).

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Delete | `test/data/github/datasource/github_auth_datasource_pkce_test.dart` | PKCE removed |
| Modify | `lib/data/github/datasource/github_auth_datasource_web_dio.dart` | Replace `authenticate()` with `requestDeviceCode()` + `pollForUserToken()`; remove PKCE math; refactor to hold `Dio` fields for testing |
| Modify | `lib/data/github/datasource/github_auth_datasource.dart` | Update interface |
| Create | `lib/data/github/models/device_code_response.dart` | Freezed model for `/login/device/code` response |
| Modify | `lib/data/github/repository/github_repository.dart` | Update interface |
| Modify | `lib/data/github/repository/github_repository_impl.dart` | Update implementation |
| Modify | `lib/services/github/github_service.dart` | Update service delegation |
| Modify | `lib/features/onboarding/notifiers/github_auth_notifier.dart` | Replace `authenticate()` with `startDeviceFlow()` + `cancelDeviceFlow()` |
| Create | `lib/features/onboarding/widgets/github_device_flow_dialog.dart` | New dialog widget |
| Modify | `lib/features/onboarding/widgets/github_step.dart` | Update callsite |
| Modify | `lib/features/integrations/integrations_screen.dart` | Update callsite |
| Create | `test/data/github/datasource/github_auth_datasource_device_flow_test.dart` | Tests for new methods |

---

## Task 1: Pre-cleanup (PKCE artifacts)

**Files:**
- Delete: `test/data/github/datasource/github_auth_datasource_pkce_test.dart`
- Modify: `lib/data/github/datasource/github_auth_datasource_web_dio.dart`

- [ ] **Step 1: Delete the PKCE test file**

```bash
rm test/data/github/datasource/github_auth_datasource_pkce_test.dart
```

- [ ] **Step 2: Remove the temporary diagnostic `dLog` and PKCE-related code from `github_auth_datasource_web_dio.dart`**

Open the file. Remove **all** of these lines/blocks:

1. The temporary diagnostic log (added during debugging):
```dart
dLog('[GitHubAuthDatasource] token exchange full response: $data');
```

2. The `generatePkce()` method (entire block):
```dart
@visibleForTesting
({String verifier, String challenge}) generatePkce() {
  final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
  final verifier = base64UrlEncode(bytes).replaceAll('=', '');
  final challenge = base64UrlEncode(
    sha256.convert(utf8.encode(verifier)).bytes,
  ).replaceAll('=', '');
  return (verifier: verifier, challenge: challenge);
}
```

3. These imports (no longer needed after PKCE math removal):
```dart
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
```

Leave the rest of the file alone — it still has the broken `authenticate()` and `_exchangeCodeForToken()` methods. We'll replace those in Task 4.

- [ ] **Step 3: Verify analyzer passes**

```bash
flutter analyze
```

Expected: no issues (some unused-method warnings on `authenticate()` are OK; we'll replace it in Task 4).

- [ ] **Step 4: Commit**

```bash
git add test/data/github/datasource/github_auth_datasource_pkce_test.dart \
        lib/data/github/datasource/github_auth_datasource_web_dio.dart
git commit -m "chore: remove PKCE artifacts ahead of device-flow migration"
```

---

## Task 2: Create `DeviceCodeResponse` model

**Files:**
- Create: `lib/data/github/models/device_code_response.dart`

- [ ] **Step 1: Create the freezed model file**

Create `lib/data/github/models/device_code_response.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_code_response.freezed.dart';
part 'device_code_response.g.dart';

/// Response from `POST https://github.com/login/device/code`.
///
/// `userCode` — 8-character code (e.g. `WDJB-MJHT`) the user types at
/// `verificationUri`. `deviceCode` is the opaque code the app uses when
/// polling `/login/oauth/access_token`. `interval` is the minimum
/// poll-frequency in seconds GitHub asks us to respect.
@freezed
class DeviceCodeResponse with _$DeviceCodeResponse {
  const factory DeviceCodeResponse({
    @JsonKey(name: 'user_code') required String userCode,
    @JsonKey(name: 'verification_uri') required String verificationUri,
    @JsonKey(name: 'device_code') required String deviceCode,
    required int interval,
    @JsonKey(name: 'expires_in') required int expiresIn,
  }) = _DeviceCodeResponse;

  factory DeviceCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceCodeResponseFromJson(json);
}
```

- [ ] **Step 2: Run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: two new generated files appear next to the model:
- `lib/data/github/models/device_code_response.freezed.dart`
- `lib/data/github/models/device_code_response.g.dart`

- [ ] **Step 3: Verify analyzer passes**

```bash
flutter analyze lib/data/github/models/
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/data/github/models/device_code_response.dart \
        lib/data/github/models/device_code_response.freezed.dart \
        lib/data/github/models/device_code_response.g.dart
git commit -m "feat(github): add DeviceCodeResponse model"
```

---

## Task 3: Update `GitHubAuthDatasource` interface

**Files:**
- Modify: `lib/data/github/datasource/github_auth_datasource.dart`

- [ ] **Step 1: Replace the interface contents**

Replace the entire file with:

```dart
import '../models/device_code_response.dart';
import '../models/repository.dart';

abstract interface class GitHubAuthDatasource {
  /// Initiates the GitHub Device Flow. Returns the device code metadata
  /// the caller must display to the user.
  Future<DeviceCodeResponse> requestDeviceCode();

  /// Polls GitHub's token endpoint until the user authorizes the device
  /// (returns [GitHubAccount]) or the flow fails (throws [AuthException]).
  /// Returns `null` if the [cancelSignal] completes before authorization.
  ///
  /// `intervalSeconds` is the initial poll interval; `slow_down` responses
  /// from GitHub increase it.
  Future<GitHubAccount?> pollForUserToken(
    String deviceCode,
    int intervalSeconds, {
    Future<void>? cancelSignal,
  });

  Future<GitHubAccount> signInWithPat(String token);

  Future<GitHubAccount?> getStoredAccount();

  Future<bool> isAuthenticated();

  Future<void> signOut();
}
```

> The previous `authenticate()` method is gone. `signInWithPat`, `getStoredAccount`, `isAuthenticated`, `signOut` are unchanged.

- [ ] **Step 2: Verify it compiles in isolation**

```bash
flutter analyze lib/data/github/datasource/github_auth_datasource.dart
```

Expected: no issues for this file alone. `flutter analyze` on the whole project will fail at consumer sites — that's expected; we'll fix them in subsequent tasks.

- [ ] **Step 3: Don't commit yet** — interface and implementation must commit together. Continue to Task 4.

---

## Task 4: Implement device flow in `GitHubAuthDatasourceWeb` (TDD)

**Files:**
- Create: `test/data/github/datasource/github_auth_datasource_device_flow_test.dart`
- Modify: `lib/data/github/datasource/github_auth_datasource_web_dio.dart`

- [ ] **Step 1: Create the failing test file**

Create `test/data/github/datasource/github_auth_datasource_device_flow_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/core/errors/app_exception.dart';
import 'package:code_bench_app/data/_core/secure_storage.dart';
import 'package:code_bench_app/data/github/datasource/github_auth_datasource_web_dio.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }
}

ResponseBody _json(int status, Object? body) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    status,
    headers: {Headers.contentTypeHeader: ['application/json']},
  );
}

class _InMemorySecureStorage extends Fake implements SecureStorage {
  String? token;
  String? account;

  @override
  Future<void> writeGitHubToken(String t) async => token = t;

  @override
  Future<void> writeGitHubAccount(String json) async => account = json;
}

GitHubAuthDatasourceWeb _datasource(
  _FakeAdapter githubAdapter,
  _FakeAdapter apiAdapter, {
  SecureStorage? storage,
}) {
  final githubDio = Dio(BaseOptions(baseUrl: 'https://github.com'));
  githubDio.httpClientAdapter = githubAdapter;
  final apiDio = Dio(BaseOptions(baseUrl: 'https://api.github.com'));
  apiDio.httpClientAdapter = apiAdapter;
  return GitHubAuthDatasourceWeb.withDios(
    storage ?? _InMemorySecureStorage(),
    githubDio,
    apiDio,
  );
}

void main() {
  group('requestDeviceCode', () {
    test('parses the GitHub response into DeviceCodeResponse', () async {
      final githubAdapter = _FakeAdapter((opts) async {
        expect(opts.path, contains('/login/device/code'));
        expect(opts.method, 'POST');
        return _json(200, {
          'device_code': 'dev-xyz',
          'user_code': 'WDJB-MJHT',
          'verification_uri': 'https://github.com/login/device',
          'interval': 5,
          'expires_in': 900,
        });
      });
      final apiAdapter = _FakeAdapter((_) async => fail('api should not be called'));

      final ds = _datasource(githubAdapter, apiAdapter);
      final code = await ds.requestDeviceCode();

      expect(code.userCode, 'WDJB-MJHT');
      expect(code.verificationUri, 'https://github.com/login/device');
      expect(code.deviceCode, 'dev-xyz');
      expect(code.interval, 5);
      expect(code.expiresIn, 900);
    });
  });

  group('pollForUserToken', () {
    test('returns GitHubAccount when /access_token returns access_token', () async {
      final storage = _InMemorySecureStorage();
      final githubAdapter = _FakeAdapter((opts) async {
        expect(opts.path, contains('/login/oauth/access_token'));
        return _json(200, {'access_token': 'gho_xxx', 'token_type': 'bearer'});
      });
      final apiAdapter = _FakeAdapter((opts) async {
        expect(opts.path, contains('/user'));
        return _json(200, {
          'login': 'octocat',
          'avatar_url': 'https://example.com/a.png',
          'name': 'Octocat',
          'email': 'oct@cat.com',
        });
      });

      final ds = _datasource(githubAdapter, apiAdapter, storage: storage);
      final account = await ds.pollForUserToken('dev-xyz', 0);

      expect(account, isNotNull);
      expect(account!.username, 'octocat');
      expect(storage.token, 'gho_xxx');
    });

    test('retries on authorization_pending then returns account', () async {
      var calls = 0;
      final githubAdapter = _FakeAdapter((opts) async {
        calls++;
        if (calls == 1) return _json(200, {'error': 'authorization_pending'});
        return _json(200, {'access_token': 'gho_xxx', 'token_type': 'bearer'});
      });
      final apiAdapter = _FakeAdapter((_) async {
        return _json(200, {'login': 'octocat', 'avatar_url': 'a', 'name': 'O', 'email': null});
      });

      final ds = _datasource(githubAdapter, apiAdapter);
      final account = await ds.pollForUserToken('dev-xyz', 0);

      expect(calls, 2);
      expect(account!.username, 'octocat');
    });

    test('throws AuthException on expired_token', () async {
      final githubAdapter = _FakeAdapter((_) async => _json(200, {'error': 'expired_token'}));
      final apiAdapter = _FakeAdapter((_) async => fail('api should not be called'));

      final ds = _datasource(githubAdapter, apiAdapter);

      expect(() => ds.pollForUserToken('dev-xyz', 0), throwsA(isA<AuthException>()));
    });

    test('throws AuthException on access_denied', () async {
      final githubAdapter = _FakeAdapter((_) async => _json(200, {'error': 'access_denied'}));
      final apiAdapter = _FakeAdapter((_) async => fail('api should not be called'));

      final ds = _datasource(githubAdapter, apiAdapter);

      expect(() => ds.pollForUserToken('dev-xyz', 0), throwsA(isA<AuthException>()));
    });

    test('returns null when cancelSignal completes', () async {
      final cancel = Completer<void>();
      var calls = 0;
      final githubAdapter = _FakeAdapter((_) async {
        calls++;
        return _json(200, {'error': 'authorization_pending'});
      });
      final apiAdapter = _FakeAdapter((_) async => fail('api should not be called'));

      final ds = _datasource(githubAdapter, apiAdapter);
      final future = ds.pollForUserToken('dev-xyz', 1, cancelSignal: cancel.future);

      // Cancel after a brief moment to let one poll fire if any
      await Future.delayed(const Duration(milliseconds: 10));
      cancel.complete();

      final result = await future;
      expect(result, isNull);
    });
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
flutter test test/data/github/datasource/github_auth_datasource_device_flow_test.dart
```

Expected: FAIL — `requestDeviceCode`, `pollForUserToken`, and the `withDios` constructor don't exist yet (compile errors).

- [ ] **Step 3: Replace the implementation in `github_auth_datasource_web_dio.dart`**

Replace the **entire file** with:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../_core/http/dio_factory.dart';
import '../../_core/secure_storage.dart';
import '../models/device_code_response.dart';
import '../models/repository.dart';
import 'github_auth_datasource.dart';

part 'github_auth_datasource_web_dio.g.dart';

@Riverpod(keepAlive: true)
GitHubAuthDatasource githubAuthDatasource(Ref ref) =>
    GitHubAuthDatasourceWeb(ref.watch(secureStorageProvider));

/// Device-Flow-backed implementation of [GitHubAuthDatasource].
///
/// Holds two pre-configured Dio instances: one for github.com (auth
/// endpoints) and one for api.github.com (user lookup). Tests inject
/// stub adapters via [GitHubAuthDatasourceWeb.withDios].
class GitHubAuthDatasourceWeb implements GitHubAuthDatasource {
  GitHubAuthDatasourceWeb(this._storage)
      : _githubDio = DioFactory.create(baseUrl: 'https://github.com'),
        _apiDio = DioFactory.create(baseUrl: ApiConstants.githubApiBaseUrl);

  /// Test-only constructor — accepts pre-configured [Dio] instances so tests
  /// can inject a fake [HttpClientAdapter] without hitting real GitHub.
  @visibleForTesting
  GitHubAuthDatasourceWeb.withDios(this._storage, this._githubDio, this._apiDio);

  static const _clientId = String.fromEnvironment('GITHUB_CLIENT_ID');

  final SecureStorage _storage;
  final Dio _githubDio;
  final Dio _apiDio;

  @override
  Future<DeviceCodeResponse> requestDeviceCode() async {
    try {
      final response = await _githubDio.post(
        '/login/device/code',
        data: {'client_id': _clientId},
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return DeviceCodeResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      dLog('[GitHubAuthDatasource] requestDeviceCode failed (${e.type})');
      throw AuthException('Failed to request device code', originalError: e);
    }
  }

  @override
  Future<GitHubAccount?> pollForUserToken(
    String deviceCode,
    int intervalSeconds, {
    Future<void>? cancelSignal,
  }) async {
    var interval = Duration(seconds: intervalSeconds);

    while (true) {
      final cancelled = await _waitOrCancel(interval, cancelSignal);
      if (cancelled) return null;

      final Response<dynamic> response;
      try {
        response = await _githubDio.post(
          '/login/oauth/access_token',
          data: {
            'client_id': _clientId,
            'device_code': deviceCode,
            'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          },
          options: Options(headers: {'Accept': 'application/json'}),
        );
      } on DioException catch (e) {
        dLog('[GitHubAuthDatasource] poll failed (${e.type})');
        throw AuthException('Device flow polling failed', originalError: e);
      }

      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token != null) {
        await _storage.writeGitHubToken(token);
        final account = await _fetchUserInfo(token);
        await _storage.writeGitHubAccount(jsonEncode(account.toJson()));
        return account;
      }

      final error = data['error'] as String?;
      switch (error) {
        case 'authorization_pending':
          continue;
        case 'slow_down':
          interval += const Duration(seconds: 5);
          continue;
        case 'expired_token':
          throw const AuthException('Device code expired — please try signing in again');
        case 'access_denied':
          throw const AuthException('Authorization denied');
        default:
          throw AuthException(
            'Device flow failed: ${data['error_description'] ?? error}',
          );
      }
    }
  }

  /// Returns true if [cancelSignal] completed before [interval] elapsed.
  Future<bool> _waitOrCancel(Duration interval, Future<void>? cancelSignal) async {
    if (cancelSignal == null) {
      await Future<void>.delayed(interval);
      return false;
    }
    final delay = Future<void>.delayed(interval).then((_) => false);
    final cancel = cancelSignal.then((_) => true);
    return Future.any([delay, cancel]);
  }

  Future<GitHubAccount> _fetchUserInfo(String token) async {
    final response = await _apiDio.get(
      '/user',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
      }),
    );
    final data = response.data as Map<String, dynamic>;
    return GitHubAccount(
      username: data['login'] as String,
      avatarUrl: data['avatar_url'] as String,
      email: data['email'] as String?,
      name: data['name'] as String?,
    );
  }

  @override
  Future<GitHubAccount> signInWithPat(String token) async {
    try {
      final account = await _fetchUserInfo(token);
      await _storage.writeGitHubToken(token);
      await _storage.writeGitHubAccount(jsonEncode(account.toJson()));
      return account;
    } on AuthException {
      rethrow;
    } catch (e) {
      // Deliberately do NOT interpolate `e` here — a Dio error's toString()
      // can surface request headers (including the PAT). See
      // macos/Runner/README.md threat model.
      dLog('[GitHubAuthDatasource] signInWithPat failed (${e.runtimeType}) — original suppressed for PAT safety');
      throw const AuthException('GitHub token rejected');
    }
  }

  @override
  Future<GitHubAccount?> getStoredAccount() async {
    final token = await _storage.readGitHubToken();
    if (token == null) return null;
    final json = await _storage.readGitHubAccount();
    if (json != null) {
      try {
        return GitHubAccount.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } catch (e) {
        dLog('[GitHubAuthDatasource] cached account parse failed, falling back to network: $e');
      }
    }
    try {
      final account = await _fetchUserInfo(token);
      await _storage.writeGitHubAccount(jsonEncode(account.toJson()));
      return account;
    } catch (e) {
      dLog('[GitHubAuthDatasource] getStoredAccount network fallback failed (${e.runtimeType})');
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.readGitHubToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> signOut() async {
    await _storage.deleteGitHubToken();
    await _storage.deleteGitHubAccount();
  }
}
```

> Notes:
> - `package:meta/meta.dart` provides `@visibleForTesting` (lighter than `package:flutter/foundation.dart`)
> - The `flutter_web_auth_2` import is gone — device flow doesn't use it
> - The package itself can stay in `pubspec.yaml`; removing the dependency is out of scope

- [ ] **Step 4: Run the device-flow tests — must pass**

```bash
flutter test test/data/github/datasource/github_auth_datasource_device_flow_test.dart
```

Expected:
```
+5: All tests passed!
```

- [ ] **Step 5: Don't run the full test suite yet** — repository/notifier/widget callers are still broken until Tasks 5–7. Continue.

- [ ] **Step 6: Don't commit yet** — Tasks 3 + 4 commit together with Task 5 to keep compilation green per-commit. Move to Task 5.

---

## Task 5: Update repository, repository impl, and service

**Files:**
- Modify: `lib/data/github/repository/github_repository.dart`
- Modify: `lib/data/github/repository/github_repository_impl.dart`
- Modify: `lib/services/github/github_service.dart`

- [ ] **Step 1: Replace `authenticate()` in `github_repository.dart`**

In `lib/data/github/repository/github_repository.dart`, replace the line:
```dart
Future<GitHubAccount> authenticate();
```

With:
```dart
Future<DeviceCodeResponse> requestDeviceCode();

Future<GitHubAccount?> pollForUserToken(
  String deviceCode,
  int intervalSeconds, {
  Future<void>? cancelSignal,
});
```

And add this import at the top of the file (preserving existing imports):
```dart
import '../models/device_code_response.dart';
```

- [ ] **Step 2: Replace `authenticate()` in `github_repository_impl.dart`**

In `lib/data/github/repository/github_repository_impl.dart`, replace:
```dart
@override
Future<GitHubAccount> authenticate() => _auth.authenticate();
```

With:
```dart
@override
Future<DeviceCodeResponse> requestDeviceCode() => _auth.requestDeviceCode();

@override
Future<GitHubAccount?> pollForUserToken(
  String deviceCode,
  int intervalSeconds, {
  Future<void>? cancelSignal,
}) =>
    _auth.pollForUserToken(deviceCode, intervalSeconds, cancelSignal: cancelSignal);
```

Add the import:
```dart
import '../models/device_code_response.dart';
```

- [ ] **Step 3: Replace `authenticate()` in `github_service.dart`**

In `lib/services/github/github_service.dart`, replace:
```dart
Future<GitHubAccount> authenticate() => _repo.authenticate();
```

With:
```dart
Future<DeviceCodeResponse> requestDeviceCode() => _repo.requestDeviceCode();

Future<GitHubAccount?> pollForUserToken(
  String deviceCode,
  int intervalSeconds, {
  Future<void>? cancelSignal,
}) =>
    _repo.pollForUserToken(deviceCode, intervalSeconds, cancelSignal: cancelSignal);
```

Add the import:
```dart
import '../../data/github/models/device_code_response.dart';
```

And add `DeviceCodeResponse` to the existing `export` line so consumers can import via `github_service.dart`:

Replace:
```dart
export '../../data/github/models/repository.dart' show GitHubAccount, GitTreeItem, Repository;
```

With:
```dart
export '../../data/github/models/repository.dart' show GitHubAccount, GitTreeItem, Repository;
export '../../data/github/models/device_code_response.dart' show DeviceCodeResponse;
```

- [ ] **Step 4: Verify the data and service layers compile**

```bash
flutter analyze lib/data/github/ lib/services/github/
```

Expected: no issues for these directories. (The notifier and widgets still reference the old `authenticate()` — that's expected, fixed in Task 6.)

- [ ] **Step 5: Don't commit yet** — Task 6 fixes the notifier so the build is green again.

---

## Task 6: Update `GitHubAuthNotifier`

**Files:**
- Modify: `lib/features/onboarding/notifiers/github_auth_notifier.dart`

- [ ] **Step 1: Replace the file contents**

Replace the entire `lib/features/onboarding/notifiers/github_auth_notifier.dart` with:

```dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/github/github_service.dart';

part 'github_auth_notifier.g.dart';

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubService] directly.
@Riverpod(keepAlive: true)
class GitHubAuthNotifier extends _$GitHubAuthNotifier {
  Completer<void>? _cancelSignal;

  @override
  Future<GitHubAccount?> build() async {
    final svc = await ref.watch(githubServiceProvider.future);
    return svc.getStoredAccount();
  }

  /// Requests a device code from GitHub and starts background polling.
  /// Returns the device code immediately so the dialog can display it.
  /// Notifier state transitions to AsyncData(GitHubAccount) when the user
  /// authorizes, AsyncError on failure, or AsyncData(null) on cancel.
  Future<DeviceCodeResponse> startDeviceFlow() async {
    state = const AsyncLoading();
    final svc = await ref.read(githubServiceProvider.future);
    final code = await svc.requestDeviceCode();

    final cancelSignal = Completer<void>();
    _cancelSignal = cancelSignal;
    unawaited(_pollInBackground(svc, code, cancelSignal));
    return code;
  }

  Future<void> _pollInBackground(
    GitHubService svc,
    DeviceCodeResponse code,
    Completer<void> cancelSignal,
  ) async {
    state = await AsyncValue.guard(() async {
      return svc.pollForUserToken(
        code.deviceCode,
        code.interval,
        cancelSignal: cancelSignal.future,
      );
    });
  }

  /// Cancels in-flight polling. State returns to AsyncData(null).
  void cancelDeviceFlow() {
    final signal = _cancelSignal;
    if (signal != null && !signal.isCompleted) {
      signal.complete();
    }
    _cancelSignal = null;
    state = const AsyncData(null);
  }

  /// Deletes the stored token, then clears account state on success.
  ///
  /// We must delete before clearing: an optimistic `AsyncData(null)` followed
  /// by a failed keychain delete would leave the token on disk while the UI
  /// reports "signed out", and the next `build()` would silently
  /// re-authenticate from the leaked credential. On cleanup failure the
  /// notifier surfaces an [AsyncError] so a listener can warn the user.
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final svc = await ref.read(githubServiceProvider.future);
      await svc.signOut();
      return null;
    });
  }

  /// Validates [token] against the GitHub API, persists it on success, and
  /// updates state. The token never leaves the service layer.
  Future<void> signInWithPat(String token) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final svc = await ref.read(githubServiceProvider.future);
      return svc.signInWithPat(token);
    });
  }
}
```

- [ ] **Step 2: Run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `github_auth_notifier.g.dart` regenerates without errors.

- [ ] **Step 3: Verify the notifier compiles**

```bash
flutter analyze lib/features/onboarding/notifiers/
```

Expected: no issues. (The widgets still call `.authenticate()` — that's fixed in Task 8.)

- [ ] **Step 4: Don't commit yet** — Task 7 (dialog) and Task 8 (callsites) commit together.

---

## Task 7: Create `GitHubDeviceFlowDialog`

**Files:**
- Create: `lib/features/onboarding/widgets/github_device_flow_dialog.dart`

- [ ] **Step 1: Inspect the existing AppDialog API**

Open `lib/core/widgets/app_dialog.dart` to confirm the `AppDialog` constructor signature. The widget you'll build below uses:

```dart
AppDialog(
  icon: IconData,
  iconType: AppDialogIconType,
  title: String,
  subtitle: String?,
  content: Widget,
  actions: List<AppDialogAction>?,
)
```

- [ ] **Step 2: Inspect the existing GitHub icon constant**

Run:
```bash
grep -n "github" lib/core/constants/app_icons.dart
```

Note the exact identifier (e.g. `AppIcons.github`) — use it in step 3.

- [ ] **Step 3: Create the dialog file**

Create `lib/features/onboarding/widgets/github_device_flow_dialog.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../services/github/github_service.dart';
import '../notifiers/github_auth_notifier.dart';

/// Frosted-glass dialog implementing the GitHub Device Flow user-facing screen.
///
/// Mounted by tapping "Sign in with GitHub". On mount it asks the notifier to
/// `startDeviceFlow()`, displays the resulting 8-character code (auto-copying
/// it to clipboard), and listens for the auth provider to transition to a
/// signed-in state — at which point the dialog dismisses itself.
class GitHubDeviceFlowDialog extends ConsumerStatefulWidget {
  const GitHubDeviceFlowDialog({super.key});

  static Future<void> show(BuildContext context) =>
      showDialog<void>(context: context, builder: (_) => const GitHubDeviceFlowDialog());

  @override
  ConsumerState<GitHubDeviceFlowDialog> createState() => _GitHubDeviceFlowDialogState();
}

class _GitHubDeviceFlowDialogState extends ConsumerState<GitHubDeviceFlowDialog> {
  DeviceCodeResponse? _code;
  String? _initError;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      final code = await ref.read(gitHubAuthProvider.notifier).startDeviceFlow();
      if (!mounted) return;
      setState(() => _code = code);
      await Clipboard.setData(ClipboardData(text: code.userCode));
    } catch (e) {
      if (mounted) setState(() => _initError = e.toString());
    }
  }

  void _onCancel() {
    ref.read(gitHubAuthProvider.notifier).cancelDeviceFlow();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gitHubAuthProvider, (previous, next) {
      next.whenData((account) {
        if (account != null && mounted) Navigator.of(context).pop();
      });
    });

    final code = _code;
    final initError = _initError;

    return AppDialog(
      icon: AppIcons.github,
      iconType: AppDialogIconType.teal,
      title: 'Sign in to GitHub',
      subtitle: code == null
          ? 'Requesting code…'
          : 'Enter this code at github.com/login/device',
      content: _DeviceFlowContent(code: code, initError: initError),
      actions: [
        AppDialogAction.cancel(onPressed: _onCancel),
      ],
    );
  }
}

class _DeviceFlowContent extends StatelessWidget {
  const _DeviceFlowContent({required this.code, required this.initError});

  final DeviceCodeResponse? code;
  final String? initError;

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: ThemeConstants.spacing16),
        child: Text(
          initError!,
          style: TextStyle(color: AppColors.of(context).textError),
        ),
      );
    }

    if (code == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: ThemeConstants.spacing24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: ThemeConstants.spacing16),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeConstants.spacing24,
            vertical: ThemeConstants.spacing12,
          ),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(ThemeConstants.radius8),
          ),
          child: SelectableText(
            code!.userCode,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: ThemeConstants.spacing16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () async {
                try {
                  await launchUrl(Uri.parse(code!.verificationUri));
                } catch (_) {
                  // launchUrl is widget-permitted; failures are swallowed
                  // because the user can still copy the URL manually.
                }
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open browser'),
            ),
            const SizedBox(width: ThemeConstants.spacing8),
            TextButton.icon(
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: code!.userCode));
                } catch (_) {
                  // Clipboard is widget-permitted; nothing to do on failure.
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy code'),
            ),
          ],
        ),
        const SizedBox(height: ThemeConstants.spacing16),
        Text(
          'Waiting for authorization…',
          style: TextStyle(color: c.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}
```

> **Color tokens:** `c.surfaceMuted`, `c.textPrimary`, `c.textMuted`, `c.textError` are taken from `AppColors`. If any of these names don't exist verbatim in [app_colors.dart](lib/core/theme/app_colors.dart), substitute the closest equivalent — do **not** introduce new tokens for this dialog.
> **Spacing tokens:** `ThemeConstants.spacing8/12/16/24` and `ThemeConstants.radius8` are taken from [theme_constants.dart](lib/core/constants/theme_constants.dart). If different names are in use, substitute equivalents.

- [ ] **Step 4: Verify the dialog compiles**

```bash
flutter analyze lib/features/onboarding/widgets/github_device_flow_dialog.dart
```

Expected: no issues. If `AppColors` token names differ, substitute with equivalents and re-run.

- [ ] **Step 5: Don't commit yet** — Task 8 wires the dialog into existing screens. Continue.

---

## Task 8: Wire callsites and final cleanup

**Files:**
- Modify: `lib/features/onboarding/widgets/github_step.dart`
- Modify: `lib/features/integrations/integrations_screen.dart`

- [ ] **Step 1: Update `github_step.dart`**

Open `lib/features/onboarding/widgets/github_step.dart`. Find the line:
```dart
await ref.read(gitHubAuthProvider.notifier).authenticate();
```

Replace with:
```dart
await GitHubDeviceFlowDialog.show(context);
```

Add the import (preserving existing imports):
```dart
import 'github_device_flow_dialog.dart';
```

> **Note on the provider name:** Riverpod's generator strips the `Notifier` suffix when emitting provider variable names — `class GitHubAuthNotifier` → `gitHubAuthProvider`. The existing widget callsite already uses `gitHubAuthProvider`, so no rename needed.

- [ ] **Step 2: Update `integrations_screen.dart`**

Open `lib/features/integrations/integrations_screen.dart`. Find the line:
```dart
await ref.read(gitHubAuthProvider.notifier).authenticate();
```

Replace with:
```dart
await GitHubDeviceFlowDialog.show(context);
```

Add the import:
```dart
import '../onboarding/widgets/github_device_flow_dialog.dart';
```

- [ ] **Step 3: Run the full analyzer**

```bash
flutter analyze
```

Expected: no issues. Fix any remaining references to `authenticate()` in widgets/screens (unlikely, but possible if the search in pre-flight missed any).

- [ ] **Step 4: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass. The PKCE test was deleted; the new device-flow test passes; everything else (existing notifier/service tests) is unaffected.

- [ ] **Step 5: Format**

```bash
dart format lib/ test/
```

- [ ] **Step 6: Commit (combined Tasks 3-8)**

```bash
git add lib/data/github/datasource/github_auth_datasource.dart \
        lib/data/github/datasource/github_auth_datasource_web_dio.dart \
        lib/data/github/repository/github_repository.dart \
        lib/data/github/repository/github_repository_impl.dart \
        lib/services/github/github_service.dart \
        lib/features/onboarding/notifiers/github_auth_notifier.dart \
        lib/features/onboarding/notifiers/github_auth_notifier.g.dart \
        lib/features/onboarding/widgets/github_device_flow_dialog.dart \
        lib/features/onboarding/widgets/github_step.dart \
        lib/features/integrations/integrations_screen.dart \
        test/data/github/datasource/github_auth_datasource_device_flow_test.dart
git commit -m "feat: switch GitHub auth to Device Flow on GitHub App"
```

---

## Post-implementation: manual smoke test

Before considering this work merge-ready:

1. Make sure the **`Benchlabs Codebench`** GitHub App on github.com has **"Enable Device Flow"** ticked (this is a one-time setting per spec section "GitHub-side setup")

2. Update local `env.json` with the GitHub App's client_id (the `Iv23li…` one):
   ```json
   { "GITHUB_CLIENT_ID": "Iv23liXXXXXX" }
   ```

3. Run the app:
   ```bash
   flutter run -d macos --dart-define-from-file=env.json
   ```

4. Click **Sign in with GitHub** somewhere in the UI (onboarding or integrations screen)

5. Verify:
   - Dialog appears with an 8-character code
   - Clipboard contains the code (paste into a text editor to confirm)
   - "Open browser" launches `https://github.com/login/device`
   - Pasting the code and authorizing in the browser causes the dialog to dismiss within ~5 seconds
   - The app shows "Signed in as @username"

6. Verify cancel:
   - Trigger the flow again
   - Click "Cancel" in the dialog before authorizing
   - The dialog closes, no error appears, the user is not signed in
