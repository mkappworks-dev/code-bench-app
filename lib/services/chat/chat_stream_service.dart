import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/debug_logger.dart';
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
    void Function()? onCancel,
    List<Duration> backoff = _defaultBackoff,
  }) {
    if (sessionId.isEmpty) {
      throw ArgumentError.value(sessionId, 'sessionId', 'must be non-empty');
    }
    final handle = _handles.putIfAbsent(sessionId, () => _StreamHandle(sessionId));
    // Block re-entry while either an active subscription or a pending retry timer exists — the timer keeps the connect-loop alive even after `cancelOnError: true` clears the subscription.
    if (handle.subscription != null || handle.retryTimer != null) return;
    handle.onCancel = onCancel;
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
          dLog(
            '[ChatStreamService] dropped cross-session chunk: '
            'expected=${handle.sessionId} got=${msg.sessionId}',
          );
          return;
        }
        sawChunk = true;
        if (handle.latest is! ChatStreamStreaming) {
          handle._emit(const ChatStreamState.streaming());
        }
        onMessage(msg);
      },
      onError: (Object e, StackTrace st) {
        // `cancelOnError: true` invalidates the subscription on error — drop our reference synchronously so a re-entrant `start()` during the retry window isn't blocked by a stale handle.
        handle.subscription = null;
        final isRetryable = !sawChunk && (e is NetworkException || e is TimeoutException);
        final shouldRetry = isRetryable && attempt <= backoff.length;
        if (shouldRetry) {
          final delay = backoff[attempt - 1];
          scheduleMicrotask(() {
            if (handle._controller.isClosed) return;
            handle._emit(ChatStreamState.retrying(attempt: attempt, nextDelay: delay));
            handle.retryTimer?.cancel();
            handle.retryTimer = Timer(delay, () {
              handle.retryTimer = null;
              if (handle._controller.isClosed) return;
              _attemptConnect(handle, streamFactory, onMessage, backoff, attempt: attempt + 1);
            });
          });
        } else {
          final failure = isRetryable ? AgentFailure.networkExhausted(attempt) : _mapError(e);
          handle._emit(ChatStreamState.failed(failure));
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
    // Invoke first so the underlying transport (e.g. Claude CLI process) is signalled to stop before we tear down the Dart subscription that might otherwise outrun it.
    handle.onCancel?.call();
    handle.onCancel = null;
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
  void Function()? onCancel;
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
