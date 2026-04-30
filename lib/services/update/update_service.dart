// lib/services/update/update_service.dart
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/update/models/update_info.dart';
import '../../data/update/update_exception.dart';
import '../../data/update/update_repository.dart';
import '../../data/update/update_repository_impl.dart';

part 'update_service.g.dart';

@Riverpod(keepAlive: true)
UpdateService updateService(Ref ref) => UpdateService(repository: ref.watch(updateRepositoryProvider));

class UpdateService {
  UpdateService({required UpdateRepository repository}) : _repo = repository;

  final UpdateRepository _repo;

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

  Future<void> installUpdate(String zipPath) async {
    final extractDir = '${Directory.systemTemp.path}/cb-update-extracted';

    // Extract .zip — ditto preserves macOS xattrs and codesign metadata
    final extractResult = await Process.run('ditto', ['-x', '-k', zipPath, extractDir]);
    if (extractResult.exitCode != 0) {
      dLog('[UpdateService] ditto extract failed: ${extractResult.stderr}');
      throw UpdateInstallException('ditto extract failed: ${extractResult.stderr}');
    }

    // Resolve current .app path from executable: walk up 3 levels
    // e.g. /Applications/Code Bench.app/Contents/MacOS/code_bench_app → .app
    final appPath = p.dirname(p.dirname(p.dirname(Platform.resolvedExecutable)));

    // Find extracted .app directory
    final extracted = Directory(extractDir).listSync().whereType<Directory>().firstWhere(
      (d) => d.path.endsWith('.app'),
      orElse: () {
        throw const UpdateInstallException('No .app found in extracted zip');
      },
    );

    // Write backup-first relaunch script:
    // mv current → .old, ditto new → current, open on success, restore on failure
    final scriptPath = '${Directory.systemTemp.path}/cb_relaunch.sh';
    final script = '''#!/bin/bash
sleep 1
mv "\$1" "\$1.old"
ditto "\$2" "\$1"
if [ \$? -eq 0 ]; then
  rm -rf "\$1.old"
  open "\$1"
else
  mv "\$1.old" "\$1"
fi
''';
    await File(scriptPath).writeAsString(script);
    await Process.run('chmod', ['+x', scriptPath]);
    await Process.start('/bin/bash', [scriptPath, appPath, extracted.path]);

    exit(0);
  }

  static bool isNewer(String latest, String current) {
    final l = latest.split('.').map(int.tryParse).whereType<int>().toList();
    final c = current.split('.').map(int.tryParse).whereType<int>().toList();
    if (l.length < 3 || c.length < 3) return false;
    for (var i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }
}
