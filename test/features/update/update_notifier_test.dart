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
  Object? applyError; // set to throw from applyUpdate
  Object? downloadError; // set to throw from downloadUpdate
  Object? relaunchError; // set to throw from relaunchApp
  bool relaunchCalled = false;
  UpdateInstallStatus? lastInstallStatus; // returned by readLastInstallStatus

  @override
  Future<UpdateInfo?> checkForUpdate() async => null;

  @override
  Future<String> downloadUpdate({required UpdateInfo info, required void Function(double) onProgress}) async {
    if (downloadError != null) throw downloadError!;
    return '/tmp/fake.zip';
  }

  @override
  Future<void> applyUpdate(String zipPath) async {
    if (applyError != null) throw applyError!;
  }

  @override
  Future<Never> relaunchApp() {
    relaunchCalled = true;
    if (relaunchError != null) {
      return Future.error(relaunchError!);
    }
    // Never completes — mirrors production behaviour (process would exit).
    return Completer<Never>().future;
  }

  @override
  Future<UpdateInstallStatus?> readLastInstallStatus() async => lastInstallStatus;

  @override
  Future<void> clearLastInstallStatus() async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final _kInfo = UpdateInfo(
  version: '9.9.9',
  downloadUrl: 'https://example.com/update.zip',
  releaseNotes: '',
  publishedAt: DateTime(2026, 1, 1),
);

ProviderContainer _makeContainer(_FakeUpdateService fake) {
  final c = ProviderContainer(overrides: [updateServiceProvider.overrideWithValue(fake)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  late _FakeUpdateService fake;

  setUp(() => fake = _FakeUpdateService());

  // ── downloadAndInstall ────────────────────────────────────────────────────

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

    test('transitions to error when downloadUpdate throws UpdateDownloadException', () async {
      fake.downloadError = const UpdateDownloadException('timeout');
      final c = _makeContainer(fake);
      await c.read(updateProvider.notifier).downloadAndInstall(_kInfo);
      expect(c.read(updateProvider), isA<UpdateStateError>());
      final err = (c.read(updateProvider) as UpdateStateError).failure;
      expect(err, isA<UpdateDownloadFailed>());
    });

    test('is a no-op when state is already ReadyToRestart', () async {
      final c = _makeContainer(fake);
      await c.read(updateProvider.notifier).downloadAndInstall(_kInfo);
      expect(c.read(updateProvider), isA<UpdateStateReadyToRestart>());
      // Second call must be skipped — state must remain ReadyToRestart.
      await c.read(updateProvider.notifier).downloadAndInstall(_kInfo);
      expect(c.read(updateProvider), isA<UpdateStateReadyToRestart>());
    });
  });

  // ── dismiss ───────────────────────────────────────────────────────────────

  group('dismiss', () {
    test('transitions ReadyToRestart back to Idle', () async {
      final c = _makeContainer(fake);
      await c.read(updateProvider.notifier).downloadAndInstall(_kInfo);
      expect(c.read(updateProvider), isA<UpdateStateReadyToRestart>());
      c.read(updateProvider.notifier).dismiss();
      expect(c.read(updateProvider), isA<UpdateStateIdle>());
    });
  });

  // ── restartNow ────────────────────────────────────────────────────────────

  group('restartNow', () {
    test('calls relaunchApp and state remains ReadyToRestart while pending', () async {
      final c = _makeContainer(fake);
      // Reach ReadyToRestart first via the real path.
      await c.read(updateProvider.notifier).downloadAndInstall(_kInfo);
      expect(c.read(updateProvider), isA<UpdateStateReadyToRestart>());

      // Don't await — relaunchApp never completes in the fake.
      unawaited(c.read(updateProvider.notifier).restartNow());
      // Pump microtasks so the call reaches the fake.
      await Future<void>.microtask(() {});

      expect(fake.relaunchCalled, isTrue);
      // State must remain ReadyToRestart — no premature transition.
      expect(c.read(updateProvider), isA<UpdateStateReadyToRestart>());
    });

    test('transitions to UpdateRelaunchFailed error when relaunchApp throws', () async {
      fake.relaunchError = Exception('open failed');
      final c = _makeContainer(fake);
      await c.read(updateProvider.notifier).downloadAndInstall(_kInfo);
      expect(c.read(updateProvider), isA<UpdateStateReadyToRestart>());

      await c.read(updateProvider.notifier).restartNow();

      expect(c.read(updateProvider), isA<UpdateStateError>());
      final err = (c.read(updateProvider) as UpdateStateError).failure;
      expect(err, isA<UpdateRelaunchFailed>());
    });
  });

  // ── checkForUpdates guard ─────────────────────────────────────────────────

  group('checkForUpdates guard', () {
    test('skips check when state is ReadyToRestart', () async {
      final c = _makeContainer(fake);
      await c.read(updateProvider.notifier).downloadAndInstall(_kInfo);
      expect(c.read(updateProvider), isA<UpdateStateReadyToRestart>());
      await c.read(updateProvider.notifier).checkForUpdates();
      expect(c.read(updateProvider), isA<UpdateStateReadyToRestart>());
    });
  });

  // ── _surfacePreviousInstallStatus ─────────────────────────────────────────

  group('_surfacePreviousInstallStatus', () {
    test('surfaces failed sentinel as installFailed error on startup', () async {
      fake.lastInstallStatus = (status: 'failed', detail: 'ditto-failed', timestamp: '2026-01-01T00:00:00Z');
      final c = _makeContainer(fake);
      // Reading the provider triggers build(), which calls unawaited(_surfacePreviousInstallStatus()).
      // delayed(Duration.zero) drains microtasks + one event-loop turn so the async chain completes.
      c.read(updateProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(updateProvider), isA<UpdateStateError>());
      final err = (c.read(updateProvider) as UpdateStateError).failure;
      expect(err, isA<UpdateInstallFailed>());
    });

    test('does not surface sentinel when status is ok', () async {
      fake.lastInstallStatus = (status: 'ok', detail: '', timestamp: '2026-01-01T00:00:00Z');
      final c = _makeContainer(fake);
      c.read(updateProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(updateProvider), isA<UpdateStateIdle>());
    });
  });
}
