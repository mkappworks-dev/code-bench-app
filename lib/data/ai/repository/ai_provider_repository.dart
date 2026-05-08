/// Domain interface for interacting with a pluggable AI provider at runtime —
/// forwarding user responses back into in-flight CLI sessions.
abstract interface class AIProviderRepository {
  void respondToPermissionRequest(String sessionId, String requestId, {required bool approved});

  void respondToUserInputRequest(String sessionId, String requestId, {required String response});
}
