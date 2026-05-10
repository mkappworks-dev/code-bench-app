import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/shared/chat_message.dart';
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

  bool isAwaiting(ChatMessage? msg) {
    if (msg == null) return false;
    return msg.pendingPermissionRequest != null || msg.askQuestion != null;
  }

  final seed = svc.liveMessagesFor(sessionId);
  if (seed.isNotEmpty) ctrl.add(isAwaiting(seed.last));

  final msgSub = svc
      .watchMessages(sessionId)
      .listen(
        (msg) {
          if (!ctrl.isClosed) ctrl.add(isAwaiting(msg));
        },
        onError: (Object e) {
          // Don't drop the subscription on a stray error — the sidebar status dot would freeze for the rest of the session lifetime. Log and treat as not-awaiting so the dot doesn't get stuck "on".
          dLog('[chatSessionAwaiting] watchMessages error: ${e.runtimeType}');
          if (!ctrl.isClosed) ctrl.add(false);
        },
      );

  final stateSub = svc
      .watchState(sessionId)
      .listen(
        (s) {
          if (!ctrl.isClosed && (s is ChatStreamIdle || s is ChatStreamDone)) {
            ctrl.add(false);
          }
        },
        onError: (Object e) {
          dLog('[chatSessionAwaiting] watchState error: ${e.runtimeType}');
        },
      );

  ref.onDispose(() {
    msgSub.cancel();
    stateSub.cancel();
    ctrl.close();
  });

  return ctrl.stream;
}
