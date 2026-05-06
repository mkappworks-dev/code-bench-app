import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/chat/models/agent_failure.dart';
import '../../data/shared/chat_message.dart';
import '../agent/agent_exceptions.dart';
import 'chat_stream_state.dart';

part 'chat_stream_service.g.dart';

@Riverpod(keepAlive: true)
ChatStreamService chatStreamService(Ref ref) {
  final registry = ChatStreamService();
  ref.onDispose(registry.dispose);
  return registry;
}

class ChatStreamService {
  final Map<String, _StreamHandle> _handles = {};

  static const _defaultBackoff = [Duration(milliseconds: 500), Duration(seconds: 1), Duration(seconds: 2)];

  ChatStreamState latestState(String sessionId) => _handles[sessionId]?.latest ?? const ChatStreamState.idle();

  Stream<ChatStreamState> watchState(String sessionId) {
    final handle = _handles.putIfAbsent(sessionId, () => _StreamHandle(sessionId));
    return handle.stateStream;
  }

  void start({
    required String sessionId,
    required Stream<ChatMessage> Function() streamFactory,
    required void Function(ChatMessage) onMessage,
    List<Duration> backoff = _defaultBackoff,
  }) {
    if (sessionId.isEmpty) {
      throw ArgumentError.value(sessionId, 'sessionId', 'must be non-empty');
    }
    final handle = _handles.putIfAbsent(sessionId, () => _StreamHandle(sessionId));
    if (handle.subscription != null) return;
    _attemptConnect(handle, streamFactory, onMessage, backoff, attempt: 1);
  }

  void _attemptConnect(
    _StreamHandle handle,
    Stream<ChatMessage> Function() streamFactory,
    void Function(ChatMessage) onMessage,
    List<Duration> backoff, {
    required int attempt,
  }) {
    handle._emit(ChatStreamState.connecting(attempt: attempt));
    var sawChunk = false;

    handle.subscription = streamFactory().listen(
      (msg) {
        if (msg.sessionId != handle.sessionId) {
          assert(() {
            // ignore: avoid_print
            print(
              '[ChatStreamService] dropped cross-session chunk: '
              'expected=${handle.sessionId} got=${msg.sessionId}',
            );
            return true;
          }());
          return;
        }
        sawChunk = true;
        if (handle.latest is! ChatStreamStreaming) {
          handle._emit(const ChatStreamState.streaming());
        }
        onMessage(msg);
      },
      onError: (Object e, StackTrace st) {
        final isRetryable = !sawChunk && (e is NetworkException || e is TimeoutException);
        final shouldRetry = isRetryable && attempt <= backoff.length;
        if (shouldRetry) {
          final delay = backoff[attempt - 1];
          // scheduleMicrotask defers the emit until after the stateStream async*
          // generator has subscribed to the broadcast controller via yield*.
          scheduleMicrotask(() {
            if (handle._controller.isClosed) return;
            handle._emit(ChatStreamState.retrying(attempt: attempt, nextDelay: delay));
            handle.retryTimer?.cancel();
            handle.retryTimer = Timer(delay, () {
              if (handle._controller.isClosed) return;
              _attemptConnect(handle, streamFactory, onMessage, backoff, attempt: attempt + 1);
            });
          });
        } else {
          final failure = isRetryable ? AgentFailure.networkExhausted(attempt) : _mapError(e);
          handle._emit(ChatStreamState.failed(failure));
          handle.subscription = null;
        }
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
    handle.retryTimer?.cancel();
    handle.retryTimer = null;
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
  Timer? retryTimer;
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
    retryTimer?.cancel();
    await subscription?.cancel();
    await _controller.close();
  }
}
