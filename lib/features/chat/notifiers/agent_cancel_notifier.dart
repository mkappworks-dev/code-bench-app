import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agent_cancel_notifier.g.dart';

/// Cooperative per-session cancel flags read by [AgentService] / [ChatStreamService] at each tool boundary; tracking by sessionId stops one chat's stop-button from cancelling concurrent chats' streams.
@Riverpod(keepAlive: true)
class AgentCancelNotifier extends _$AgentCancelNotifier {
  @override
  Set<String> build() => const <String>{};

  void request(String sessionId) {
    if (state.contains(sessionId)) return;
    state = {...state, sessionId};
  }

  void clear(String sessionId) {
    if (!state.contains(sessionId)) return;
    state = state.where((id) => id != sessionId).toSet();
  }

  /// Stable accessor for closures captured by `ChatStreamService` — `ref.read` would throw after the originating notifier disposes.
  bool isCancelled(String sessionId) => state.contains(sessionId);
}
