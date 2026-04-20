import 'package:freezed_annotation/freezed_annotation.dart';

part 'coding_tool_result.freezed.dart';

/// Normalized result of executing one tool call. Converted to a `tool_result`
/// message in the OpenAI wire history by [AgentService] before the next round.
@freezed
sealed class CodingToolResult with _$CodingToolResult {
  const factory CodingToolResult.success(String output) = CodingToolResultSuccess;
  const factory CodingToolResult.error(String message) = CodingToolResultError;
}
