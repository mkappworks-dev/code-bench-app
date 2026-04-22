import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';

typedef BashResult = ({int exitCode, String output, bool timedOut});

const int _kOutputCapBytes = 50 * 1024;

abstract class BashDatasource {
  Future<BashResult> run({required String command, required String workingDirectory});
}

class BashDatasourceProcess implements BashDatasource {
  BashDatasourceProcess({this.timeout = const Duration(seconds: 120)});
  final Duration timeout;

  @override
  Future<BashResult> run({required String command, required String workingDirectory}) async {
    late final Process process;
    try {
      process = await Process.start('/bin/sh', ['-c', command], workingDirectory: workingDirectory);
    } on ProcessException catch (e) {
      dLog('[BashDatasource] Process.start failed (ProcessException): $e');
      rethrow;
    } on IOException catch (e) {
      // SF-1: OSError (e.g. missing workingDirectory) does not wrap as ProcessException.
      dLog('[BashDatasource] Process.start failed (IOException): $e');
      rethrow;
    }

    final outputBuf = StringBuffer();
    var totalBytes = 0;
    var outputCapped = false;

    // SF-2: cap output to prevent unbounded memory growth on runaway commands.
    void write(String chunk) {
      if (outputCapped) return;
      final chunkBytes = utf8.encode(chunk).length;
      if (totalBytes + chunkBytes > _kOutputCapBytes) {
        outputBuf.write('\n[Output capped at ${_kOutputCapBytes ~/ 1024} KB]');
        outputCapped = true;
        return;
      }
      outputBuf.write(chunk);
      totalBytes += chunkBytes;
    }

    final stdoutFuture = process.stdout.transform(utf8.decoder).forEach(write);
    final stderrFuture = process.stderr.transform(utf8.decoder).forEach(write);

    late int exitCode;
    late bool timedOut;
    try {
      exitCode = await process.exitCode.timeout(timeout);
      timedOut = false;
    } on TimeoutException {
      // SF-4: SIGKILL cannot be caught or ignored; SIGTERM can be.
      // Known limitation: child processes in a separate process group may persist as orphans.
      process.kill(ProcessSignal.sigkill);
      dLog('[BashDatasource] command timed out; shell killed. Child processes in separate groups may persist.');
      exitCode = -1;
      timedOut = true;
    }

    // SF-3: distinguish benign close-after-kill from real decode/timeout errors.
    try {
      await Future.wait([stdoutFuture, stderrFuture]).timeout(const Duration(seconds: 5));
    } on TimeoutException {
      dLog('[BashDatasource] stdout/stderr drain timed out — output may be incomplete');
      outputBuf.write('\n[Warning: output stream drain timed out; output may be incomplete]');
    } catch (e) {
      dLog('[BashDatasource] stream drain error: ${e.runtimeType} $e');
      outputBuf.write('\n[Warning: output stream error (${e.runtimeType}); output may be incomplete]');
    }

    return (exitCode: exitCode, output: outputBuf.toString(), timedOut: timedOut);
  }
}
