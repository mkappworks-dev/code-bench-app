import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../services/project/project_file_scan_service.dart';
import 'project_file_scan_failure.dart';

part 'project_file_scan_actions.g.dart';

/// Command notifier for the file picker's project scan.
///
/// On [FileSystemException] the notifier emits [AsyncError] carrying a
/// [ProjectFileScanFailure] so widgets can surface an inline error message
/// via [ref.listen] without catching exceptions themselves.
@Riverpod(keepAlive: true)
class ProjectFileScanActions extends _$ProjectFileScanActions {
  @override
  FutureOr<void> build() {}

  /// Returns repo-relative code-file paths under [rootPath]. Emits
  /// [AsyncError] with a [ProjectFileScanFailure] if the root cannot be listed.
  Future<List<String>> scanCodeFiles(String rootPath) async {
    state = const AsyncLoading();
    List<String> result = const [];
    state = await AsyncValue.guard(() async {
      try {
        result = await ref.read(projectFileScanServiceProvider).scanCodeFiles(rootPath);
      } on FileSystemException catch (e, st) {
        dLog('[ProjectFileScanActions] scan failed: ${e.runtimeType}');
        Error.throwWithStackTrace(ProjectFileScanFailure.scan(e.message), st);
      } on Exception catch (_, st) {
        dLog('[ProjectFileScanActions] scan failed with unknown error');
        Error.throwWithStackTrace(const ProjectFileScanFailure.scan('Couldn\'t scan project.'), st);
      }
    });
    return result;
  }
}
