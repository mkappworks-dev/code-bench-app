import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_event.freezed.dart';

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
