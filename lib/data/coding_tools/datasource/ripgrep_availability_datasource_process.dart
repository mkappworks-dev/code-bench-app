import 'dart:io';

/// Checks whether the `rg` (ripgrep) binary is available on PATH.
/// File name ends in `_process.dart` so the dart:io arch rule is satisfied.
class RipgrepAvailabilityDatasource {
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run('rg', ['--version']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }
}
