# GitHub OAuth PKCE Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add PKCE (RFC 7636, S256) to the existing GitHub OAuth flow and supply `client_id` via a gitignored `env.json` file so the source never contains production credentials.

**Architecture:** `GitHubAuthDatasourceWeb.authenticate()` generates an ephemeral `(verifier, challenge)` pair, adds `code_challenge` + `code_challenge_method=S256` to the GitHub authorize URL, and forwards `code_verifier` on the token exchange — replacing the absent `client_secret`. The `client_id` is sourced from `String.fromEnvironment('GITHUB_CLIENT_ID')` supplied by `--dart-define-from-file=env.json` at build time.

**Tech Stack:** Flutter/Dart, `package:crypto` (already in pubspec), `flutter_web_auth_2`, Dio, Riverpod.

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Modify | `.gitignore` | Add `env.json` entry |
| Create | `env.json.example` | Committed template documenting required keys |
| Create | `.vscode/launch.json` | VS Code run config passing `--dart-define-from-file=env.json` |
| Create | `test/data/github/datasource/github_auth_datasource_pkce_test.dart` | Unit tests for PKCE generation math |
| Modify | `lib/data/github/datasource/github_auth_datasource_web_dio.dart` | PKCE implementation + env-sourced client_id |

---

## Task 1: env.json infrastructure

**Files:**
- Modify: `.gitignore`
- Create: `env.json.example`
- Create: `.vscode/launch.json`

- [ ] **Step 1: Add `env.json` to `.gitignore`**

Open `.gitignore` and add after the `app.*.map.json` line (around line 40):

```
# Local build-time env — never commit real values
env.json
```

- [ ] **Step 2: Create `env.json.example`**

Create `env.json.example` at the repo root:

```json
{
  "GITHUB_CLIENT_ID": "YOUR_GITHUB_CLIENT_ID"
}
```

- [ ] **Step 3: Create `.vscode/launch.json`**

Create `.vscode/launch.json` at the repo root:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Code Bench (macOS)",
      "request": "launch",
      "type": "dart",
      "toolArgs": ["--dart-define-from-file=env.json"]
    }
  ]
}
```

- [ ] **Step 4: Verify gitignore works**

Run:
```bash
git status
```
Expected: `env.json` is NOT listed (gitignored). `env.json.example` and `.vscode/launch.json` ARE listed as untracked.

- [ ] **Step 5: Commit**

```bash
git add .gitignore env.json.example .vscode/launch.json
git commit -m "chore: add env.json setup for dart-define-from-file"
```

---

## Task 2: Write failing PKCE tests

**Files:**
- Create: `test/data/github/datasource/github_auth_datasource_pkce_test.dart`

- [ ] **Step 1: Create the test file**

Create `test/data/github/datasource/github_auth_datasource_pkce_test.dart`:

```dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/_core/secure_storage.dart';
import 'package:code_bench_app/data/github/datasource/github_auth_datasource_web_dio.dart';

class _FakeSecureStorage extends Fake implements SecureStorage {}

