import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_event.freezed.dart';

/// Provider-agnostic stream event emitted by [AIRepository.streamMessageWithTools].
///
/// The OpenAI wire format interleaves content deltas and tool-call deltas.
/// This sealed class surfaces those as discrete events so the [AgentService]
/// loop can append tool events as they appear without re-parsing SSE.
@freezed
sealed class StreamEvent with _$StreamEvent {
  const factory StreamEvent.textDelta(String text) = StreamTextDelta;
  const factory StreamEvent.toolCallStart({required String id, required String name}) = StreamToolCallStart;
  const factory StreamEvent.toolCallArgsDelta({required String id, required String argsJsonFragment}) =
      StreamToolCallArgsDelta;
  const factory StreamEvent.toolCallEnd({required String id}) = StreamToolCallEnd;

  /// OpenAI `finish_reason` — typically "stop", "tool_calls", or "length".
  const factory StreamEvent.finish({required String reason}) = StreamFinish;
}
