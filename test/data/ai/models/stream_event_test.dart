import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';

void main() {
  test('StreamEvent variants pattern-match exhaustively', () {
    final events = <StreamEvent>[
      const StreamEvent.textDelta('hi'),
      const StreamEvent.toolCallStart(id: 'a', name: 'read_file'),
      const StreamEvent.toolCallArgsDelta(id: 'a', argsJsonFragment: '{"p":'),
      const StreamEvent.toolCallEnd(id: 'a'),
      const StreamEvent.finish(reason: 'stop'),
    ];

    final names = events
        .map(
          (e) => switch (e) {
            StreamTextDelta() => 'text',
            StreamToolCallStart() => 'start',
            StreamToolCallArgsDelta() => 'args',
            StreamToolCallEnd() => 'end',
            StreamFinish() => 'finish',
          },
        )
        .toList();

    expect(names, ['text', 'start', 'args', 'end', 'finish']);
  });
}
