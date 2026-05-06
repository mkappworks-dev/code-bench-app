import 'dart:async';

import 'package:code_bench_app/core/errors/app_exception.dart';
import 'package:code_bench_app/data/chat/models/agent_failure.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/services/chat/chat_stream_service.dart';
import 'package:code_bench_app/services/chat/chat_stream_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessage _msg(String id, {String sessionId = 's'}) => ChatMessage(
  id: id,
  sessionId: sessionId,
  role: MessageRole.assistant,
  content: 'hi',
  timestamp: DateTime(2026, 5, 6),
);

void main() {
  test('latestState returns idle for unknown sessions', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final registry = container.read(chatStreamServiceProvider);
    expect(registry.latestState('unknown'), isA<ChatStreamIdle>());
  });

  test('watchState emits the current state immediately', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final registry = container.read(chatStreamServiceProvider);
    final first = await registry.watchState('s').first;
    expect(first, isA<ChatStreamIdle>());
  });

  group('start', () {
    test('start emits connecting → streaming → done as chunks arrive', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(chatStreamServiceProvider);

      final source = StreamController<ChatMessage>();
      final states = <ChatStreamState>[];
      final sub = registry.watchState('s').listen(states.add);
      addTearDown(sub.cancel);

      final messages = <ChatMessage>[];
      registry.start(sessionId: 's', streamFactory: () => source.stream, onMessage: messages.add);

      await Future<void>.delayed(Duration.zero);
      expect(states.last, isA<ChatStreamConnecting>());

      source.add(_msg('a'));
      await Future<void>.delayed(Duration.zero);
      expect(states.last, isA<ChatStreamStreaming>());
      expect(messages, hasLength(1));

      await source.close();
      await Future<void>.delayed(Duration.zero);
      expect(states.last, isA<ChatStreamDone>());
    });

    test('start drops chunks whose sessionId does not match', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(chatStreamServiceProvider);
      final source = StreamController<ChatMessage>();
      final messages = <ChatMessage>[];

      registry.start(sessionId: 's', streamFactory: () => source.stream, onMessage: messages.add);

      source.add(_msg('a', sessionId: 'OTHER'));
      source.add(_msg('b', sessionId: 's'));
      await source.close();
      await Future<void>.delayed(Duration.zero);

      expect(messages.map((m) => m.id), ['b']);
    });
  });

  group('cancel', () {
    test('cancel stops the subscription and emits idle', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(chatStreamServiceProvider);
      final source = StreamController<ChatMessage>();
      final states = <ChatStreamState>[];
      registry.watchState('s').listen(states.add);
      registry.start(sessionId: 's', streamFactory: () => source.stream, onMessage: (_) {});
      await Future<void>.delayed(Duration.zero);
      source.add(_msg('a'));
      await Future<void>.delayed(Duration.zero);

      await registry.cancel('s');
      expect(registry.latestState('s'), isA<ChatStreamIdle>());

      final received = <ChatMessage>[];
      source.add(_msg('b'));
      await Future<void>.delayed(Duration.zero);
      expect(received, isEmpty);
    });

    test('cancelAll stops every active session', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(chatStreamServiceProvider);
      final s1 = StreamController<ChatMessage>();
      final s2 = StreamController<ChatMessage>();
      registry.start(sessionId: 'a', streamFactory: () => s1.stream, onMessage: (_) {});
      registry.start(sessionId: 'b', streamFactory: () => s2.stream, onMessage: (_) {});
      await Future<void>.delayed(Duration.zero);

      await registry.cancelAll();
      expect(registry.latestState('a'), isA<ChatStreamIdle>());
      expect(registry.latestState('b'), isA<ChatStreamIdle>());
    });
  });

  group('retry', () {
    test('retries on NetworkException before any chunk arrives', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(chatStreamServiceProvider);

      var calls = 0;
      Stream<ChatMessage> factory() async* {
        calls++;
        if (calls < 3) {
          throw NetworkException('flaky');
        }
        yield _msg('ok');
      }

      final states = <ChatStreamState>[];
      registry.watchState('s').listen(states.add);
      final received = <ChatMessage>[];
      registry.start(
        sessionId: 's',
        streamFactory: factory,
        onMessage: received.add,
        backoff: const [Duration(milliseconds: 1), Duration(milliseconds: 1)],
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, 3);
      expect(received.single.id, 'ok');
      expect(states.whereType<ChatStreamRetrying>(), hasLength(2));
      expect(states.last, isA<ChatStreamDone>());
    });

    test('after retries are exhausted, emits failed(networkExhausted)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(chatStreamServiceProvider);

      Stream<ChatMessage> factory() async* {
        throw NetworkException('still flaky');
      }

      final states = <ChatStreamState>[];
      registry.watchState('s').listen(states.add);
      registry.start(
        sessionId: 's',
        streamFactory: factory,
        onMessage: (_) {},
        backoff: const [Duration(milliseconds: 1), Duration(milliseconds: 1)],
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final failed = states.last as ChatStreamFailed;
      expect(failed.failure, isA<AgentNetworkExhausted>());
      expect((failed.failure as AgentNetworkExhausted).attempts, 3);
    });

    test('errors after first chunk arrives are NOT retried', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(chatStreamServiceProvider);

      var calls = 0;
      Stream<ChatMessage> factory() async* {
        calls++;
        yield _msg('partial');
        throw NetworkException('drop after partial');
      }

      final states = <ChatStreamState>[];
      registry.watchState('s').listen(states.add);
      registry.start(
        sessionId: 's',
        streamFactory: factory,
        onMessage: (_) {},
        backoff: const [Duration(milliseconds: 1)],
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, 1);
      expect(states.last, isA<ChatStreamFailed>());
      expect((states.last as ChatStreamFailed).failure, isNot(isA<AgentNetworkExhausted>()));
    });
  });
}
