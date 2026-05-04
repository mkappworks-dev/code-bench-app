# Update: Ready-to-Restart Flow — Design Spec

**Date:** 2026-05-04  
**Branch:** `feat/2026-05-04-update-ready-to-restart`  
**Scope:** Post-install UX — "Restart Now / Restart Later" dialog state + deferred-restart sidebar chip

---

## Problem

The current update flow calls `exit(0)` immediately after the install script succeeds — the app relaunches without giving the user any choice. There is no way to defer the relaunch, and no visible indicator if the user happens to hide the dialog during download.

---

## Chosen Approach

**Install now, relaunch later.**

The install script (bundle replacement + codesign verify + sentinel write) runs immediately when the download finishes. Once it succeeds, the app transitions to a new `UpdateStateReadyToRestart` state instead of calling `exit(0)`. The user then chooses:

- **Restart Now** — triggers a minimal relaunch script (`open "$APP" && exit 0`) immediately.
- **Restart Later** — dismisses the dialog; a persistent green chip appears in the sidebar footer.
- **Quit the app** — because the bundle is already replaced on disk, the next manual launch automatically runs the new version. No special close-handler is needed.

---

## State Machine

### New state added

```dart
// lib/features/update/notifiers/update_state.dart
UpdateStateReadyToRestart(UpdateInfo info)
```

### Full progression

```
Idle → Checking → Available → Downloading → Installing → ReadyToRestart
```

- `Installing` = bundle replacement in progress (spinner, "Replacing app bundle…")
- `ReadyToRestart` = bundle replaced, old process still running, waiting for user

### Error path (unchanged)

Any failure during `applyUpdate` transitions to `UpdateStateError` with the existing failure types.

---

## Datasource Split

**File:** `lib/data/update/datasource/update_install_datasource_process.dart`

The current single `installUpdate(UpdateInfo)` method is split into two:

### `applyUpdate(UpdateInfo info) → Future<void>`

Runs the install bash script up to and including:
1. Back up old bundle: `mv "$APP" "$APP.old"`
2. Copy new bundle: `ditto "$SRC" "$APP"`
3. Codesign verify: `codesign --verify --deep --strict "$APP"`
4. Write success sentinel to Application Support
5. Clean up temp directories and downloaded zip

Does **not** call `open "$APP"` or `exit(0)`. Returns normally on success, throws `UpdateInstallFailed` on failure (existing type, no change).

### `relaunchApp() → Never`

Runs a small second script:
```bash
open "$APP"
exit 0
```

Spawned detached. Parent calls `exit(0)` after spawn. This is the only path that terminates the running process.

---

## Notifier Changes

**File:** `lib/features/update/notifiers/update_notifier.dart`

### `downloadAndInstall(UpdateInfo info)`

Existing state progression: `downloading(progress) → installing`

After the split, on install success: transitions to `ReadyToRestart(info)` instead of calling the combined script.

```dart
// After applyUpdate() returns without throwing:
state = AsyncData(UpdateStateReadyToRestart(info));
```

Errors still propagate to `UpdateStateError` via the existing `_asFailure` mapper.

### New method: `restartNow()`

```dart
Future<void> restartNow() async {
  state = const AsyncLoading();
  await _installDatasource.relaunchApp(); // never returns
}
```

Called when the user taps "Restart Now" in the dialog or chip.

### `dismiss()`

Behaviour unchanged. When called from `ReadyToRestart`, it does **not** reset state to `Idle` — it leaves the provider in `ReadyToRestart` so the chip remains visible. The dialog simply pops.

> `dismiss()` resets to `Idle` only from `Available` and `Error` states (existing behaviour). From `ReadyToRestart` it is a no-op on the provider; the caller just pops the route.

---

## Dialog Changes

**File:** `lib/features/update/widgets/update_dialog.dart`

### Title / subtitle switch

```dart
UpdateStateReadyToRestart() => 'Ready to restart',      // title
UpdateStateReadyToRestart(:final info) =>
    'v${info.version} is installed — relaunch to activate', // subtitle
```

### Content area

New `_ReadyRow` widget rendered when state is `UpdateStateReadyToRestart`:

- Green filled circle icon with a checkmark (using `AppColors.successGreen` / existing success token)
- Text: `"App bundle updated. Restart to run the new version."`

Replaces the `_InstallingRow` in the exhaustive content `switch`.

### Action buttons

| State | Left (cancel-style) | Right (primary) |
|---|---|---|
| `ReadyToRestart` | `Restart Later` — pops dialog, leaves provider in `ReadyToRestart` | `Restart Now` — calls `restartNow()` |

The `Restart Later` button calls `Navigator.of(context).pop()` directly (no `dismiss()` call, since state must stay `ReadyToRestart`).

The `Restart Now` button calls `ref.read(updateProvider.notifier).restartNow()`.

### `barrierDismissible`

Remains `false`. `Restart Later` is the explicit dismissal path.

### Dialog icon

`ReadyToRestart` uses a new `AppDialogIconType.success` variant. This variant must be added to the `AppDialogIconType` enum in `lib/core/widgets/app_dialog.dart` and mapped to `c.success` / `c.successTintBg` in the icon background/foreground switch (parallel to the existing `teal` and `destructive` arms).

---

## Chip Changes

**File:** `lib/features/update/widgets/update_chip.dart`

New arm in the state-mapping switch:

```dart
UpdateStateReadyToRestart(:final info) => (info, 'Restart to update', false),
```

The chip uses existing green color tokens (`c.successTintBg` for background, `c.success` for icon/text) instead of the existing teal tokens. A filled green dot (using `c.success`) replaces the update icon to signal "ready, not pending." A border color `c.success.withValues(alpha: 0.3)` is used inline since no `successBorder` token exists.

Tapping the chip calls `UpdateDialog.show(context, info)`. Since the provider is in `ReadyToRestart`, the dialog opens directly in that state showing just the two buttons.

---

## Color Tokens

`AppColors` already has `success` (`0xFF4EC9B0`), `successTintBg`, and `successBadgeBg`. No new tokens are needed. The chip border uses `c.success.withValues(alpha: 0.3)` inline rather than a dedicated token.

---

## "Close App" Behaviour

No special handling required. After `applyUpdate()` succeeds:

- The new `.app` bundle is already on disk at the standard install path.
- If the user quits the app without clicking "Restart Now", the OS will launch the new binary on the next open.
- The `last-update-status.json` sentinel written during `applyUpdate()` will be read on next launch and cleared (existing mechanism, no change).

---

## Files Changed

| File | Change |
|---|---|
| `lib/features/update/notifiers/update_state.dart` | Add `UpdateStateReadyToRestart(UpdateInfo info)` |
| `lib/data/update/datasource/update_install_datasource_process.dart` | Split `installUpdate` → `applyUpdate` + `relaunchApp` |
| `lib/features/update/notifiers/update_notifier.dart` | Transition to `ReadyToRestart` after apply; add `restartNow()`; adjust `dismiss()` |
| `lib/features/update/widgets/update_dialog.dart` | New title/subtitle arms, `_ReadyRow`, updated action buttons for `ReadyToRestart` |
| `lib/features/update/widgets/update_chip.dart` | New `UpdateStateReadyToRestart` arm with green styling |
| `lib/core/widgets/app_dialog.dart` | Add `AppDialogIconType.success` variant |

---

## Out of Scope

- Persisting the "ready to restart" state across cold launches (if the user quits while in `ReadyToRestart`, the next launch starts at `Idle` and auto-checks for updates as usual — this is acceptable since the binary is already updated).
- Any notification or OS-level badge.
- Windows/Linux — this entire update flow is macOS-only.
