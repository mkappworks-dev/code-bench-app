/// A handle to a running user-defined action subprocess.
///
/// [lines] emits merged stdout/stderr split by newline and completes when the
/// process exits. [exitCode] resolves to the process exit code. [kill] sends
/// SIGTERM to the process.
final class ActionRun {
  ActionRun({required this.lines, required this.exitCode, required this.kill});
  final Stream<String> lines;
  final Future<int> exitCode;
  final void Function() kill;
}
