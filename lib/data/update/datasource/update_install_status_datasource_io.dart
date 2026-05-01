// lib/data/update/datasource/update_install_status_datasource_io.dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../models/update_install_status.dart';
import 'update_install_status_datasource.dart';

part 'update_install_status_datasource_io.g.dart';

const _kStatusFileName = 'last-update-status.json';

@Riverpod(keepAlive: true)
UpdateInstallStatusDatasource updateInstallStatusDatasource(Ref ref) => UpdateInstallStatusDatasourceIo();

class UpdateInstallStatusDatasourceIo implements UpdateInstallStatusDatasource {
  @override
  Future<String> sentinelPath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, _kStatusFileName);
  }

  @override
  Future<UpdateInstallStatus?> readStatus() async {
    final path = await sentinelPath();
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return (
        status: json['status'] as String? ?? 'unknown',
        detail: json['detail'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
      );
    } catch (e, st) {
      // Distinguish "missing" (handled above with existsSync) from
      // "present-but-unreadable": surface a corrupted-sentinel marker so the
      // notifier can show the user something instead of pretending nothing
      // happened.
      dLog('[UpdateInstallStatusDatasource] readStatus failed: ${e.runtimeType}: $e\n$st');
      return (status: 'unknown', detail: 'corrupted-sentinel', timestamp: '');
    }
  }

  @override
  Future<void> clearStatus() async {
    final path = await sentinelPath();
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
      return;
    } catch (e) {
      dLog('[UpdateInstallStatusDatasource] clearStatus delete failed, falling back to overwrite: $e');
    }
    // Fallback: if delete failed (read-only volume, perm change, locked), at
    // least overwrite the file with an "ok" payload so the notifier doesn't
    // re-fire the same install-failed error on every cold start forever.
    try {
      await File(path).writeAsString('{"status":"ok","detail":"","timestamp":""}\n');
    } catch (e, st) {
      dLog('[UpdateInstallStatusDatasource] clearStatus overwrite fallback failed: $e\n$st');
    }
  }
}
