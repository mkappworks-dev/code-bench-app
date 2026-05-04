# macOS Runner — Entitlements notes

## App Sandbox is intentionally disabled

Both `DebugProfile.entitlements` and `Release.entitlements` set
`com.apple.security.app-sandbox` to `false`. This is **deliberate** and
required by the feature set shipped in Phase 3:

- **`ActionRunnerService`** lets users define and run arbitrary shell
  commands against their projects (`flutter test`, `npm run build`,
  custom scripts). This cannot work under App Sandbox, which blocks
  arbitrary `fork`/`exec` and PATH resolution of helper binaries.
- **`GitService`** shells out to `git` for commit/push/pull/fetch. Under
  sandbox, `git` would fail to invoke credential helpers or SSH agents.
- **`IdeLaunchService`** calls `code`, `cursor`, and `open -a <app>` to
  launch external editors and terminals. Sandbox would require per-app
  temporary-exception entitlements for every supported tool.

## What this means in practice

The app runs with the invoking user's full privileges. Any command
injection bug, path-traversal, or RCE in Code Bench therefore has the
same blast radius as "run anything the user can run". Code touching
`Process.run`/`Process.start`, subprocess argument construction, or
external input parsing must be reviewed with that threat model in mind.

### Contributor rules

1. **Never set `runInShell: true`** on any `Process.run`/`Process.start`
   call. Arguments are passed as literal argv lists throughout the app,
   which prevents shell metacharacter injection. Enabling shell mode
   would turn currently-safe code into an injection vector the moment
   any argument is interpolated from user input.

2. **Never attach `LogInterceptor(requestHeader: true)`** to the Dio
   instance in `GitHubApiService`. The `Authorization` header contains
   the user's GitHub Personal Access Token.

3. **Do not re-enable App Sandbox** without first removing the features
   above (or re-architecting them through a separate privileged helper).
   A half-sandboxed app is worse than either extreme: it gives users a
   false sense of security while breaking core features.

## Distribution implications

- **Mac App Store:** Not eligible — the MAS requires App Sandbox.
- **Direct distribution:** OK, but requires Developer ID signing,
  hardened runtime, and notarization. Verify these are configured in
  `Runner.xcodeproj` / the release workflow before publishing a build.

## Local vs distribution signing

`Runner.xcodeproj` defaults the Release target to `Apple Development` +
Automatic signing so that `flutter build macos` works on developer machines
without a Developer ID certificate. This produces a build that **cannot be
notarized or distributed**.

For any distributable or CI release build, the following env vars must be set
(the release workflow sets these automatically):

```
FLUTTER_XCODE_CODE_SIGN_STYLE=Manual
FLUTTER_XCODE_CODE_SIGN_IDENTITY=Developer ID Application
```

Running `flutter build macos --release` locally without these vars yields an
`Apple Development`-signed artifact — fine for on-device testing, not for
distribution.

## MACOS_PROVISIONING_PROFILE secret

The full list of GitHub Actions secrets required to ship a release lives in
the top-level [README.md](../../README.md#required-github-actions-secrets).
This section explains the macOS-specific reason the
`MACOS_PROVISIONING_PROFILE` secret exists and how to regenerate it when
the underlying cert rotates or it gets revoked.

### Why it's needed

Xcode 14+ aborts pre-build with `"Runner" requires a provisioning profile`
whenever entitlements include `keychain-access-groups` — even for Developer
ID direct distribution, which historically didn't need a profile at all.
`flutter_secure_storage` v10+ requires that entitlement on macOS 15
Sequoia (which removed the legacy file-based keychain), so the profile
became a hard CI dependency.

The profile itself isn't a credential — it's a signed manifest that vouches
for the entitlements in the bundle. Apple regenerates it for free in the
Developer Portal whenever you need.

### Regenerating

1. Sign in at <https://developer.apple.com/account>.
2. **Certificates, Identifiers & Profiles → Identifiers** → confirm
   `app.benchlabs.CodeBench` exists. If not, register it as an App ID.
3. **Profiles → `+` (Add)**.
4. **Distribution** section → choose **Developer ID** → Continue.
5. **App ID** → choose `app.benchlabs.CodeBench` → Continue.
6. **Certificate** → select your active Developer ID Application
   certificate → Continue.
7. **Provisioning Profile Name:** `Code Bench Developer ID` — must match
   `FLUTTER_XCODE_PROVISIONING_PROFILE_SPECIFIER` in `build-and-publish.yml`.
   If you change the name here, change it in the workflow too.
8. **Generate → Download** → you get `Code_Bench_Developer_ID.provisionprofile`.
9. Base64-encode and copy to clipboard:
   ```
   base64 -i ~/Downloads/Code_Bench_Developer_ID.provisionprofile | pbcopy
   ```
10. GitHub repo → **Settings → Secrets and variables → Actions** → update
    (or create) `MACOS_PROVISIONING_PROFILE` with the clipboard contents.

The release workflow's `Install Developer ID provisioning profile` step
re-decodes the profile, prints its name/UUID/team for diagnostics, and
fails fast if the profile name doesn't match the expected value. That
makes profile-related CI breakage self-explanatory in the run log.
