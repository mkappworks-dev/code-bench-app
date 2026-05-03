# GitHub App + Device Flow — Design

**Date:** 2026-05-03
**Status:** Approved
**Supersedes:** [2026-05-03-github-oauth-pkce-design.md](2026-05-03-github-oauth-pkce-design.md) — OAuth App + PKCE web flow (requires `client_secret`)

## Problem

An earlier design attempted PKCE on GitHub's standard OAuth web flow (first on an OAuth App, then on a GitHub App) under the assumption that PKCE would substitute for `client_secret`. Verification against GitHub's documentation showed this is false for both app types — the `/login/oauth/access_token` endpoint requires `client_secret` regardless of PKCE parameters; PKCE is documented as additional defence, not a replacement. The only GitHub flow that does not require a client secret is **Device Flow**, which trades a callback redirect for an in-app code-display screen.

## Goal

Implement GitHub authentication via the **Device Flow** on a GitHub App. The user sees an 8-character code in a Code Bench dialog, opens a browser to `github.com/login/device`, pastes the code, and authorizes. The app polls in the background and stores the resulting non-expiring access token. **No `client_secret` is ever embedded in the binary.**

## Decisions

| Question | Decision |
|---|---|
| App type | **GitHub App** (`Benchlabs Codebench`) — same registration as the prior spec, plus "Enable Device Flow" |
| Auth flow | **Device Flow** — no callback URL used, no PKCE |
| Token lifetime | **Non-expiring** ("Expire user authorization tokens" unchecked) — no refresh-token plumbing |
| Code-display surface | **`AppDialog`** — the project's standard frosted-glass dialog from `lib/core/widgets/app_dialog.dart` |
| `client_id` sourcing | `--dart-define-from-file=env.json` (unchanged) |
| `client_secret` | **None** — never generated, never sent |
| PAT flow | **Kept** — `signInWithPat()` and its UI unchanged |

## GitHub-side setup

The `Benchlabs Codebench` GitHub App is already registered. **One additional change:**

`github.com/Benchlabs` → **Settings → Developer settings → GitHub Apps → Benchlabs Codebench → Edit**

Scroll to the bottom and tick:

> ☑️ **Enable Device Flow**

Save. Everything else stays as previously configured:

- Callback URL: `codebench://oauth/callback` (still required by the form, but unused by Device Flow)
- "Request user authorization (OAuth) during installation": checked (works alongside Device Flow)
- "Expire user authorization tokens": unchecked
- Permissions: Repository → Contents R/W, Pull requests R/W, Metadata R; Account → Email addresses R
- "Where can this GitHub App be installed?": Any account

The `client_id` (e.g. `Iv23li…`) goes into local `env.json` exactly as in the prior spec — no `client_secret` ever generated or used.

## Local development setup

Unchanged from the prior spec. `env.json` gitignored, `env.json.example` committed, `.vscode/launch.json` passes `--dart-define-from-file=env.json` automatically.

```json
{
  "GITHUB_CLIENT_ID": "Iv23li..."
}
```

## Code changes

### 1. New model: `DeviceCodeResponse`

Location: `lib/data/github/models/device_code_response.dart` (freezed, follows existing `Repository` model pattern in this folder)

```dart
@freezed
class DeviceCodeResponse with _$DeviceCodeResponse {
  const factory DeviceCodeResponse({
    required String userCode,
    required String verificationUri,
    required String deviceCode,
    required int interval,
    required int expiresIn,
  }) = _DeviceCodeResponse;

  factory DeviceCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceCodeResponseFromJson(json);
}
```

### 2. Datasource interface — replace `authenticate()` with two methods

`lib/data/github/datasource/github_auth_datasource.dart`:

```dart
abstract interface class GitHubAuthDatasource {
  Future<DeviceCodeResponse> requestDeviceCode();
  Future<GitHubAccount> pollForUserToken(String deviceCode, int intervalSeconds);

  Future<GitHubAccount> signInWithPat(String token);     // unchanged
  Future<GitHubAccount?> getStoredAccount();             // unchanged
  Future<bool> isAuthenticated();                        // unchanged
  Future<void> signOut();                                // unchanged
}
```

The previous `authenticate()` method is removed.

### 3. Datasource implementation

`lib/data/github/datasource/github_auth_datasource_web_dio.dart`:

