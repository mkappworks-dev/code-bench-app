import 'package:freezed_annotation/freezed_annotation.dart';

part 'tool_event.freezed.dart';
part 'tool_event.g.dart';

@freezed
abstract class ToolEvent with _$ToolEvent {
  const factory ToolEvent({
    required String type,
    required String toolName,
    @Default({}) Map<String, dynamic> input,
    String? output,
    String? filePath,
    int? durationMs,
    int? tokensIn,
    int? tokensOut,
  }) = _ToolEvent;

  factory ToolEvent.fromJson(Map<String, dynamic> json) => _$ToolEventFromJson(json);
}
