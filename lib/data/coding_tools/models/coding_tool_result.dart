/// Normalized result of executing one tool call. Converted to a `tool_result`
/// message in the OpenAI wire history by [AgentService] before the next round.
class CodingToolResult {
  const CodingToolResult._({this.output, this.error}) : assert((output == null) != (error == null));

  const factory CodingToolResult.success(String output) = _CodingToolResultSuccess;
  const factory CodingToolResult.error(String message) = _CodingToolResultError;

  final String? output;
  final String? error;

  bool get isSuccess => output != null;
}

class _CodingToolResultSuccess extends CodingToolResult {
  const _CodingToolResultSuccess(String output) : super._(output: output);
}

class _CodingToolResultError extends CodingToolResult {
  const _CodingToolResultError(String message) : super._(error: message);
}
