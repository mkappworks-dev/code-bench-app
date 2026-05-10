/// Domain interface for forwarding user responses back into in-flight CLI sessions.
abstract interface class AIProviderRepository {
  void respondToPermissionRequest(String sessionId, String requestId, {required bool approved});

  /// Routes the response to the [providerId] datasource only — the request
  /// carries that id (see [ProviderUserInputRequest.providerId]) so we can
  /// avoid the broadcast-and-hope pattern that drowned valid responses in
  /// "no pending request" log lines from sibling providers.
  bool respondToUserInputRequest(String providerId, String sessionId, String requestId, {required String response});
}
