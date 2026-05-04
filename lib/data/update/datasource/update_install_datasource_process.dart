// lib/data/update/datasource/update_install_datasource_process.dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../update_exception.dart';
import 'update_install_datasource.dart';

part 'update_install_datasource_process.g.dart';

@Riverpod(keepAlive: true)
UpdateInstallDatasource updateInstallDatasource(Ref ref) => UpdateInstallDatasourceProcess();

class UpdateInstallDatasourceProcess implements UpdateInstallDatasource {
  @override
  String currentAppPath() {
    // /Applications/Code Bench.app/Contents/MacOS/code_bench_app → walk up 3
    final path = p.dirname(p.dirname(p.dirname(Platform.resolvedExecutable)));
    if (!path.endsWith('.app')) {
      sLog('[UpdateInstallDatasource] currentAppPath did not resolve to a .app: $path');
      throw UpdateInstallException('Could not resolve running app bundle path: $path');
    }
    return path;
  }

  @override
  Future<String> createExtractDir() async {
    final dir = await Directory.systemTemp.createTemp('cb-update-extract-');
    return dir.path;
  }

  @override
  Future<void> extractZip({required String zipPath, required String destDir}) async {
    final r = await Process.run('ditto', ['-x', '-k', zipPath, destDir]);
    if (r.exitCode != 0) {
      dLog('[UpdateInstallDatasource] ditto extract failed: ${r.stderr}');
      throw UpdateInstallException('ditto extract failed: ${r.stderr}');
    }
  }

  @override
  Future<String> resolveExtractedAppPath(String extractDir) async {
    final dir = Directory(extractDir);
    final topLevel = dir.listSync(followLinks: false);

    // Zip-slip-via-symlink defence: reject any symlink whose resolved target
    // escapes the extraction root. Relative in-bundle symlinks (e.g.
    // FlutterMacOS.framework/Versions/Current → A) are legitimate macOS
    // framework layout and must be allowed; only reject links pointing outside
    // extractDir.
    final allEntries = dir.listSync(recursive: true, followLinks: false);
    for (final e in allEntries) {
      if (FileSystemEntity.typeSync(e.path, followLinks: false) != FileSystemEntityType.link) continue;
      final target = Link(e.path).targetSync();
      final resolved = p.normalize(p.isAbsolute(target) ? target : p.join(p.dirname(e.path), target));
      if (!p.isWithin(extractDir, resolved) && resolved != extractDir) {
        sLog('[UpdateInstallDatasource] Rejecting escaping symlink in extract: ${e.path} → $target');
        throw UpdateInstallException('Update archive contains a symlink that escapes the bundle: $target');
      }
    }

    // Require exactly one .app at the top level — refuses zips with multiple
    // bundles or none.
    final apps = topLevel.whereType<Directory>().where((d) => d.path.endsWith('.app')).toList();
    if (apps.isEmpty) {
      throw const UpdateInstallException('No .app found in extracted zip.');
    }
    if (apps.length > 1) {
      throw UpdateInstallException('Expected exactly one .app in update archive, found ${apps.length}.');
    }
    return apps.single.path;
  }

  @override
  Future<String?> readTeamId(String appPath) async {
    // codesign -dv writes its detail output to stderr by default
    final r = await Process.run('codesign', ['-dv', '--verbose=4', appPath]);
    // For unsigned bundles codesign exits non-zero; treat as "no team id" rather
    // than risking a regex match on garbage output.
    if (r.exitCode != 0) return null;
    final output = '${r.stdout}${r.stderr}';
    final match = RegExp(r'TeamIdentifier=(\S+)').firstMatch(output);
    final teamId = match?.group(1);
    if (teamId == null || teamId == 'not' || teamId.isEmpty) return null;
    return teamId;
  }

  @override
  Future<void> verifyCodesign(String appPath) async {
    final r = await Process.run('codesign', ['--verify', '--deep', '--strict', appPath]);
    if (r.exitCode != 0) {
      sLog('[UpdateInstallDatasource] codesign verify FAILED for $appPath: ${r.stderr}');
      throw const UpdateInstallException('Downloaded bundle failed codesign verification.');
    }
  }

  @override
  Future<void> assessGatekeeper(String appPath) async {
    final r = await Process.run('spctl', ['--assess', '--type', 'execute', appPath]);
    if (r.exitCode != 0) {
      sLog('[UpdateInstallDatasource] spctl assess FAILED for $appPath: ${r.stderr}');
      throw const UpdateInstallException('Downloaded bundle failed Gatekeeper assessment.');
    }
  }

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

  @override
  void cleanupExtractDir(String extractDir) {
    try {
      final dir = Directory(extractDir);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } catch (e) {
      dLog('[UpdateInstallDatasource] cleanup of $extractDir failed: $e');
    }
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
}
