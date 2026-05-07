import 'dart:io';

/// Process-spawning seam used by [CodexSession] (and any future datasource
/// that wants unit-testable process plumbing). Production callers pass
/// [defaultProcessLauncher]; tests pass a closure that returns a fake
/// [Process] so JSON-RPC handshakes can be exercised without spawning the
/// real binary.
///
/// Mirrors `Process.start`'s positional + named parameter shape so
/// `defaultProcessLauncher` is a one-line forward.
typedef ProcessLauncher =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment,
      bool runInShell,
    });

Future<Process> defaultProcessLauncher(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
}) {
  return Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
  );
}
