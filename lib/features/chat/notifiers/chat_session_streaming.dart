import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/chat/chat_stream_registry_service.dart';
import '../../../services/chat/chat_stream_state.dart';

part 'chat_session_streaming.g.dart';

@riverpod
Stream<bool> chatSessionStreaming(Ref ref, String sessionId) {
  final svc = ref.watch(chatStreamRegistryServiceProvider);
  return svc
      .watchState(sessionId)
      .map((s) => s is ChatStreamConnecting || s is ChatStreamStreaming || s is ChatStreamRetrying);
}

@riverpod
Stream<bool> chatSessionFailed(Ref ref, String sessionId) {
  final svc = ref.watch(chatStreamRegistryServiceProvider);
  return svc.watchState(sessionId).map((s) => s is ChatStreamFailed);
}

/// Whether the session is waiting for user input (permission or question).
/// Derived entirely from in-memory registry data — no SQLite load.
@riverpod
Stream<bool> chatSessionAwaiting(Ref ref, String sessionId) {
  final svc = ref.watch(chatStreamRegistryServiceProvider);
  final ctrl = StreamController<bool>();

  bool isAwaiting(Object? msg) {
    if (msg == null) return false;
    final m = msg as dynamic;
    return (m.pendingPermissionRequest != null) || (m.askQuestion != null);
  }

  final seed = svc.liveMessagesFor(sessionId);
  if (seed.isNotEmpty) ctrl.add(isAwaiting(seed.last));

  final msgSub = svc.watchMessages(sessionId).listen((msg) {
    if (!ctrl.isClosed) ctrl.add(isAwaiting(msg));
  });

  final stateSub = svc.watchState(sessionId).listen((s) {
    if (!ctrl.isClosed && (s is ChatStreamIdle || s is ChatStreamDone)) {
      ctrl.add(false);
    }
  });

  ref.onDispose(() {
    msgSub.cancel();
    stateSub.cancel();
    ctrl.close();
  });

  return ctrl.stream;
}
