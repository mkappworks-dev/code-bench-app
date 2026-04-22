import 'dart:async';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';

const Duration kGitCheckoutTimeout = Duration(seconds: 30);

/// Process-level git operations for the apply flow. Isolated in a datasource
/// so [ApplyRepositoryImpl] needs no dart:io import.
class ApplyGitDatasource {
  /// Restores [filePath] to HEAD via `git checkout --`. Throws [StateError] on
  /// non-zero exit or timeout.
  Future<void> gitCheckout(String filePath, String workingDirectory) async {
    final ProcessResult result;
    try {
      result = await Process.run('git', [
        'checkout',
        '--',
        filePath,
      ], workingDirectory: workingDirectory).timeout(kGitCheckoutTimeout);
    } on TimeoutException {
      dLog('[ApplyGitDatasource] gitCheckout timed out for $filePath');
      throw StateError('git checkout timed out after ${kGitCheckoutTimeout.inSeconds}s');
    }
    if (result.exitCode != 0) {
      dLog('[ApplyGitDatasource] gitCheckout failed (exit ${result.exitCode}): ${result.stderr}');
      throw StateError('git checkout failed (exit ${result.exitCode}): ${result.stderr}');
    }
  }
}
