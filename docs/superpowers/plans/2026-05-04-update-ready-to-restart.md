# Update: Ready-to-Restart Flow — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After the bundle swap succeeds, show a "Ready to restart" dialog state with "Restart Now / Restart Later" buttons instead of immediately relaunching.

**Architecture:** Split the existing atomic `swapAndRelaunch` datasource method into `applyUpdate` (synchronous bundle swap, no exit) and `relaunchApp` (open + exit). A new `UpdateStateReadyToRestart` state holds the gap. The chip shows a persistent green "Restart to update" indicator when the user defers.

**Tech Stack:** Flutter/Dart, Riverpod (code-gen), freezed, macOS bash scripts via `Process.run`/`Process.start`

---

## Files Changed

| File | Change |
|---|---|
| `lib/features/update/notifiers/update_state.dart` | Add `readyToRestart(UpdateInfo)` factory |
| `lib/features/update/notifiers/update_state.freezed.dart` | Regenerated |
| `lib/data/update/datasource/update_install_datasource.dart` | Add `applyUpdate` + `relaunchApp`; remove `swapAndRelaunch` |
| `lib/data/update/datasource/update_install_datasource_process.dart` | Implement `applyUpdate` + `relaunchApp`; add `_applyScript`; remove `swapAndRelaunch` |
| `lib/services/update/update_service.dart` | Rename `installUpdate` → `applyUpdate`; add `relaunchApp()` |
| `lib/features/update/notifiers/update_notifier.dart` | `downloadAndInstall` → transitions to `ReadyToRestart`; add `restartNow()`; guard `checkForUpdates` |
| `lib/features/update/widgets/update_dialog.dart` | New title/subtitle arms; `_ReadyRow`; updated action buttons |
| `lib/features/update/widgets/update_chip.dart` | New `ReadyToRestart` arm with green styling |
| `test/features/update/update_notifier_test.dart` | New — notifier tests |

---

## Task 1: Add `UpdateStateReadyToRestart` to the state machine

**Files:**
- Modify: `lib/features/update/notifiers/update_state.dart`
- Regenerate: `lib/features/update/notifiers/update_state.freezed.dart`

- [ ] **Step 1: Add the new factory**

  Open `lib/features/update/notifiers/update_state.dart`. Add one line after `installing`:

  ```dart
  @freezed
  sealed class UpdateState with _$UpdateState {
    const factory UpdateState.idle() = UpdateStateIdle;
    const factory UpdateState.checking() = UpdateStateChecking;
    const factory UpdateState.available(UpdateInfo info) = UpdateStateAvailable;
    const factory UpdateState.downloading(UpdateInfo info, double progress) = UpdateStateDownloading;
    const factory UpdateState.installing(UpdateInfo info) = UpdateStateInstalling;
    const factory UpdateState.readyToRestart(UpdateInfo info) = UpdateStateReadyToRestart;  // NEW
    const factory UpdateState.upToDate() = UpdateStateUpToDate;
    const factory UpdateState.error(UpdateFailure failure) = UpdateStateError;
  }
  ```

- [ ] **Step 2: Regenerate freezed**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: no errors, `update_state.freezed.dart` updated.

- [ ] **Step 3: Verify it compiles**

  ```bash
  flutter analyze lib/features/update/notifiers/update_state.dart
  ```

  Expected: no issues.

- [ ] **Step 4: Commit**

  ```bash
  git add lib/features/update/notifiers/update_state.dart \
          lib/features/update/notifiers/update_state.freezed.dart
  git commit -m "feat(update): add UpdateStateReadyToRestart to state machine"
  ```

---

## Task 2: Add `applyUpdate` + `relaunchApp` to the datasource interface; remove `swapAndRelaunch`

**Files:**
- Modify: `lib/data/update/datasource/update_install_datasource.dart`

