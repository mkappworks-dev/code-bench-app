import 'dart:io';

class GitDetector {
  static bool isGitRepo(String directoryPath) {
    final gitDir = Directory('$directoryPath/.git');
    return gitDir.existsSync();
  }

  static String? getCurrentBranch(String directoryPath) {
    if (!isGitRepo(directoryPath)) return null;
    try {
      final result = Process.runSync(
        'git',
        ['rev-parse', '--abbrev-ref', 'HEAD'],
        workingDirectory: directoryPath,
      );
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