- Remove imports: `flutter_web_auth_2`, `dart:math`, `package:crypto/crypto.dart`, `package:flutter/foundation.dart` (the `@visibleForTesting` annotation is no longer needed since `generatePkce` is removed)
- Remove `_clientId` constant — keep it; still required for device flow
- Remove `generatePkce()` method
- Remove `authenticate()` method body
- Remove `_exchangeCodeForToken()` (replaced by polling logic)

Add:

```dart
@override
Future<DeviceCodeResponse> requestDeviceCode() async {
  final dio = DioFactory.create(baseUrl: 'https://github.com');
  final response = await dio.post(
    '/login/device/code',
    data: {'client_id': _clientId},
    options: Options(headers: {'Accept': 'application/json'}),
  );
  return DeviceCodeResponse.fromJson(response.data as Map<String, dynamic>);
}

@override
Future<GitHubAccount> pollForUserToken(String deviceCode, int intervalSeconds) async {
  final dio = DioFactory.create(baseUrl: 'https://github.com');
  var interval = Duration(seconds: intervalSeconds);
  while (true) {
    await Future.delayed(interval);
    final response = await dio.post(
      '/login/oauth/access_token',
      data: {
        'client_id': _clientId,
        'device_code': deviceCode,
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );
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
        interval = Duration(seconds: interval.inSeconds + 5);
        continue;
      case 'expired_token':
        throw const AuthException('Device code expired — please try signing in again');
      case 'access_denied':
        throw const AuthException('Authorization denied');
      default:
        throw AuthException('Device flow failed: ${data['error_description'] ?? error}');
    }
  }
}
```

`_fetchUserInfo()` is unchanged.

### 4. Notifier — `GitHubAuthNotifier` updates

`lib/features/onboarding/notifiers/github_auth_notifier.dart`:

Remove the existing `authenticate()` method. Add:

```dart
/// Requests a device code from GitHub, starts background polling for the
/// resulting user token, and returns the device code immediately so the
/// caller (the dialog) can display it. State transitions to
/// AsyncData(GitHubAccount) when polling completes.
Future<DeviceCodeResponse> startDeviceFlow() async {
  state = const AsyncLoading();
  final repo = await ref.read(githubServiceProvider.future);
  final code = await repo.requestDeviceCode();
  // Start polling in the background — don't await
  unawaited(_pollInBackground(repo, code));
  return code;
}

Future<void> _pollInBackground(GitHubRepository repo, DeviceCodeResponse code) async {
  state = await AsyncValue.guard(() => repo.pollForUserToken(code.deviceCode, code.interval));
}

/// Cancels in-flight polling. State returns to AsyncData(null).
/// Implemented by setting a cancellation flag the polling loop checks.
void cancelDeviceFlow() {
  _cancelled = true;
  state = const AsyncData(null);
}

bool _cancelled = false;
```

`signOut()` and `signInWithPat()` are unchanged.

The polling loop in the datasource needs to check the cancellation flag; this is plumbed by passing a cancellation token (or by exposing `cancelDeviceFlow()` on the repository that flips a flag the polling loop reads each iteration).

> Implementation note for the plan: cancellation can be implemented as a `Completer<void>` passed into `pollForUserToken` — the loop awaits `Future.any([Future.delayed(interval), cancelCompleter.future])` so cancellation breaks the wait immediately and a thrown `CancellationException` exits the loop cleanly.

### 5. New widget: `GitHubDeviceFlowDialog`

Location: `lib/features/onboarding/widgets/github_device_flow_dialog.dart`

```dart
class GitHubDeviceFlowDialog extends ConsumerStatefulWidget {
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

  @override
  Widget build(BuildContext context) {
    // Listen for auth state — close dialog when account is set
    ref.listen(gitHubAuthProvider, (prev, next) {
      next.whenData((account) {
        if (account != null) Navigator.of(context).pop();
      });
    });

    return AppDialog(
      icon: AppIcons.github,
      iconType: AppDialogIconType.teal,
      title: 'Sign in to GitHub',
      subtitle: _code == null
          ? 'Requesting code…'
          : 'Enter this code at github.com/login/device',
      content: _DeviceFlowContent(code: _code, initError: _initError),
      actions: [
        AppDialogAction.cancel(onPressed: () {
          ref.read(gitHubAuthProvider.notifier).cancelDeviceFlow();
          Navigator.of(context).pop();
        }),
      ],
    );
  }
}
```

The `_DeviceFlowContent` private widget renders:
- Big monospace code badge (e.g. `WDJB-MJHT`)
- "Open browser" button → `launchUrl(Uri.parse(code.verificationUri))`
- "Copy code" button → `Clipboard.setData(...)` (also auto-copied on init)
- Status line: "Waiting for authorization…" or error string

