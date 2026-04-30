# In-App Updates — Design Spec

**Date:** 2026-04-30
**Status:** Approved

---

## Overview

Code Bench checks GitHub Releases for new versions, shows a non-intrusive sidebar chip when one is found, and lets the user confirm a one-click download-and-install that replaces the running `.app` and relaunches.

---

## Decisions

| Question | Decision |
|---|---|
| Distribution channel | GitHub Releases (`.zip` of `.app`) |
| Install mechanism | Custom: GitHub API + Dio download + shell swap (no `auto_updater` package) |
| Check trigger | On launch + manual "Check now" in Settings › General |
| Update entry point | Rounded chip in sidebar, above Settings button |
| Icon | `LucideIcons.arrowDownToLine` (distinct from `LucideIcons.download` used for "apply diff") |
| Dialog chrome | Reuses `AppDialog` (`teal` icon type) |

---

## Architecture

Follows the existing dependency rule: **Widgets → Notifiers → Services → Repositories → Datasources → External**.

### New files

```
lib/
  data/
    update/
      datasource/
        update_datasource_dio.dart      # GitHub releases API check + Dio download
      models/
        update_info.dart                # @freezed UpdateInfo
        update_state.dart               # @freezed sealed UpdateState
      update_repository.dart            # abstract interface
      update_repository_impl.dart       # @riverpod impl

  services/
    update/
      update_service.dart               # version compare + install script (Process.run)

  features/
    project_sidebar/
      widgets/
        update_chip.dart                # sidebar chip — watches updateNotifier
        update_dialog.dart              # release notes + progress + install button

    settings/
      notifiers/
        update_notifier.dart            # Notifier<UpdateState>, keepAlive: true
        update_failure.dart             # @freezed sealed UpdateFailure
      widgets/
        update_section.dart             # Settings › General: version + manual check

  core/
    constants/
      update_constants.dart             # kGithubOwner, kGithubRepo, kUpdateAssetName
```

### Files modified (not created)

| File | Change |
|---|---|
| `lib/shell/widgets/app_lifecycle_observer.dart` | Call `checkForUpdates()` in `initState` |
| `lib/features/general/general_screen.dart` | Add `UpdateSection` at bottom |
| `lib/features/project_sidebar/project_sidebar.dart` | Add `UpdateChip` above Settings button |
| `lib/core/constants/app_icons.dart` | Add `arrowDownToLine` icon constant |

---

## Data Models

### `UpdateInfo`

```dart
@freezed
class UpdateInfo with _$UpdateInfo {
  const factory UpdateInfo({
    required String version,       // "1.2.0"
    required String releaseNotes,  // GitHub release body (markdown)
    required String downloadUrl,   // direct .zip asset URL
    required DateTime publishedAt,
  }) = _UpdateInfo;
}
```

### `UpdateState`

State machine owned by `UpdateNotifier`:

```
idle → checking → available(info) → downloading(progress) → installing → [app exits & relaunches]
                → upToDate
                → error(failure)
```

```dart
@freezed
sealed class UpdateState with _$UpdateState {
  const factory UpdateState.idle()                        = UpdateStateIdle;
  const factory UpdateState.checking()                    = UpdateStateChecking;
  const factory UpdateState.available(UpdateInfo info)    = UpdateStateAvailable;
  const factory UpdateState.downloading(double progress)  = UpdateStateDownloading;
  const factory UpdateState.installing()                  = UpdateStateInstalling;
  const factory UpdateState.upToDate()                    = UpdateStateUpToDate;
  const factory UpdateState.error(UpdateFailure failure)  = UpdateStateError;
}
```

### `UpdateFailure`

```dart
@freezed
sealed class UpdateFailure with _$UpdateFailure {
  const factory UpdateFailure.networkError([String? detail])    = UpdateNetworkError;
  const factory UpdateFailure.parseError([String? detail])      = UpdateParseError;
  const factory UpdateFailure.downloadFailed([String? detail])  = UpdateDownloadFailed;
  const factory UpdateFailure.installFailed([String? detail])   = UpdateInstallFailed;
  const factory UpdateFailure.unknown(Object error)             = UpdateUnknownError;
}
```

---

## Notifier

`UpdateNotifier extends Notifier<UpdateState>` with `keepAlive: true`. Owns the state machine and exposes three imperative methods:

```dart
Future<void> checkForUpdates()              // idle → checking → available/upToDate/error
Future<void> downloadAndInstall(UpdateInfo) // available → downloading → installing
void dismiss()                              // any → idle (chip reappears next launch)
```

No separate `UpdateActions` — the progress state (downloading %, installing spinner) makes `UpdateNotifier` itself the right owner rather than a fire-and-forget `AsyncNotifier<void>`.