void main() {
  late GitHubAuthDatasourceWeb datasource;

  setUp(() {
    datasource = GitHubAuthDatasourceWeb(_FakeSecureStorage());
  });

  group('generatePkce', () {
    test('verifier meets RFC 7636 minimum length of 43 chars', () {
      final pkce = datasource.generatePkce();
      expect(pkce.verifier.length, greaterThanOrEqualTo(43));
    });

    test('verifier contains only base64url characters with no padding', () {
      final pkce = datasource.generatePkce();
      expect(pkce.verifier, matches(RegExp(r'^[A-Za-z0-9\-_]+$')));
    });

    test('challenge contains only base64url characters with no padding', () {
      final pkce = datasource.generatePkce();
      expect(pkce.challenge, matches(RegExp(r'^[A-Za-z0-9\-_]+$')));
    });

    test('challenge is S256 of verifier (RFC 7636 §4.6)', () {
      final pkce = datasource.generatePkce();
      final expected = base64UrlEncode(
        sha256.convert(utf8.encode(pkce.verifier)).bytes,
      ).replaceAll('=', '');
      expect(pkce.challenge, equals(expected));
    });

    test('verifier and challenge are distinct', () {
      final pkce = datasource.generatePkce();
      expect(pkce.verifier, isNot(equals(pkce.challenge)));
    });

    test('successive calls produce different verifiers', () {
      final pkce1 = datasource.generatePkce();
      final pkce2 = datasource.generatePkce();
      expect(pkce1.verifier, isNot(equals(pkce2.verifier)));
    });
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
flutter test test/data/github/datasource/github_auth_datasource_pkce_test.dart
```

Expected: FAIL — `The method 'generatePkce' isn't defined for the type 'GitHubAuthDatasourceWeb'` (or similar compile error). This confirms TDD red state.

---

## Task 3: Implement PKCE in the datasource

**Files:**
- Modify: `lib/data/github/datasource/github_auth_datasource_web_dio.dart`

- [ ] **Step 1: Add missing imports**

At the top of `github_auth_datasource_web_dio.dart`, add after `import 'dart:convert';`:

```dart
import 'dart:math';
```

And after `import 'package:dio/dio.dart';`:

```dart
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
```

- [ ] **Step 2: Replace the hardcoded `_clientId` with env-sourced constant**

Replace:
```dart
static const _clientId = 'YOUR_GITHUB_CLIENT_ID';
```

With:
```dart
static const _clientId = String.fromEnvironment('GITHUB_CLIENT_ID');
```

- [ ] **Step 3: Add `generatePkce()` method**

Add this method to `GitHubAuthDatasourceWeb`, just before `authenticate()`:

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

- [ ] **Step 4: Update `authenticate()` to use PKCE**

Replace the existing `authenticate()` method body with:

```dart
@override
Future<GitHubAccount> authenticate() async {
  try {
    final pkce = generatePkce();

    final authUrl = Uri.parse(ApiConstants.githubAuthUrl).replace(
      queryParameters: {
        'client_id': _clientId,
        'scope': ApiConstants.githubScopes,
        'redirect_uri': AppConstants.oauthCallbackUrl,
        'code_challenge': pkce.challenge,
        'code_challenge_method': 'S256',
      },
    );

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: AppConstants.oauthScheme,
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) throw const AuthException('OAuth callback missing code');

    final token = await _exchangeCodeForToken(code, pkce.verifier);
    await _storage.writeGitHubToken(token);

    final account = await _fetchUserInfo(token);
    await _storage.writeGitHubAccount(jsonEncode(account.toJson()));
    return account;
  } on AuthException {
    rethrow;
  } catch (e) {
    throw AuthException('GitHub authentication failed', originalError: e);
  }
}
```

- [ ] **Step 5: Update `_exchangeCodeForToken` to accept and send `code_verifier`**

Replace the existing `_exchangeCodeForToken` signature and body with:

```dart
Future<String> _exchangeCodeForToken(String code, String codeVerifier) async {
  final dio = DioFactory.create(baseUrl: 'https://github.com');
  final response = await dio.post(
    '/login/oauth/access_token',
    data: {
      'client_id': _clientId,
      'code': code,
      'redirect_uri': AppConstants.oauthCallbackUrl,
      'code_verifier': codeVerifier,
    },
    options: Options(headers: {'Accept': 'application/json'}),
  );
  final data = response.data as Map<String, dynamic>;
  final token = data['access_token'] as String?;
  if (token == null) {
    throw AuthException(
      'Failed to obtain access token: ${data['error_description'] ?? data['error']}',
    );
  }
  return token;
}
```

- [ ] **Step 6: Run the PKCE tests and confirm they pass**

```bash
flutter test test/data/github/datasource/github_auth_datasource_pkce_test.dart
```

Expected:
```
00:00 +6: All tests passed!
```

- [ ] **Step 7: Run the full test suite**

```bash
flutter test
```

Expected: all existing tests still pass. Fix any failures before continuing.

- [ ] **Step 8: Format and analyze**

```bash
dart format lib/data/github/datasource/github_auth_datasource_web_dio.dart test/data/github/datasource/github_auth_datasource_pkce_test.dart
flutter analyze
```

Expected: no issues. Fix any warnings before committing.

- [ ] **Step 9: Commit**

```bash
git add lib/data/github/datasource/github_auth_datasource_web_dio.dart \
        test/data/github/datasource/github_auth_datasource_pkce_test.dart
git commit -m "feat: add PKCE (S256) to GitHub OAuth flow"
```

---

## Post-implementation: local smoke test

After both commits, test the full OAuth flow locally:

1. Create your local `env.json`:
   ```bash
   cp env.json.example env.json
   # Edit env.json and add your Client ID from the Benchlabs org OAuth App
   ```

2. Run the app:
   ```bash
   flutter run -d macos --dart-define-from-file=env.json
   ```

3. Navigate to the GitHub sign-in screen and tap "Sign in with GitHub". The browser should open, you should be able to log in, and the app should receive the callback and store the token.

4. If `_clientId` is empty (env.json missing or key not set), GitHub will return an error on the authorize URL — the existing `AuthException` handler will surface it to the UI.
