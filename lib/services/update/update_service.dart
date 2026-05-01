// lib/services/update/update_service.dart
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/update/datasource/update_install_datasource.dart';
import '../../data/update/datasource/update_install_datasource_process.dart';
import '../../data/update/datasource/update_install_status_datasource.dart';
import '../../data/update/datasource/update_install_status_datasource_io.dart';
import '../../data/update/models/update_info.dart';
import '../../data/update/models/update_install_status.dart';
import '../../data/update/update_exception.dart';
import '../../data/update/update_repository.dart';
import '../../data/update/update_repository_impl.dart';

part 'update_service.g.dart';

@Riverpod(keepAlive: true)
UpdateService updateService(Ref ref) => UpdateService(
  repository: ref.watch(updateRepositoryProvider),
  installDs: ref.watch(updateInstallDatasourceProvider),
  statusDs: ref.watch(updateInstallStatusDatasourceProvider),
);

/// Orchestrates the update lifecycle. Owns policy decisions (signature
/// enforcement, Team-ID matching, version comparison) and composes datasources
/// for all I/O — does not perform Process or filesystem operations directly.
class UpdateService {
  UpdateService({
    required UpdateRepository repository,
    required UpdateInstallDatasource installDs,
    required UpdateInstallStatusDatasource statusDs,
  }) : _repo = repository,
       _installDs = installDs,
       _statusDs = statusDs;

  final UpdateRepository _repo;
  final UpdateInstallDatasource _installDs;
  final UpdateInstallStatusDatasource _statusDs;

  Future<UpdateInfo?> checkForUpdate() async {
    final info = await _repo.fetchLatestRelease();
    if (info == null) return null;
    final packageInfo = await PackageInfo.fromPlatform();
    return isNewer(info.version, packageInfo.version) ? info : null;
  }

  Future<String> downloadUpdate({required UpdateInfo info, required void Function(double progress) onProgress}) =>
      _repo.downloadRelease(
        url: info.downloadUrl,
        version: info.version,
        onProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );

  /// Verifies the downloaded bundle's authenticity and swaps it in for the
  /// running install. Never returns normally on success — the spawned
  /// relaunch script outlives this process.
  Future<void> installUpdate(String zipPath) async {
    final extractDir = await _installDs.createExtractDir();
    try {
      await _installDs.extractZip(zipPath: zipPath, destDir: extractDir);
      final extractedAppPath = await _installDs.resolveExtractedAppPath(extractDir);
      final appPath = _installDs.currentAppPath();

      // Authenticity gate: refuse anything not signed by the same Team ID as
      // the running bundle. When the running bundle is unsigned (dev build),
      // require the downloaded bundle to be unsigned too — refuses any
      // signed↔unsigned crossover.
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
      await _installDs.swapAndRelaunch(
        currentAppPath: appPath,
        newAppPath: extractedAppPath,
        extractDir: extractDir,
        zipPath: zipPath,
        statusSentinelPath: statusPath,
        enforceSignature: enforceSignature,
      );
    } catch (e, st) {
      _installDs.cleanupExtractDir(extractDir);
      // Preserve typed UpdateException; wrap anything else (raw I/O, etc.) so
      // higher layers never see implementation-leak exceptions. Preserve the
      // original stack trace so Flutter's error reporter sees the real cause.
      if (e is UpdateException) rethrow;
      dLog('[UpdateService] installUpdate unexpected error: ${e.runtimeType}: $e\n$st');
      Error.throwWithStackTrace(UpdateInstallException('Install failed: ${e.runtimeType}: $e'), st);
    }
  }

  /// Reads the previous-attempt sentinel left behind by the relaunch script.
  Future<UpdateInstallStatus?> readLastInstallStatus() => _statusDs.readStatus();

  /// Clears the sentinel after the notifier has surfaced its contents.
  Future<void> clearLastInstallStatus() => _statusDs.clearStatus();

  static bool isNewer(String latest, String current) {
    final l = latest.split('.').map(int.tryParse).whereType<int>().toList();
    final c = current.split('.').map(int.tryParse).whereType<int>().toList();
    if (l.length < 3 || c.length < 3) {
      dLog('[UpdateService] isNewer: unparseable version latest="$latest" current="$current"');
      return false;
    }
    for (var i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }
}
