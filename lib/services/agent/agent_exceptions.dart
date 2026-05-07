/// Typed exceptions thrown by [AgentService] and [SessionService] when the
/// agentic loop cannot proceed. [ChatMessagesNotifier] maps them into the
/// UI-facing [AgentFailure] union (`lib/data/chat/models/agent_failure.dart`).
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

/// Thrown when the user picked a CLI transport whose datasource is not
/// registered (e.g. providerId="claude-cli" but no provider). Previously the
/// path silently fell through to HTTP, which routed user-selected CLI traffic
/// through API keys without any UI signal.
class ProviderUnavailableException extends AgentException {
  ProviderUnavailableException(this.providerId);
  final String providerId;
  @override
  String toString() =>
      'Selected provider "$providerId" is not available — try restarting the app or reselecting the transport.';
}
