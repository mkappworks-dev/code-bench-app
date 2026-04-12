import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../services/project/project_file_scan_service.dart';

part 'project_file_scan_actions.g.dart';

/// Command notifier for the @-mention file picker's project scan.
///
/// Widgets never touch [ProjectFileScanService] directly — they call
/// [scanCodeFiles] here, which owns the FileSystemException logging so the
/// widget can render a plain error string without a second log site.
@Riverpod(keepAlive: true)
class ProjectFileScanActions extends _$ProjectFileScanActions {
  @override
  void build() {}

  /// Returns repo-relative code-file paths under [rootPath]. Throws
  /// [FileSystemException] when the root itself cannot be listed; the UI
  /// should catch and surface a user-facing message.
  Future<List<String>> scanCodeFiles(String rootPath) async {
    try {
      return await ref.read(projectFileScanServiceProvider).scanCodeFiles(rootPath);
    } on FileSystemException catch (e) {
      dLog('[ProjectFileScanActions] scan failed: ${e.runtimeType}');
      rethrow;
    }
  }
}
