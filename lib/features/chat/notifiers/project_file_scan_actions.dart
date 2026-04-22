import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/project/datasource/project_file_scan_datasource_io.dart';
import 'project_file_scan_failure.dart';

part 'project_file_scan_actions.g.dart';

/// Command notifier for the file picker's project scan.
///
/// On scan failure the notifier emits [AsyncError] carrying a
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
        result = await ref.read(projectFileScanDatasourceProvider).scanCodeFiles(rootPath);
      } catch (e, st) {
        dLog('[ProjectFileScanActions] scan failed: ${e.runtimeType}');
        Error.throwWithStackTrace(ProjectFileScanFailure.scan(e.toString()), st);
      }
    });
    return result;
  }
}
