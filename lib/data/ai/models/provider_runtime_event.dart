/// Canonical event emitted by all AI provider datasources.
/// Normalized from each provider's native wire format so the UI layer
/// never needs to know which provider is active.
sealed class ProviderRuntimeEvent {
  const ProviderRuntimeEvent();
}

/// Provider initialized; sending message to remote service.
class ProviderInit extends ProviderRuntimeEvent {
  const ProviderInit({required this.provider, this.modelId});
  final String provider; // e.g. "claude-cli", "codex"
  final String? modelId;
}

/// Assistant text chunk (token-by-token streaming).
class ProviderTextDelta extends ProviderRuntimeEvent {
  const ProviderTextDelta({required this.text});
  final String text;
}

/// Thinking block content (if model supports thinking).
class ProviderThinkingDelta extends ProviderRuntimeEvent {
  const ProviderThinkingDelta({required this.thinking});
  final String thinking;
}

/// Tool use started (e.g. "read_file" with id "toolu_123").
class ProviderToolUseStart extends ProviderRuntimeEvent {
  const ProviderToolUseStart({required this.toolId, required this.toolName});
  final String toolId;
  final String toolName;
}

/// Tool input JSON chunk (accumulated across deltas).
class ProviderToolInputDelta extends ProviderRuntimeEvent {
  const ProviderToolInputDelta({required this.toolId, required this.partialJson});
  final String toolId;
  final String partialJson;
}

/// Tool input JSON complete; ready to execute.
class ProviderToolUseComplete extends ProviderRuntimeEvent {
  const ProviderToolUseComplete({required this.toolId, required this.input});
  final String toolId;
  final Map<String, dynamic> input;
}

/// Permission request: user must approve tool use before execution.
/// UI shows a card with tool name, input preview, and allow/deny buttons.
class ProviderPermissionRequest extends ProviderRuntimeEvent {
  const ProviderPermissionRequest({required this.requestId, required this.toolName, required this.toolInput});
  final String requestId; // UUID; passed back to provider on approval
  final String toolName;
  final Map<String, dynamic> toolInput;
}

/// Stream ended successfully.
class ProviderStreamDone extends ProviderRuntimeEvent {
  const ProviderStreamDone();
}

/// Stream ended with error.
class ProviderStreamFailure extends ProviderRuntimeEvent {
  const ProviderStreamFailure({required this.error, this.details});
  final Object error;
  final String? details;
}

/// Agent-initiated request for typed user input (not a yes/no approval).
/// UI shows a question card with [prompt], optional [choices], and a
/// free-text fallback. The reply travels back through
/// `respondToUserInputRequest({response: <answer>})`. [providerId] and
/// [sessionId] are stamped so the response can be routed to the originating
/// datasource without broadcast (avoids cross-provider spillover).
class ProviderUserInputRequest extends ProviderRuntimeEvent {
  const ProviderUserInputRequest({
    required this.requestId,
    required this.prompt,
    required this.providerId,
    required this.sessionId,
    this.choices,
    this.defaultValue,
  });
  final String requestId;
  final String prompt;
  final String providerId;
  final String sessionId;
  final List<String>? choices;
  final String? defaultValue;
}
