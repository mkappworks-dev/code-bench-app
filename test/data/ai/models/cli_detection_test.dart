import 'package:code_bench_app/data/ai/models/cli_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CliDetection', () {
    test('notInstalled variant constructs', () {
      const detection = CliDetection.notInstalled();
      expect(detection, isA<CliNotInstalled>());
    });

    test('installed variant carries version, path, auth, timestamp', () {
      final now = DateTime.utc(2026, 4, 23);
      final detection = CliDetection.installed(
        version: '2.1.104',
        binaryPath: '/opt/homebrew/bin/claude',
        authStatus: CliAuthStatus.authenticated,
        checkedAt: now,
      );
      switch (detection) {
        case CliNotInstalled():
          fail('expected installed');
        case CliInstalled(:final version, :final binaryPath, :final authStatus, :final checkedAt):
          expect(version, '2.1.104');
          expect(binaryPath, '/opt/homebrew/bin/claude');
          expect(authStatus, CliAuthStatus.authenticated);
          expect(checkedAt, now);
      }
    });
  });
}
