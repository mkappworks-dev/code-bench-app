import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/session/models/permission_request.dart';

part 'agent_permission_request_notifier.g.dart';

@Riverpod(keepAlive: true)
class AgentPermissionRequestNotifier extends _$AgentPermissionRequestNotifier {
  Completer<bool>? _completer;

  @override
  PermissionRequest? build() => null;

  Future<bool> request(PermissionRequest req) {
    _completer?.complete(false);
    _completer = Completer<bool>();
    state = req;
    return _completer!.future;
  }

  void resolve(bool approved) {
    _completer?.complete(approved);
    _completer = null;
    state = null;
  }

  /// Completes any in-flight permission request with `false` and clears the
  /// dialog. Used by [ChatMessagesNotifier.cancelSend] so cancelling a turn
  /// that is currently awaiting user approval unblocks the agent loop rather
  /// than leaving it wedged until the dialog is manually dismissed.
  void cancel() {
    if (_completer == null && state == null) return;
    _completer?.complete(false);
    _completer = null;
    state = null;
  }
}
