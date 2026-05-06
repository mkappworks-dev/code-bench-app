import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'chat_stream_state.dart';

part 'chat_stream_registry.g.dart';

@Riverpod(keepAlive: true)
ChatStreamRegistry chatStreamRegistry(Ref ref) {
  final registry = ChatStreamRegistry();
  ref.onDispose(registry.dispose);
  return registry;
}

class ChatStreamRegistry {
  final Map<String, _StreamHandle> _handles = {};

  ChatStreamState latestState(String sessionId) => _handles[sessionId]?.latest ?? const ChatStreamState.idle();

  Stream<ChatStreamState> watchState(String sessionId) {
    final handle = _handles.putIfAbsent(sessionId, () => _StreamHandle(sessionId));
    return handle.stateStream;
  }

  Future<void> dispose() async {
    for (final h in _handles.values) {
      await h.dispose();
    }
    _handles.clear();
  }
}

class _StreamHandle {
  _StreamHandle(this.sessionId);

  final String sessionId;
  final StreamController<ChatStreamState> _controller = StreamController<ChatStreamState>.broadcast();
  ChatStreamState latest = const ChatStreamState.idle();

  Stream<ChatStreamState> get stateStream async* {
    yield latest;
    yield* _controller.stream;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
