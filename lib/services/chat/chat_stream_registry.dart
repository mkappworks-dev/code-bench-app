import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/chat/models/agent_failure.dart';
import '../../data/shared/chat_message.dart';
import '../agent/agent_exceptions.dart';
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

  /// Begins a stream for [sessionId]. If a stream is already active for that
  /// session, this is a no-op (the caller must `cancel` first).
  void start({
    required String sessionId,
    required Stream<ChatMessage> Function() streamFactory,
    required void Function(ChatMessage) onMessage,
  }) {
    if (sessionId.isEmpty) {
      throw ArgumentError.value(sessionId, 'sessionId', 'must be non-empty');
    }
    final handle = _handles.putIfAbsent(sessionId, () => _StreamHandle(sessionId));
    if (handle.subscription != null) return; // already active
    handle._emit(const ChatStreamState.connecting(attempt: 1));
    handle.subscription = streamFactory().listen(
      (msg) {
        if (msg.sessionId != sessionId) {
          assert(() {
            // ignore: avoid_print
            print(
              '[ChatStreamRegistry] dropped cross-session chunk: '
              'expected=$sessionId got=${msg.sessionId}',
            );
            return true;
          }());
          return;
        }
        if (handle.latest is! ChatStreamStreaming) {
          handle._emit(const ChatStreamState.streaming());
        }
        onMessage(msg);
      },
      onError: (Object e, StackTrace st) {
        handle._emit(ChatStreamState.failed(_mapError(e)));
        handle.subscription = null;
      },
      onDone: () {
        handle._emit(const ChatStreamState.done());
        handle.subscription = null;
      },
      cancelOnError: true,
    );
  }

  AgentFailure _mapError(Object e) => switch (e) {
    ProviderDoesNotSupportToolsException() => const AgentFailure.providerDoesNotSupportTools(),
    StreamAbortedUnexpectedlyException(:final reason) => AgentFailure.streamAbortedUnexpectedly(reason),
    _ => AgentFailure.unknown(e),
  };

  Future<void> cancel(String sessionId) async {
    final handle = _handles[sessionId];
    if (handle == null) return;
    await handle.subscription?.cancel();
    handle.subscription = null;
    handle._emit(const ChatStreamState.idle());
  }

  Future<void> cancelAll() async {
    for (final id in _handles.keys.toList()) {
      await cancel(id);
    }
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
  StreamSubscription<ChatMessage>? subscription;
  ChatStreamState latest = const ChatStreamState.idle();

  Stream<ChatStreamState> get stateStream async* {
    yield latest;
    yield* _controller.stream;
  }

  void _emit(ChatStreamState s) {
    latest = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  Future<void> dispose() async {
    await subscription?.cancel();
    await _controller.close();
  }
}
