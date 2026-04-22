import 'dart:io';

import '../../../core/utils/debug_logger.dart';

/// Checks whether the `rg` (ripgrep) binary is available on PATH.
/// File name ends in `_process.dart` so the dart:io arch rule is satisfied.
class RipgrepAvailabilityDatasource {
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run('rg', ['--version']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    } on IOException catch (e) {
      dLog('[RipgrepAvailabilityDatasource] unexpected I/O error: $e');
      return false;
    }
  }
}
