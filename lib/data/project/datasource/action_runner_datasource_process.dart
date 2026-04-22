import 'dart:async';
import 'dart:io';

import '../action_runner_exceptions.dart';
import '../models/action_run.dart';

/// Starts user-defined action commands as subprocesses and streams their
/// output. Translates [ProcessException] into [ActionRunnerException] so
/// callers above this layer need no dart:io import.
class ActionRunnerDatasource {
  /// Starts [executable] with [args] in [workingDirectory].
  ///
  /// Returns an [ActionRun] whose [ActionRun.lines] stream emits merged
  /// stdout/stderr lines and completes when both streams are fully drained.
  /// Throws [ActionRunnerException] if the process cannot be started.
  Future<ActionRun> start({
    required String executable,
    required List<String> args,
    required String workingDirectory,
  }) async {
    final Process process;
    try {
      // SECURITY: runInShell is intentionally false — args are passed as a
      // literal argv list, never interpolated through a shell.
      process = await Process.start(executable, args, workingDirectory: workingDirectory);
    } on ProcessException {
      throw ActionRunnerException(executable);
    }

    final ctrl = StreamController<String>();
    var pending = 2;

    void pipe(Stream<List<int>> src) {
      src
          .transform(const SystemEncoding().decoder)
          .listen(
            (chunk) {
              for (final line in chunk.split('\n')) {
                if (line.isNotEmpty) ctrl.add(line);
              }
            },
            onDone: () {
              if (--pending == 0) ctrl.close();
            },
            onError: (_) {
              if (--pending == 0) ctrl.close();
            },
            cancelOnError: false,
          );
    }

    pipe(process.stdout);
    pipe(process.stderr);

    return ActionRun(lines: ctrl.stream, exitCode: process.exitCode, kill: () => process.kill());
  }
}
