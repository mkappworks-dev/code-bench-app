# GitHub OAuth PKCE — Design

**Date:** 2026-05-03
**Status:** Approved

## Problem

The existing `GitHubAuthDatasourceWeb.authenticate()` builds an OAuth authorize URL with no PKCE parameters and exchanges the code for a token without a `code_verifier`. A `client_secret` is also absent, meaning the token exchange would fail against a real GitHub OAuth App today. PAT sign-in is the only working auth path.

## Goal

Add PKCE (RFC 7636, S256 method) to the existing OAuth flow so the app can authenticate users via browser-based GitHub OAuth without ever shipping or using a `client_secret`.

## Decisions

| Question | Decision |
|---|---|
| App type | GitHub **OAuth App** (classic scopes, long-lived tokens, simpler UX) |
| `client_id` sourcing | `--dart-define=GITHUB_CLIENT_ID=...` at build/run time; no default in source so forks must register their own OAuth App |
| PAT flow | Kept as-is — untouched fallback |
| New dependencies | None — `crypto: 3.0.7` already in `pubspec.yaml` |

## GitHub-side setup (one-time, manual)

1. `github.com/Benchlabs` → **Settings → Developer settings → OAuth Apps → New OAuth App**
2. Fields:
   - **Application name:** Code Bench
   - **Homepage URL:** your landing page URL
   - **Application description:** AI-powered desktop coding assistant. Accesses your repositories to read file history, apply code changes, and manage branches.
   - **Authorization callback URL:** `codebench://oauth/callback`
   - **Enable Device Flow:** unchecked
3. **Register application**
4. Copy the **Client ID** — supply it at build/run time via `--dart-define=GITHUB_CLIENT_ID=<your-id>`
5. Do **not** store or use the generated Client Secret — PKCE replaces it

## Code changes

**File:** `lib/data/github/datasource/github_auth_datasource_web_dio.dart`

### `client_id` sourcing

Replace the hardcoded placeholder with a compile-time constant:

```dart
static const _clientId = String.fromEnvironment('GITHUB_CLIENT_ID');
```

Supplied at build time:
```bash
flutter run -d macos --dart-define=GITHUB_CLIENT_ID=Ov23liXXXXXX
flutter build macos --dart-define=GITHUB_CLIENT_ID=Ov23liXXXXXX
```

Forks must register their own OAuth App and supply their own ID. The source never contains the production value.

### New imports

```dart
import 'dart:math';
import 'package:crypto/crypto.dart';
```

### New private method

```dart
({String verifier, String challenge}) _generatePkce() {
  final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
  final verifier = base64UrlEncode(bytes).replaceAll('=', '');
  final challenge = base64UrlEncode(
    sha256.convert(utf8.encode(verifier)).bytes,
  ).replaceAll('=', '');
  return (verifier: verifier, challenge: challenge);
}
```

32 random bytes → 43-char base64url `verifier`. SHA-256 of that → base64url `challenge`. Padding stripped per RFC 7636 §4.2.

### Updated `authenticate()`

Generate PKCE pair at the start; add `code_challenge` + `code_challenge_method=S256` to the authorization URL query parameters; pass `verifier` into `_exchangeCodeForToken`.

```dart
final pkce = _generatePkce();

final authUrl = Uri.parse(ApiConstants.githubAuthUrl).replace(
  queryParameters: {
    'client_id': _clientId,
    'scope': ApiConstants.githubScopes,
    'redirect_uri': AppConstants.oauthCallbackUrl,
    'code_challenge': pkce.challenge,
    'code_challenge_method': 'S256',
  },
);
// ...
final token = await _exchangeCodeForToken(code, pkce.verifier);
```

### Updated `_exchangeCodeForToken`

Accept `codeVerifier` parameter; include it in the POST body. No `client_secret` field.

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
  // ... token extraction unchanged
}
```

## Data flow

```
authenticate()
  │
  ├─ _generatePkce() → { verifier, challenge }  ← in memory only, never persisted
  │
  ├─ build authUrl with code_challenge + S256
  │
  ├─ FlutterWebAuth2.authenticate()
  │     browser → user logs in → GitHub stores challenge server-side
  │     → redirect to codebench://oauth/callback?code=xyz
  │
  ├─ extract code   (null → AuthException, existing check)
  │
  ├─ _exchangeCodeForToken(code, verifier)
  │     GitHub: sha256(verifier) == stored challenge?
  │     mismatch → {"error":"bad_verification_code"} → token null → AuthException
  │
  └─ store token → fetch user → return GitHubAccount
```

## Error handling

No new error cases. Both PKCE failure modes (malformed challenge, verifier mismatch) fall through the two existing `null` guards and surface as `AuthException` — identical to the current flow.

## Security notes

- `verifier` is ephemeral — lives only in the `authenticate()` stack frame, never written to `SecureStorage`
- `client_id` is public information (visible on the GitHub OAuth App page); the `--dart-define` approach keeps it out of source so forks can't accidentally reuse the production app identity
- `client_secret` is never present in the app; PKCE is the sole proof of origin
