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
      dLog('[UpdateInstallStatusDatasource] readStatus failed: $e\n$st');
      return null;
    }
  }

  @override
  Future<void> clearStatus() async {
    try {
      final file = File(await sentinelPath());
      if (file.existsSync()) await file.delete();
    } catch (e) {
      dLog('[UpdateInstallStatusDatasource] clearStatus failed: $e');
    }
  }
}