- [ ] **Step 1: Replace `swapAndRelaunch` with the two new methods**

  Replace the `swapAndRelaunch` declaration (lines 44–51) and its doc comment with:

  ```dart
  /// Runs the bundle-swap script synchronously: backs up the current bundle,
  /// ditto-copies the new one in, optionally re-verifies codesign, writes the
  /// status sentinel, and cleans up temp files. Returns normally on success.
  /// Throws [UpdateInstallException] on any failure.
  ///
  /// Does NOT relaunch — call [relaunchApp] when the user is ready.
  Future<void> applyUpdate({
    required String currentAppPath,
    required String newAppPath,
    required String extractDir,
    required String zipPath,
    required String statusSentinelPath,
    required bool enforceSignature,
  });

  /// Opens [appPath] and exits the current process with code 0.
  /// Never returns normally.
  Future<Never> relaunchApp({required String appPath});
  ```

- [ ] **Step 2: Verify the interface compiles**

  ```bash
  flutter analyze lib/data/update/datasource/update_install_datasource.dart
  ```

  Expected: error about `UpdateInstallDatasourceProcess` not implementing the new methods (that's correct — we fix it in Task 3).

---

## Task 3: Implement `applyUpdate` + `relaunchApp` in the process datasource

**Files:**
- Modify: `lib/data/update/datasource/update_install_datasource_process.dart`

- [ ] **Step 1: Replace `swapAndRelaunch` with `applyUpdate` and `relaunchApp`**

  Remove the entire `swapAndRelaunch` method (lines 108–141) and the `_relaunchScript` constant (lines 154–221). Replace with:

  ```dart
  @override
  Future<void> applyUpdate({
    required String currentAppPath,
    required String newAppPath,
    required String extractDir,
    required String zipPath,
    required String statusSentinelPath,
    required bool enforceSignature,
  }) async {
    final scriptDir = await Directory.systemTemp.createTemp('cb-apply-');
    final scriptPath = p.join(scriptDir.path, 'cb_apply.sh');
    try {
      await File(scriptPath).writeAsString(_applyScript);
      final chmod = await Process.run('chmod', ['+x', scriptPath]);
      if (chmod.exitCode != 0) {
        throw UpdateInstallException('Could not make apply script executable: ${chmod.stderr}');
      }
      final result = await Process.run('/bin/bash', [
        scriptPath,
        currentAppPath,
        newAppPath,
        extractDir,
        zipPath,
        statusSentinelPath,
        enforceSignature ? '1' : '0',
      ]);
      if (result.exitCode != 0) {
        dLog('[UpdateInstallDatasource] apply script exited ${result.exitCode}: ${result.stderr}');
        throw UpdateInstallException('Bundle swap failed (exit ${result.exitCode}): ${result.stderr}');
      }
    } finally {
      try {
        Directory(scriptDir.path).deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  @override
  Future<Never> relaunchApp({required String appPath}) async {
    await Process.start('open', [appPath], mode: ProcessStartMode.detached);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    exit(0);
  }

  static const _applyScript = r'''#!/bin/bash
  # Args: $1=appPath $2=srcAppPath $3=extractDir $4=zipPath
  #       $5=statusPath $6=enforceSignature(0|1)
  #
  # Why -u alone, not -eu: every fallible step is explicitly checked with
  # `if ! <cmd>; then ... fi` and the failure-path branches restore $APP.old
  # before exiting. Adding -e would exit before those restores can run.
  set -u
  APP="$1"; SRC="$2"; EXTRACT_DIR="$3"; ZIP="$4"
  STATUS="$5"; VERIFY="$6"

  write_status() {
    mkdir -p "$(dirname "$STATUS")" 2>/dev/null || true
    printf '{"status":"%s","detail":"%s","timestamp":"%s"}\n' \
      "$1" "$2" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$STATUS"
  }

  restore_if_needed() {
    if [ -d "$APP.old" ] && [ ! -d "$APP" ]; then
      mv "$APP.old" "$APP" 2>/dev/null || true
    fi
  }

  cleanup() {
    rm -rf "$EXTRACT_DIR" 2>/dev/null || true
    rm -f "$ZIP" 2>/dev/null || true
  }

  trap 'restore_if_needed; write_status "failed" "interrupted"; cleanup; exit 1' INT TERM

  # 1. Back up the running bundle
  if ! mv "$APP" "$APP.old"; then
    write_status "failed" "backup-failed"
    cleanup
    exit 2
  fi

  # 2. Copy the new bundle into place (preserves codesign metadata)
  if ! ditto "$SRC" "$APP"; then
    rm -rf "$APP" 2>/dev/null || true
    mv "$APP.old" "$APP" 2>/dev/null || true
    write_status "failed" "ditto-failed"
    cleanup
    exit 3
  fi

  # 3. Defense-in-depth: re-verify codesign of the installed bundle
  if [ "$VERIFY" = "1" ]; then
    if ! codesign --verify --deep --strict "$APP" 2>/dev/null; then
      rm -rf "$APP"
      mv "$APP.old" "$APP" 2>/dev/null || true
      write_status "failed" "post-install-codesign"
      cleanup
      exit 4
    fi
  fi

  # Success
  rm -rf "$APP.old" 2>/dev/null || true
  write_status "ok" ""
  cleanup
  exit 0
  ''';
  ```

- [ ] **Step 2: Verify it compiles**

  ```bash
  flutter analyze lib/data/update/datasource/update_install_datasource_process.dart
  ```

  Expected: no issues.

- [ ] **Step 3: Commit**

  ```bash
  git add lib/data/update/datasource/update_install_datasource.dart \
          lib/data/update/datasource/update_install_datasource_process.dart
  git commit -m "feat(update): split swapAndRelaunch into applyUpdate + relaunchApp"
  ```

---

## Task 4: Update `UpdateService` — rename `installUpdate` → `applyUpdate`; add `relaunchApp`

**Files:**
- Modify: `lib/services/update/update_service.dart`

- [ ] **Step 1: Rename `installUpdate` to `applyUpdate` and update its internals**

  Replace the `installUpdate` method (lines 61–111) with `applyUpdate`. Change only:
  1. Method name: `installUpdate` → `applyUpdate`
  2. The `_installDs.swapAndRelaunch(...)` call → `_installDs.applyUpdate(...)`
  3. Remove the doc comment line "Never returns normally on success"

  The full replacement (doc comment through closing brace):

  ```dart
  /// Verifies the downloaded bundle's authenticity and swaps it in for the
  /// running install. Returns normally on success — call [relaunchApp] to
  /// restart into the new version.
  Future<void> applyUpdate(String zipPath) async {
    final appPath = _installDs.currentAppPath();
    _assertNotDevBuild(appPath);
    final extractDir = await _installDs.createExtractDir();
    try {
      await _installDs.extractZip(zipPath: zipPath, destDir: extractDir);
      final extractedAppPath = await _installDs.resolveExtractedAppPath(extractDir);

      final currentTeamId = await _installDs.readTeamId(appPath);
      final downloadedTeamId = await _installDs.readTeamId(extractedAppPath);
      if (currentTeamId != downloadedTeamId) {
        sLog('[UpdateService] Team ID mismatch: current=$currentTeamId downloaded=$downloadedTeamId');
        throw const UpdateInstallException('Downloaded bundle Team ID does not match current install.');
      }
      final enforceSignature = currentTeamId != null;

      if (enforceSignature) {
        await _installDs.verifyCodesign(extractedAppPath);
        await _installDs.assessGatekeeper(extractedAppPath);
      } else {
        dLog('[UpdateService] Current bundle is unsigned — skipping codesign/spctl checks.');
      }

      sLog(
        '[UpdateService] swapping bundle: $appPath ← $extractedAppPath '
        '(team=${currentTeamId ?? "unsigned"})',
      );

      final statusPath = await _statusDs.sentinelPath();
      await _installDs.applyUpdate(
        currentAppPath: appPath,
        newAppPath: extractedAppPath,
        extractDir: extractDir,
        zipPath: zipPath,
        statusSentinelPath: statusPath,
        enforceSignature: enforceSignature,
      );
    } catch (e, st) {
      _installDs.cleanupExtractDir(extractDir);
      if (e is UpdateException) rethrow;
      dLog('[UpdateService] applyUpdate unexpected error: ${e.runtimeType}: $e\n$st');
      Error.throwWithStackTrace(UpdateInstallException('Install failed: ${e.runtimeType}: $e'), st);
    }
  }
  ```

- [ ] **Step 2: Add `relaunchApp` method to `UpdateService`**

  Add this method immediately after `applyUpdate`:

  ```dart
  /// Relaunches the installed app bundle and exits the current process.
  /// Never returns normally.
  Future<Never> relaunchApp() async {
    final appPath = _installDs.currentAppPath();
    return _installDs.relaunchApp(appPath: appPath);
  }
  ```

- [ ] **Step 3: Verify the service compiles**

  ```bash
  flutter analyze lib/services/update/update_service.dart
  ```

  Expected: no issues.

- [ ] **Step 4: Run existing tests to confirm nothing broke**

  ```bash
  flutter test test/services/update/update_service_test.dart
  ```

  Expected: all 6 `isNewer` tests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/services/update/update_service.dart
  git commit -m "feat(update): rename installUpdate→applyUpdate; add relaunchApp to service"
  ```

---

## Task 5: Update `UpdateNotifier` + write notifier tests

**Files:**
- Modify: `lib/features/update/notifiers/update_notifier.dart`
- Create: `test/features/update/update_notifier_test.dart`

- [ ] **Step 1: Write the failing tests first**

  Create `test/features/update/update_notifier_test.dart`:

  ```dart
  // test/features/update/update_notifier_test.dart
  import 'dart:async';

  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';

  import 'package:code_bench_app/data/update/models/update_info.dart';
  import 'package:code_bench_app/data/update/models/update_install_status.dart';
  import 'package:code_bench_app/data/update/update_exception.dart';
  import 'package:code_bench_app/features/update/notifiers/update_failure.dart';
  import 'package:code_bench_app/features/update/notifiers/update_notifier.dart';
  import 'package:code_bench_app/features/update/notifiers/update_state.dart';
  import 'package:code_bench_app/services/update/update_service.dart';

  // ── Fake UpdateService ────────────────────────────────────────────────────────

  class _FakeUpdateService extends Fake implements UpdateService {
    Object? applyError;       // set to UpdateInstallException to simulate failure
    bool relaunchCalled = false;

    @override
    Future<UpdateInfo?> checkForUpdate() async => null;

    @override
    Future<String> downloadUpdate({
      required UpdateInfo info,
      required void Function(double) onProgress,
    }) async => '/tmp/fake.zip';

    @override
    Future<void> applyUpdate(String zipPath) async {
      if (applyError != null) throw applyError!;
    }

    @override
    Future<Never> relaunchApp() async {
      relaunchCalled = true;
      // Never completes — mirrors production behaviour (process would exit).
      await Completer<Never>().future;
      throw StateError('unreachable');
    }

    @override
    Future<UpdateInstallStatus?> readLastInstallStatus() async => null;

    @override
    Future<void> clearLastInstallStatus() async {}
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  final _kInfo = UpdateInfo(
    version: '9.9.9',
    downloadUrl: 'https://example.com/update.zip',
    releaseNotes: '',
  );

  ProviderContainer _makeContainer(_FakeUpdateService fake) {
    final c = ProviderContainer(
      overrides: [updateServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(c.dispose);
    return c;
  }

  void main() {
    late _FakeUpdateService fake;

    setUp(() => fake = _FakeUpdateService());

    // ── downloadAndInstall → ReadyToRestart ───────────────────────────────────

    group('downloadAndInstall', () {
      test('transitions to ReadyToRestart on success', () async {
        final c = _makeContainer(fake);
        await c.read(updateProvider.notifier).downloadAndInstall(_kInfo);
        expect(c.read(updateProvider), isA<UpdateStateReadyToRestart>());
        final s = c.read(updateProvider) as UpdateStateReadyToRestart;
        expect(s.info.version, equals('9.9.9'));
      });

      test('transitions to error when applyUpdate throws UpdateInstallException', () async {
        fake.applyError = const UpdateInstallException('ditto failed');
        final c = _makeContainer(fake);
        await c.read(updateProvider.notifier).downloadAndInstall(_kInfo);
        expect(c.read(updateProvider), isA<UpdateStateError>());
        final err = (c.read(updateProvider) as UpdateStateError).failure;
        expect(err, isA<UpdateInstallFailed>());
      });
    });

    // ── restartNow ────────────────────────────────────────────────────────────

    group('restartNow', () {
      test('calls relaunchApp on the service', () async {
        final c = _makeContainer(fake);
        // Don't await — relaunchApp never completes in the fake.
        unawaited(c.read(updateProvider.notifier).restartNow());
        // Pump microtasks so the call reaches the fake.
        await Future<void>.microtask(() {});
        expect(fake.relaunchCalled, isTrue);
      });
    });

    // ── checkForUpdates guard ─────────────────────────────────────────────────

    group('checkForUpdates guard', () {
      test('skips check when state is ReadyToRestart', () async {
        final c = _makeContainer(fake);
        // Put notifier into ReadyToRestart state first.
        await c.read(updateProvider.notifier).downloadAndInstall(_kInfo);
        expect(c.read(updateProvider), isA<UpdateStateReadyToRestart>());
        // checkForUpdates should be a no-op now.
        await c.read(updateProvider.notifier).checkForUpdates();
        expect(c.read(updateProvider), isA<UpdateStateReadyToRestart>());
      });
    });
  }
  ```

- [ ] **Step 2: Run tests to confirm they fail**

  ```bash
  flutter test test/features/update/update_notifier_test.dart
  ```

  Expected: compilation errors (methods don't exist yet) or test failures.

- [ ] **Step 3: Update `downloadAndInstall` in `update_notifier.dart`**

  Replace the `downloadAndInstall` method body. Change only the install call and success transition:

  ```dart
  Future<void> downloadAndInstall(UpdateInfo info) async {
    state = UpdateState.downloading(info, 0);
    try {
      final zipPath = await ref
          .read(updateServiceProvider)
          .downloadUpdate(info: info, onProgress: (progress) => state = UpdateState.downloading(info, progress));
      state = UpdateState.installing(info);
      await ref.read(updateServiceProvider).applyUpdate(zipPath);
      state = UpdateState.readyToRestart(info);
    } on UpdateDownloadException catch (e, st) {
      dLog('[UpdateNotifier] download failed: $e\n$st');
      state = UpdateState.error(UpdateFailure.downloadFailed(e.message));
    } on UpdateInstallException catch (e, st) {
      dLog('[UpdateNotifier] install failed: $e\n$st');
      state = UpdateState.error(UpdateFailure.installFailed(e.message));
    } catch (e, st) {
      dLog('[UpdateNotifier] downloadAndInstall failed: $e\n$st');
      state = UpdateState.error(_asFailure(e));
    }
  }
  ```

- [ ] **Step 4: Add `restartNow()` method to `UpdateNotifier`**

  Add immediately after `dismiss()`:

  ```dart
  Future<void> restartNow() async {
    try {
      await ref.read(updateServiceProvider).relaunchApp();
      // Never reaches here in production — process exits inside relaunchApp.
    } catch (e, st) {
      dLog('[UpdateNotifier] restartNow failed: $e\n$st');
      state = UpdateState.error(_asFailure(e));
    }
  }
  ```

- [ ] **Step 5: Guard `checkForUpdates` against `ReadyToRestart`**

  In `checkForUpdates`, update the guard condition at the top of the method:

  ```dart
  if (state is UpdateStateChecking ||
      state is UpdateStateDownloading ||
      state is UpdateStateInstalling ||
      state is UpdateStateReadyToRestart) {
    dLog('[UpdateNotifier] checkForUpdates skipped — busy in ${state.runtimeType}');
    return;
  }
  ```

- [ ] **Step 6: Run tests to confirm they pass**

  ```bash
  flutter test test/features/update/update_notifier_test.dart
  ```

  Expected: all 4 tests pass.

- [ ] **Step 7: Run the full test suite**

  ```bash
  flutter test
  ```

  Expected: all tests pass.

- [ ] **Step 8: Commit**

  ```bash
  git add lib/features/update/notifiers/update_notifier.dart \
          test/features/update/update_notifier_test.dart
  git commit -m "feat(update): transition to ReadyToRestart after apply; add restartNow()"
  ```

---

## Task 6: Update the dialog — "Ready to restart" state

**Files:**
- Modify: `lib/features/update/widgets/update_dialog.dart`

- [ ] **Step 1: Add `ReadyToRestart` arms to the `title` and `subtitle` switches**

  In `_UpdateDialogState.build()`, update `title` and `subtitle`:

  ```dart
  final title = switch (updateState) {
    UpdateStateDownloading() => 'Downloading…',
    UpdateStateInstalling() => 'Installing…',
    UpdateStateReadyToRestart() => 'Ready to restart',          // NEW
    UpdateStateError() => 'Update Failed',
    _ => 'Update Available',
  };

  final subtitle = switch (updateState) {
    UpdateStateDownloading(:final progress) => 'Downloading… ${(progress * 100).round()}%',
    UpdateStateInstalling() => 'The app will restart shortly',
    UpdateStateReadyToRestart(:final info) =>
        'v${info.version} is installed — relaunch to activate', // NEW
    UpdateStateError() => 'Something went wrong',
    _ => 'Code Bench ${widget.info.version} is ready',
  };
  ```

- [ ] **Step 2: Replace the `actions:` list to handle `ReadyToRestart`**

  Replace the current `actions:` parameter in the `AppDialog(...)` call:

  ```dart
  actions: updateState is UpdateStateReadyToRestart
      ? [
          AppDialogAction.cancel(
            label: 'Restart Later',
            onPressed: Navigator.of(context).pop,
          ),
          AppDialogAction.primary(
            label: 'Restart Now',
            onPressed: () => unawaited(
              ref.read(updateProvider.notifier).restartNow(),
            ),
          ),
        ]
      : [
          AppDialogAction.cancel(
            label: busy ? 'Hide' : 'Cancel',
            onPressed: busy
                ? Navigator.of(context).pop
                : () {
                    ref.read(updateProvider.notifier).dismiss();
                    Navigator.of(context).pop();
                  },
          ),
          AppDialogAction.primary(
            label: 'Download & Install',
            onPressed: switch (updateState) {
              UpdateStateAvailable() ||
              UpdateStateError() => () => unawaited(
                  ref.read(updateProvider.notifier).downloadAndInstall(widget.info),
                ),
              _ => null,
            },
          ),
        ],
  ```

- [ ] **Step 3: Add `_ReadyRow` widget and wire it into `_DialogContent`**

  Add after `_InstallingRow`:

  ```dart
  class _ReadyRow extends StatelessWidget {
    const _ReadyRow();

    @override
    Widget build(BuildContext context) {
      final c = AppColors.of(context);
      return Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: c.successTintBg,
              shape: BoxShape.circle,
              border: Border.all(color: c.success.withValues(alpha: 0.3)),
            ),
            child: Icon(AppIcons.check, size: 9, color: c.success),
          ),
          const SizedBox(width: 10),
          Text(
            'App bundle updated. Restart to run the new version.',
            style: TextStyle(color: c.textSecondary, fontSize: 11),
          ),
        ],
      );
    }
  }
  ```

  In `_DialogContent.build()`, add `UpdateStateReadyToRestart` to the content switch:

  ```dart
  switch (updateState) {
    UpdateStateDownloading(:final progress) => _ProgressBar(progress: progress),
    UpdateStateInstalling() => const _InstallingRow(),
    UpdateStateReadyToRestart() => const _ReadyRow(),                          // NEW
    UpdateStateError(:final failure) => _ErrorRow(failure: failure, info: info),
    UpdateStateIdle() ||
    UpdateStateChecking() ||
    UpdateStateAvailable() ||
    UpdateStateUpToDate() => _ReleaseNotes(notes: info.releaseNotes),
  },
  ```

- [ ] **Step 4: Analyze for compile errors**

  ```bash
  flutter analyze lib/features/update/widgets/update_dialog.dart
  ```

  Expected: no issues. If there are exhaustiveness errors on the state switch, add the missing cases.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/update/widgets/update_dialog.dart
  git commit -m "feat(update): add Ready to Restart dialog state with Restart Now/Later buttons"
  ```

