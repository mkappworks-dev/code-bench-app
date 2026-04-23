@TestOn('mac-os || linux')
@Tags(['integration'])
library;

import 'dart:io';

import 'package:code_bench_app/data/ai/datasource/claude_cli_remote_datasource_process.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cliAvailable = Platform.environment['CLAUDE_CLI_AVAILABLE'] == '1';

  test('real claude CLI emits at least one TextDelta', () async {
    final ds = ClaudeCliRemoteDatasourceProcess();
    final events = <StreamEvent>[];
    await for (final event in ds.streamEvents(
      history: const [],
      prompt: 'Say "hi" and nothing else.',
      workingDirectory: Directory.systemTemp.path,
      sessionId: 'smoke-${DateTime.now().millisecondsSinceEpoch}',
      isFirstTurn: true,
    )) {
      events.add(event);
      if (events.length > 500) break;
    }
    expect(events.whereType<TextDelta>().isNotEmpty, isTrue);
  }, skip: cliAvailable ? null : 'Set CLAUDE_CLI_AVAILABLE=1 to run');
}
