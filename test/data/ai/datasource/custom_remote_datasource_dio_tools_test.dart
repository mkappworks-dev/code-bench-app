import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/ai/datasource/custom_remote_datasource_dio.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';

void main() {
  group('parseOpenAiToolSseLine', () {
    test('text delta → StreamTextDelta', () {
      final event = parseOpenAiToolSseLine('data: {"choices":[{"delta":{"content":"hello"}}]}', <int, String>{});
      expect(event, isA<StreamTextDelta>());
      expect((event as StreamTextDelta).text, 'hello');
    });

    test('tool_call_start assigns id and name', () {
      final idByIndex = <int, String>{};
      final event = parseOpenAiToolSseLine(
        'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_abc","type":"function","function":{"name":"read_file","arguments":""}}]}}]}',
        idByIndex,
      );
      expect(event, isA<StreamToolCallStart>());
      expect((event as StreamToolCallStart).id, 'call_abc');
      expect(event.name, 'read_file');
      expect(idByIndex[0], 'call_abc');
    });

    test('args delta without id reuses id-by-index map', () {
      final idByIndex = {0: 'call_abc'};
      final event = parseOpenAiToolSseLine(
        'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\\"path\\":"}}]}}]}',
        idByIndex,
      );
      expect(event, isA<StreamToolCallArgsDelta>());
      expect((event as StreamToolCallArgsDelta).id, 'call_abc');
      expect(event.argsJsonFragment, '{"path":');
    });

    test('args delta with unregistered index returns null', () {
      final event = parseOpenAiToolSseLine(
        'data: {"choices":[{"delta":{"tool_calls":[{"index":5,"function":{"arguments":"{\\"x\\":"}}]}}]}',
        <int, String>{},
      );
      expect(event, isNull);
    });

    test('finish_reason stop → StreamFinish("stop")', () {
      final event = parseOpenAiToolSseLine('data: {"choices":[{"finish_reason":"stop"}]}', <int, String>{});
      expect(event, isA<StreamFinish>());
      expect((event as StreamFinish).reason, 'stop');
    });

    test('finish_reason tool_calls → StreamFinish("tool_calls")', () {
      final event = parseOpenAiToolSseLine('data: {"choices":[{"finish_reason":"tool_calls"}]}', <int, String>{});
      expect((event as StreamFinish).reason, 'tool_calls');
    });

    test('[DONE] line returns null', () {
      expect(parseOpenAiToolSseLine('data: [DONE]', <int, String>{}), isNull);
    });

    test('malformed JSON returns null (no throw)', () {
      expect(parseOpenAiToolSseLine('data: {bad', <int, String>{}), isNull);
    });

    test('non-data line returns null', () {
      expect(parseOpenAiToolSseLine(': keep-alive', <int, String>{}), isNull);
    });
  });

  group('isUnknownFieldRejection', () {
    test('non-400 status never matches', () {
      expect(isUnknownFieldRejection(401, 'unknown field reasoning_effort', 'reasoning_effort'), isFalse);
      expect(isUnknownFieldRejection(500, 'unsupported reasoning_effort', 'reasoning_effort'), isFalse);
      expect(isUnknownFieldRejection(null, 'unknown reasoning_effort', 'reasoning_effort'), isFalse);
    });

    test('null/empty body never matches', () {
      expect(isUnknownFieldRejection(400, null, 'reasoning_effort'), isFalse);
      expect(isUnknownFieldRejection(400, '', 'reasoning_effort'), isFalse);
    });

    test('body must contain the field name', () {
      expect(isUnknownFieldRejection(400, 'unknown field thinking_budget', 'reasoning_effort'), isFalse);
    });

    test('matches vLLM-style unknown-field rejection', () {
      expect(isUnknownFieldRejection(400, '{"error":"unknown field reasoning_effort"}', 'reasoning_effort'), isTrue);
    });

    test('matches Pydantic-style extra_forbidden', () {
      expect(
        isUnknownFieldRejection(
          400,
          '[{"loc":["body","reasoning_effort"],"type":"extra_forbidden"}]',
          'reasoning_effort',
        ),
        isTrue,
      );
    });

    test('matches "unrecognized parameter" wording', () {
      expect(isUnknownFieldRejection(400, 'unrecognized parameter reasoning_effort', 'reasoning_effort'), isTrue);
    });

    test('does NOT match a 400 that merely names the field (oversize context)', () {
      expect(
        isUnknownFieldRejection(
          400,
          'context length exceeded; fields used: model, messages, reasoning_effort',
          'reasoning_effort',
        ),
        isFalse,
      );
    });

    test('does NOT match auth-scope 400 mentioning the field', () {
      expect(
        isUnknownFieldRejection(400, 'API key does not have access to reasoning_effort', 'reasoning_effort'),
        isFalse,
      );
    });
  });
}
