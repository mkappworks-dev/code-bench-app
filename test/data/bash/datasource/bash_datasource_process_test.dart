import 'package:code_bench_app/data/bash/datasource/bash_datasource_process.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BashDatasource.run', () {
    test('captures stdout and exits 0', () async {
      final ds = BashDatasourceProcess();
      final result = await ds.run(command: 'echo hello', workingDirectory: '/tmp');
      expect(result.exitCode, 0);
      expect(result.output, contains('hello'));
      expect(result.timedOut, isFalse);
    });

    test('captures stderr and exits 0', () async {
      final ds = BashDatasourceProcess();
      final result = await ds.run(command: 'echo err >&2', workingDirectory: '/tmp');
      expect(result.exitCode, 0);
      expect(result.output, contains('err'));
      expect(result.timedOut, isFalse);
    });

    test('returns non-zero exit code', () async {
      final ds = BashDatasourceProcess();
      final result = await ds.run(command: 'exit 42', workingDirectory: '/tmp');
      expect(result.exitCode, 42);
      expect(result.timedOut, isFalse);
    });

    test('kills process and sets timedOut on timeout', () async {
      final ds = BashDatasourceProcess(timeout: const Duration(seconds: 1));
      final result = await ds.run(command: 'sleep 200', workingDirectory: '/tmp');
      expect(result.timedOut, isTrue);
    });

    test('caps output at 50 KB and appends sentinel', () async {
      final ds = BashDatasourceProcess();
      // ~1 KB per iteration × 60 = ~60 KB total
      final result = await ds.run(
        command: r"for i in $(seq 1 60); do printf '%1000s\n'; done",
        workingDirectory: '/tmp',
      );
      expect(result.timedOut, isFalse);
      expect(result.output, contains('[Output capped'));
    });
  });
}
