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
  Object? applyError; // set to UpdateInstallException to simulate failure
  bool relaunchCalled = false;

  @override
  Future<UpdateInfo?> checkForUpdate() async => null;

  @override
  Future<String> downloadUpdate({required UpdateInfo info, required void Function(double) onProgress}) async =>
      '/tmp/fake.zip';

  @override
  Future<void> applyUpdate(String zipPath) async {
    if (applyError != null) throw applyError!;
  }

  @override
  Future<Never> relaunchApp() {
    relaunchCalled = true;
    // Never completes — mirrors production behaviour (process would exit).
    return Completer<Never>().future;
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