The dialog watches `gitHubAuthProvider` via `ref.listen`. When polling resolves to `AsyncData(GitHubAccount)`, the dialog dismisses itself. Errors during polling surface as `AsyncError` and the existing widget-level error handling on the auth screen displays them.

Per the project's Rule 1, the `Clipboard.setData(...)` and `launchUrl(...)` calls are explicitly permitted in widgets. No business-logic try/catch is needed.

### 6. Trigger — replace `repo.authenticate()` callsite

The "Sign in with GitHub" button currently calls `ref.read(gitHubAuthProvider.notifier).authenticate()`. Replace with:

```dart
await GitHubDeviceFlowDialog.show(context);
```

### 7. Cleanup of prior PKCE work

Files to delete (added in commits `1f77ede` / `7afe9ce` of this branch):
- `test/data/github/datasource/github_auth_datasource_pkce_test.dart` (PKCE tests no longer relevant)

The infrastructure files **stay** (still needed):
- `env.json.example` — still documents `GITHUB_CLIENT_ID`
- `.vscode/launch.json` — still passes `--dart-define-from-file=env.json`
- `.gitignore` entry for `env.json` — still correct

Files to clean up:
- Remove temporary `dLog` in `_exchangeCodeForToken` (the diagnostic added during debugging)

## Data flow

```
User taps "Sign in with GitHub"
  │
  ├─ GitHubDeviceFlowDialog.show(context)
  │     │
  │     ├─ initState → startDeviceFlow()
  │     │     ├─ POST /login/device/code → { user_code, verification_uri, device_code, interval }
  │     │     ├─ returns DeviceCodeResponse to dialog (synchronously after one network round-trip)
  │     │     └─ background: starts polling /login/oauth/access_token every `interval` seconds
  │     │
  │     ├─ dialog displays user_code, auto-copies to clipboard
  │     ├─ dialog watches gitHubAuthProvider
  │     │
  │     └─ user opens browser → pastes code → authorizes
  │
  ├─ Background polling
  │     ├─ authorization_pending → continue
  │     ├─ slow_down → increase interval, continue
  │     ├─ expired_token → AsyncError(AuthException)
  │     ├─ access_denied → AsyncError(AuthException)
  │     └─ access_token → store token, fetch /user → AsyncData(GitHubAccount)
  │
  └─ ref.listen on gitHubAuthProvider sees AsyncData(account) → Navigator.pop → dialog closes → user signed in
```

## Error handling

Failure modes and surfacing:

| Failure | Source | UI |
|---|---|---|
| Network error requesting device code | `requestDeviceCode()` throws | dialog shows inline error, user can close and retry |
| Polling network error | `pollForUserToken()` throws | `gitHubAuthProvider` becomes `AsyncError` → dialog closes, screen shows error snackbar via existing `ref.listen` pattern |
| `expired_token` | GitHub returns after `expires_in` elapses | `AuthException('Device code expired — please try signing in again')` |
| `access_denied` | User clicks Cancel in browser | `AuthException('Authorization denied')` |
| User clicks dialog Cancel | `cancelDeviceFlow()` | Polling loop exits via cancellation token, no error state |

## Security notes

- No `client_secret` is generated for the app; nothing to embed, nothing to leak.
- `client_id` is public information — `env.json` keeps it out of source so forks register their own GitHub App.
- The non-expiring access token is stored in `flutter_secure_storage` (encrypted at rest). Revocation is via github.com (user-side) or by deleting the local token via "Sign out".
- Device codes have a server-enforced TTL (~15 min default). Even if a `device_code` is intercepted in transit, it cannot be used after expiry.
- Polling respects `slow_down` to avoid GitHub rate-limiting.

## Testing strategy

- **Datasource unit tests:** mock the Dio response sequence. Cover:
  - `requestDeviceCode()` parses GitHub's response shape correctly
  - `pollForUserToken()` returns on `access_token`, retries on `authorization_pending`, increases interval on `slow_down`, throws `AuthException` on `expired_token` / `access_denied`
- **Notifier tests:** verify `startDeviceFlow()` returns the device code and `cancelDeviceFlow()` resets state
- **Dialog widget test:** verify mount triggers `startDeviceFlow`, code displays once received, Cancel button calls `cancelDeviceFlow` + pops the dialog
- The PAT flow tests stay as-is

The previous PKCE math test is deleted along with `generatePkce()`.
