/// Thrown when a user-defined action command cannot be started — the executable
/// is not on PATH or lacks execute permissions.
class ActionRunnerException implements Exception {
  const ActionRunnerException(this.executable);
  final String executable;
  @override
  String toString() => 'Failed to start process: $executable';
}
