import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/ai/models/provider_runtime_event.dart';

part 'agent_user_input_request_notifier.g.dart';

@Riverpod(keepAlive: true)
class AgentUserInputRequestNotifier extends _$AgentUserInputRequestNotifier {
  Completer<String?>? _pending;

  @override
  ProviderUserInputRequest? build() => null;

  /// Stores the request and returns a future that resolves when the user
  /// answers (string) or cancels (null).
  Future<String?> requestAndAwait(ProviderUserInputRequest req) {
    _pending?.complete(null); // implicitly cancel any prior pending
    _pending = Completer<String?>();
    state = req;
    return _pending!.future;
  }

  void submit(String answer) {
    _pending?.complete(answer);
    _pending = null;
    state = null;
  }

  void cancel() {
    _pending?.complete(null);
    _pending = null;
    state = null;
  }
}
