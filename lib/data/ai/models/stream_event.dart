import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_event.freezed.dart';

/// Provider-agnostic stream event emitted by `ToolStreamingRepository.streamMessageWithTools`.
///
/// The OpenAI wire format interleaves content deltas and tool-call deltas.
/// This sealed class surfaces those as discrete events so the [AgentService]
/// loop can append tool events as they appear without re-parsing SSE.
///
/// Claude Code CLI transport adds richer variants: [TextDelta], [ToolUseStart],
/// [ToolUseInputDelta], [ToolUseComplete], [ToolResult], [ThinkingDelta],
/// [StreamDone], [StreamParseFailure], [StreamError]. These coexist with the
/// OpenAI-oriented `StreamTextDelta`/`StreamToolCall*`/`StreamFinish` variants
/// used by `custom_remote_datasource_dio.dart`.
@freezed
sealed class StreamEvent with _$StreamEvent {
  // ---- OpenAI wire-format variants (custom_remote_datasource_dio) ----
  const factory StreamEvent.textDelta(String text) = StreamTextDelta;
  const factory StreamEvent.toolCallStart({required String id, required String name}) = StreamToolCallStart;
  const factory StreamEvent.toolCallArgsDelta({required String id, required String argsJsonFragment}) =
      StreamToolCallArgsDelta;
  const factory StreamEvent.toolCallEnd({required String id}) = StreamToolCallEnd;

  /// OpenAI `finish_reason` — typically "stop", "tool_calls", or "length".
  const factory StreamEvent.finish({required String reason}) = StreamFinish;

  // ---- Claude Code CLI variants (claude_cli_stream_parser) ----
  const factory StreamEvent.cliTextDelta(String text) = TextDelta;
  const factory StreamEvent.cliToolUseStart({required String id, required String name}) = ToolUseStart;
  const factory StreamEvent.cliToolUseInputDelta({required String id, required String partialJson}) = ToolUseInputDelta;
  const factory StreamEvent.cliToolUseComplete({required String id, required Map<String, dynamic> input}) =
      ToolUseComplete;
  const factory StreamEvent.cliToolResult({required String toolUseId, required String content, required bool isError}) =
      ToolResult;
  const factory StreamEvent.cliThinkingDelta(String text) = ThinkingDelta;
  const factory StreamEvent.cliStreamDone() = StreamDone;
  const factory StreamEvent.cliStreamParseFailure({required String line, required Object error}) = StreamParseFailure;
  const factory StreamEvent.cliStreamError(Object failure) = StreamError;
}
