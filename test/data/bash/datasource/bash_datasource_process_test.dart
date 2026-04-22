import 'package:code_bench_app/data/bash/datasource/bash_datasource_process.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BashDatasource.run', () {
    test('captures stdout and exits 0', () async {
      final ds = BashDatasource();
      final result = await ds.run(command: 'echo hello', workingDirectory: '/tmp');
      expect(result.exitCode, 0);
      expect(result.output, contains('hello'));
      expect(result.timedOut, isFalse);
    });

    test('captures stderr and exits 0', () async {
      final ds = BashDatasource();
      final result = await ds.run(command: 'echo err >&2', workingDirectory: '/tmp');
      expect(result.exitCode, 0);
      expect(result.output, contains('err'));
      expect(result.timedOut, isFalse);
    });

    test('returns non-zero exit code', () async {
      final ds = BashDatasource();
      final result = await ds.run(command: 'exit 42', workingDirectory: '/tmp');
      expect(result.exitCode, 42);
      expect(result.timedOut, isFalse);
    });

    test('kills process and sets timedOut on timeout', () async {
      final ds = BashDatasource(timeout: const Duration(seconds: 1));
      final result = await ds.run(command: 'sleep 200', workingDirectory: '/tmp');
      expect(result.timedOut, isTrue);
    });
  });
}
