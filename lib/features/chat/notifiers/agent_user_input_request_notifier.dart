import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/ai/models/provider_runtime_event.dart';

part 'agent_user_input_request_notifier.g.dart';

/// Outcome of awaiting a `ProviderUserInputRequest` resolution. Distinguishes
/// user-initiated cancel (which should tear down the turn) from preemption by
/// a follow-up question on the same session (which should leave the turn alive
/// — the second await is now in flight and will resolve normally).
sealed class AgentUserInputResult {
  const AgentUserInputResult();
  const factory AgentUserInputResult.answer(String text) = AgentUserInputAnswer;
  const factory AgentUserInputResult.cancelled() = AgentUserInputCancelled;
  const factory AgentUserInputResult.preempted() = AgentUserInputPreempted;
}

class AgentUserInputAnswer extends AgentUserInputResult {
  const AgentUserInputAnswer(this.text);
  final String text;
}

class AgentUserInputCancelled extends AgentUserInputResult {
  const AgentUserInputCancelled();
}

class AgentUserInputPreempted extends AgentUserInputResult {
  const AgentUserInputPreempted();
}

/// Per-session notifier holding any in-flight agent question for that session.
/// Family-keyed by sessionId — concurrent sessions cannot trample each other,
/// and tab-switching while a question is open no longer routes the answer to
/// the wrong session.
@Riverpod(keepAlive: true)
class AgentUserInputRequestNotifier extends _$AgentUserInputRequestNotifier {
  Completer<AgentUserInputResult>? _pending;

  @override
  ProviderUserInputRequest? build(String sessionId) {
    ref.onDispose(() {
      final pending = _pending;
      _pending = null;
      if (pending != null && !pending.isCompleted) {
        pending.complete(const AgentUserInputResult.cancelled());
      }
    });
    return null;
  }

  /// Starts (or replaces) the pending request for this session and returns a
  /// future that resolves with the user's answer, a preempt notice (if a new
  /// request displaces this one), or cancellation.
  Future<AgentUserInputResult> requestAndAwait(ProviderUserInputRequest req) {
    final prior = _pending;
    if (prior != null && !prior.isCompleted) {
      prior.complete(const AgentUserInputResult.preempted());
    }
    final completer = Completer<AgentUserInputResult>();
    _pending = completer;
    state = req;
    return completer.future;
  }

  void submit(String answer) {
    final pending = _pending;
    _pending = null;
    state = null;
    if (pending != null && !pending.isCompleted) {
      pending.complete(AgentUserInputResult.answer(answer));
    }
  }

  void cancel() {
    final pending = _pending;
    _pending = null;
    state = null;
    if (pending != null && !pending.isCompleted) {
      pending.complete(const AgentUserInputResult.cancelled());
    }
  }
}