---

## Task 7: Update the chip — "Restart to update" arm with green styling

**Files:**
- Modify: `lib/features/update/widgets/update_chip.dart`

- [ ] **Step 1: Add `UpdateStateReadyToRestart` to the state-mapping switch**

  In `_UpdateChipState.build()`, update the switch:

  ```dart
  final (info, label, showChevron) = switch (updateState) {
    UpdateStateAvailable(:final info) => (info, 'v${info.version} available', true),
    UpdateStateDownloading(:final info, :final progress) => (info, 'Downloading ${(progress * 100).round()}%', false),
    UpdateStateInstalling(:final info) => (info, 'Installing…', false),
    UpdateStateReadyToRestart(:final info) => (info, 'Restart to update', false), // NEW
    _ => (null, null, false),
  };
  ```

- [ ] **Step 2: Apply green styling when state is `ReadyToRestart`**

  Replace the hardcoded teal color references in the `AnimatedContainer` and `Icon` with state-aware values:

  ```dart
  final isReady = updateState is UpdateStateReadyToRestart;

  // …inside GestureDetector > AnimatedContainer:
  decoration: BoxDecoration(
    color: _hovered
        ? (isReady ? c.success.withValues(alpha: 0.15) : c.accentTintMid)
        : (isReady ? c.successTintBg : c.accentTintLight),
    border: Border.all(
      color: isReady ? c.success.withValues(alpha: 0.3) : c.accentBorderTeal,
    ),
    borderRadius: BorderRadius.circular(6),
  ),
  // …inside Row, replace the Icon:
  isReady
      ? Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: c.success,
            shape: BoxShape.circle,
          ),
        )
      : Icon(AppIcons.update, size: 12, color: c.accentLight),
  const SizedBox(width: 7),
  Expanded(
    child: Text(
      label!,
      style: TextStyle(
        color: isReady ? c.success : c.accentLight,
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  ),
  if (showChevron) Icon(AppIcons.chevronRight, size: 10, color: c.textMuted),
  ```

- [ ] **Step 3: Analyze for compile errors**

  ```bash
  flutter analyze lib/features/update/widgets/update_chip.dart
  ```

  Expected: no issues.

- [ ] **Step 4: Run full test suite and format**

  ```bash
  flutter test && dart format lib/ test/
  ```

  Expected: all tests pass, no formatting changes.

- [ ] **Step 5: Run analyze on the whole project**

  ```bash
  flutter analyze
  ```

  Expected: no issues.

- [ ] **Step 6: Commit**

  ```bash
  git add lib/features/update/widgets/update_chip.dart
  git commit -m "feat(update): add Restart to update chip state with green styling"
  ```

---

## Final verification checklist

- [ ] `flutter analyze` — zero issues
- [ ] `flutter test` — all tests pass
- [ ] `dart format lib/ test/ --output=none` — no diffs (means files are formatted)
- [ ] Manually verify state exhaustiveness: every `switch (updateState)` in dialog and chip covers `ReadyToRestart`
