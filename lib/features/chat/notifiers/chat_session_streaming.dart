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
