import 'dart:io';

import 'package:code_bench_app/data/ai/datasource/process_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defaultProcessLauncher', () {
    test('forwards to Process.start and returns a Process', () async {
      // `true` is on every Unix-like and exits 0 immediately.
      final proc = await defaultProcessLauncher('/usr/bin/true', const <String>[]);
      expect(proc, isA<Process>());
      expect(await proc.exitCode, 0);
    });

    test('honours the workingDirectory parameter', () async {
      final proc = await defaultProcessLauncher('/bin/sh', const ['-c', 'pwd'], workingDirectory: '/tmp');
      final out = await proc.stdout.transform(const SystemEncoding().decoder).join();
      // /tmp is symlinked to /private/tmp on macOS
      expect(out.trim(), anyOf('/tmp', '/private/tmp'));
    });
  });
}
