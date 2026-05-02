import 'dart:io';

import 'package:code_bench_app/data/ai/datasource/claude_cli_stream_parser.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ClaudeCliStreamParser parser;

  setUp(() {
    parser = ClaudeCliStreamParser();
  });

  Stream<String> fixtureLines(String name) async* {
    final file = File('test/fixtures/claude_cli/$name.jsonl');
    for (final line in await file.readAsLines()) {
      if (line.trim().isNotEmpty) yield line;
    }
  }

  test('text_only fixture yields TextDelta + StreamDone', () async {
    final events = <StreamEvent>[];
    await for (final line in fixtureLines('text_only')) {
      final ev = parser.parseLine(line);
      if (ev != null) events.add(ev);
    }
    expect(events.whereType<TextDelta>().isNotEmpty, isTrue);
    expect(events.whereType<StreamDone>().length, greaterThanOrEqualTo(1));
  });

  test('single_tool_use fixture yields ToolUseStart + deltas + ToolUseComplete + ToolResult', () async {
    final events = <StreamEvent>[];
    await for (final line in fixtureLines('single_tool_use')) {
      final ev = parser.parseLine(line);
      if (ev != null) events.add(ev);
    }
    expect(events.whereType<ToolUseStart>().length, 1);
    expect(events.whereType<ToolUseInputDelta>().length, greaterThanOrEqualTo(1));
    expect(events.whereType<ToolUseComplete>().length, 1);
    expect(events.whereType<ToolResult>().length, 1);

    final start = events.whereType<ToolUseStart>().single;
    expect(start.name, 'Read');

    final complete = events.whereType<ToolUseComplete>().single;
    expect(complete.input['file_path'], '/etc/hosts');
    expect(complete.input['limit'], 2);

    final result = events.whereType<ToolResult>().single;
    expect(result.isError, isFalse);
    expect(result.content, contains('Host Database'));
  });

  test('thinking fixture yields ThinkingDelta events', () async {
    final events = <StreamEvent>[];
    await for (final line in fixtureLines('thinking')) {
      final ev = parser.parseLine(line);
      if (ev != null) events.add(ev);
    }
    final thinking = events.whereType<ThinkingDelta>().toList();
    expect(thinking.isNotEmpty, isTrue);
    final concatenated = thinking.map((t) => t.text).join();
    expect(concatenated, 'The user wants a simple greeting.');
  });

  test('malformed fixture: bad lines emit StreamParseFailure, good lines still parsed', () async {
    final events = <StreamEvent>[];
    await for (final line in fixtureLines('malformed')) {
      final ev = parser.parseLine(line);
      if (ev != null) events.add(ev);
    }
    expect(events.whereType<StreamParseFailure>().length, greaterThanOrEqualTo(2));
    expect(events.whereType<TextDelta>().length, 1);
  });

  test('rate_limit_event is ignored (returns null)', () {
    const line = '{"type":"rate_limit_event","session_id":"x"}';
    expect(parser.parseLine(line), isNull);
  });

  test('system:init is ignored', () {
    const line = '{"type":"system","subtype":"init","session_id":"x"}';
    expect(parser.parseLine(line), isNull);
  });

  test('hook events are ignored', () {
    const line = '{"type":"system","subtype":"hook_started","hook_name":"SessionStart:startup","session_id":"x"}';
    expect(parser.parseLine(line), isNull);
  });
}
