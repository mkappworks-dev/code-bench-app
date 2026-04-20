/// Typed exceptions thrown by [AgentService] and [SessionService] when the
/// agentic loop cannot proceed. These live in the services layer so the
/// services never depend on `lib/features/`. [ChatMessagesNotifier] maps
/// them into the UI-facing [AgentFailure] union (`lib/features/chat/notifiers/
/// agent_failure.dart`).
sealed class AgentException implements Exception {}

/// Thrown from [SessionService.sendAndStream] when `ChatMode.act` is used with
/// a provider that does not speak the OpenAI tool-calling wire shape.
class ProviderDoesNotSupportToolsException extends AgentException {
  @override
  String toString() => 'Provider does not support tool use';
}

/// Thrown when the SSE stream terminates with a [finishReason] other than
/// `stop` or `tool_calls` (e.g. `length`, `content_filter`, or `null`). The
/// in-flight assistant snapshot is still yielded before this is thrown, so
/// the user sees whatever content arrived.
class StreamAbortedUnexpectedlyException extends AgentException {
  StreamAbortedUnexpectedlyException(this.reason);
  final String reason;
  @override
  String toString() => 'Agent stream aborted unexpectedly: $reason';
}