---

## GitHub API

**Endpoint:** `GET https://api.github.com/repos/{owner}/{repo}/releases/latest`
No auth required for public repos. Uses existing `Dio` instance.

**Parsing:**
- `tag_name` → strip `v` prefix → semver compare
- `body` → release notes (rendered as plain text in v1; full markdown render is a follow-up)
- `assets[].browser_download_url` where `assets[].name == kUpdateAssetName`

**Version comparison** (no package needed):

```dart
bool isNewer(String latest, String current) {
  final l = latest.split('.').map(int.parse).toList();
  final c = current.split('.').map(int.parse).toList();
  for (var i = 0; i < 3; i++) {
    if (l[i] > c[i]) return true;
    if (l[i] < c[i]) return false;
  }
  return false;
}
```

---

## Install Mechanism

Release artifact: a `.zip` containing `Code Bench.app`, uploaded as a GitHub release asset named `CodeBench-macos.zip`.

**Install flow** (all `Process.run` / `dart:io` in `UpdateService`):

```
1. Dio downloads .zip to /tmp/cb-update-{version}.zip  (onReceiveProgress → UpdateState.downloading)
2. Process.run('unzip', ['-o', zipPath, '-d', extractDir])
3. Resolve current .app path:
     Platform.resolvedExecutable
     → /Applications/Code Bench.app/Contents/MacOS/code_bench_app
     → walk up 3 levels → /Applications/Code Bench.app
4. Write relaunch script to /tmp/cb_relaunch.sh:
     #!/bin/bash
     sleep 1
     rm -rf "$CURRENT_APP"
     mv "$NEW_APP" "$CURRENT_APP"
     open "$CURRENT_APP"
5. chmod +x /tmp/cb_relaunch.sh
6. Process.start('/bin/bash', ['/tmp/cb_relaunch.sh'])  — detached, no await
7. exit(0)  — current process quits; script runs 1 s later
```

**Error handling:** `ProcessException` caught in `UpdateService`, logged with `dLog`, rethrown as `UpdateFailure.installFailed`. The dialog surfaces this with an error message and a "Download manually" link that calls `launchUrl` to open the GitHub releases page.

---

## Config Constants

`lib/core/constants/update_constants.dart`:

```dart
const kGithubOwner     = 'mkappworks-dev';
const kGithubRepo      = 'code-bench-app';   // confirm slug before implementation
const kUpdateAssetName = 'CodeBench-macos.zip';
```

---

## UI

### Sidebar chip (`update_chip.dart`)

Appears above the Settings button when `UpdateState` is `available`, `downloading`, or `installing`. Tapping opens `UpdateDialog`.

```
┌─────────────────────────────┐
│  ↓  v1.2.0 available      › │  ← arrowDownToLine icon, teal border/text
└─────────────────────────────┘
⚙  Settings
```

Uses teal accent tokens: `accentTintLight` bg, `accentBorderTeal` border, `accentLight` text.

### Update dialog (`update_dialog.dart`)

Wraps `AppDialog(icon: AppIcons.arrowDownToLine, iconType: AppDialogIconType.teal)`.

Content widget switches on `UpdateState`:

| State | Content |
|---|---|
| `available` | Version badge row + release notes box |
| `downloading(progress)` | Version badge row + progress bar (teal gradient) + percentage |
| `installing` | Version badge row + spinner + "Replacing app bundle…" |
| `error` | Error message + "Download manually" link |

Actions (footer):
- **Later** — ghost button, calls `dismiss()`, dialog closes
- **Download & Install** — primary teal gradient button; disabled (`opacity: 0.45`) during `downloading` and `installing`

### Settings section (`update_section.dart`)

Added at the bottom of `GeneralScreen`. Shows:
- **Current version** — from `PackageInfo.version` + `buildNumber`
- **Last checked** — stored in `SharedPreferences`, formatted as "Today at HH:mm" or date
- **Check now** — ghost button, calls `checkForUpdates()`, shows a brief "Checking…" label inline

---

## On-Launch Check

`AppLifecycleObserver.initState()` calls:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  ref.read(updateNotifierProvider.notifier).checkForUpdates();
});
```

The check is fire-and-forget. Network failures are swallowed silently (state → `error` but chip does not appear for network failures on launch — only for a confirmed available update). The chip only appears when `state is UpdateStateAvailable`.

---

## Out of Scope (v1)

- Windows / Linux update support (shell swap is macOS-only; add later)
- Code-signature verification of downloaded `.zip`
- Full markdown rendering of release notes
- Automatic periodic re-check while app is running
- Rollback on failed install
