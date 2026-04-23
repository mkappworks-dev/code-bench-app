import 'package:code_bench_app/features/providers/notifiers/claude_cli_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ClaudeCliFailure variants all constructable', () {
    const variants = [
      ClaudeCliFailure.notInstalled(),
      ClaudeCliFailure.unauthenticated(),
      ClaudeCliFailure.crashed(exitCode: 127, stderr: 'not found'),
      ClaudeCliFailure.timedOut(),
      ClaudeCliFailure.streamParseFailed(line: 'x', error: 'y'),
      ClaudeCliFailure.cancelled(),
    ];
    expect(variants.length, 6);
    expect(variants[2], isA<ClaudeCliCrashed>());
  });

  test('unknown wraps arbitrary errors', () {
    final err = StateError('oops');
    final failure = ClaudeCliFailure.unknown(err);
    expect(failure, isA<ClaudeCliUnknown>());
    (failure as ClaudeCliUnknown).error == err ? null : fail('error not preserved');
  });
}
