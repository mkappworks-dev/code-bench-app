import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';

typedef BashResult = ({int exitCode, String output, bool timedOut});

class BashDatasource {
  BashDatasource({this.timeout = const Duration(seconds: 120)});
  final Duration timeout;

  Future<BashResult> run({required String command, required String workingDirectory}) async {
    late final Process process;
    try {
      process = await Process.start('/bin/sh', ['-c', command], workingDirectory: workingDirectory);
    } on ProcessException catch (e) {
      dLog('[BashDatasource] Process.start failed: $e');
      rethrow;
    }

    final outputBuf = StringBuffer();
    final stdoutFuture = process.stdout.transform(utf8.decoder).forEach(outputBuf.write);
    final stderrFuture = process.stderr.transform(utf8.decoder).forEach(outputBuf.write);

    late int exitCode;
    late bool timedOut;
    try {
      exitCode = await process.exitCode.timeout(timeout);
      timedOut = false;
    } on TimeoutException {
      process.kill();
      exitCode = -1;
      timedOut = true;
    }

    try {
      await Future.wait([stdoutFuture, stderrFuture]).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Streams may already be closed after process.kill(); drain errors are benign.
    }

    return (exitCode: exitCode, output: outputBuf.toString(), timedOut: timedOut);
  }
}
