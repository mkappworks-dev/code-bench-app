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
}
