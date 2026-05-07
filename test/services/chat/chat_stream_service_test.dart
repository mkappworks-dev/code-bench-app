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
    test('cancel invokes the onCancel callback supplied to start', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(chatStreamServiceProvider);
      final source = StreamController<ChatMessage>();
      var cancelled = 0;
      registry.start(
        sessionId: 's',
        streamFactory: () => source.stream,
        onMessage: (_) {},
        onCancel: () => cancelled++,
      );
      await Future<void>.delayed(Duration.zero);

      await registry.cancel('s');
      expect(cancelled, 1);
    });

    test('cancelAll invokes onCancel for every active session', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(chatStreamServiceProvider);
      final s1 = StreamController<ChatMessage>();
      final s2 = StreamController<ChatMessage>();
      var cancelledA = 0;
      var cancelledB = 0;
      registry.start(sessionId: 'a', streamFactory: () => s1.stream, onMessage: (_) {}, onCancel: () => cancelledA++);
      registry.start(sessionId: 'b', streamFactory: () => s2.stream, onMessage: (_) {}, onCancel: () => cancelledB++);
      await Future<void>.delayed(Duration.zero);

      await registry.cancelAll();
      expect(cancelledA, 1);
      expect(cancelledB, 1);
    });

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

    test('cancel during retry-backoff lets a fresh start attach a new listener', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(chatStreamServiceProvider);

      var firstFactoryCalls = 0;
      Stream<ChatMessage> firstFactory() async* {
        firstFactoryCalls++;
        throw NetworkException('flaky');
      }

      registry.start(
        sessionId: 's',
        streamFactory: firstFactory,
        onMessage: (_) {},
        backoff: const [Duration(milliseconds: 50)],
      );
      // Give the first attempt time to fail and schedule a retry timer.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(firstFactoryCalls, 1);

      await registry.cancel('s');

      var secondFactoryCalls = 0;
      Stream<ChatMessage> secondFactory() async* {
        secondFactoryCalls++;
        yield _msg('ok');
      }

      registry.start(sessionId: 's', streamFactory: secondFactory, onMessage: (_) {});
      // Wait long enough that the original retry timer would have fired if it weren't cancelled.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(secondFactoryCalls, 1, reason: 'fresh start must attach a new listener after cancel');
      expect(firstFactoryCalls, 1, reason: 'cancelled retry timer must not re-invoke the original factory');
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

  group('liveMessagesFor / watchMessages', () {
    test('liveMessagesFor returns messages in insertion order during streaming', () async {
      final service = ChatStreamService();
      addTearDown(service.dispose);
      final ctrl = StreamController<ChatMessage>();
      final received = <ChatMessage>[];

      service.start(sessionId: 'sid', streamFactory: () => ctrl.stream, onMessage: received.add);

      final msg1 = ChatMessage(
        id: 'a',
        sessionId: 'sid',
        role: MessageRole.user,
        content: 'hello',
        timestamp: DateTime.now(),
      );
      final msg2 = ChatMessage(
        id: 'b',
        sessionId: 'sid',
        role: MessageRole.assistant,
        content: 'hi',
        timestamp: DateTime.now(),
      );
      ctrl.add(msg1);
      await Future<void>.delayed(Duration.zero);
      ctrl.add(msg2);
      await Future<void>.delayed(Duration.zero);

      final live = service.liveMessagesFor('sid');
      expect(live.map((m) => m.id), ['a', 'b']);

      await ctrl.close();
    });

    test('liveMessagesFor replaces in place when an msg.id repeats (streaming update)', () async {
      final service = ChatStreamService();
      addTearDown(service.dispose);
      final ctrl = StreamController<ChatMessage>();

      service.start(sessionId: 'sid', streamFactory: () => ctrl.stream, onMessage: (_) {});

      final base = DateTime.now();
      ctrl.add(ChatMessage(id: 'a', sessionId: 'sid', role: MessageRole.assistant, content: 'pa', timestamp: base));
      await Future<void>.delayed(Duration.zero);
      ctrl.add(ChatMessage(id: 'a', sessionId: 'sid', role: MessageRole.assistant, content: 'parti', timestamp: base));
      await Future<void>.delayed(Duration.zero);

      final live = service.liveMessagesFor('sid');
      expect(live, hasLength(1));
      expect(live.first.content, 'parti');

      await ctrl.close();
    });

    test('liveMessagesFor survives stream completion', () async {
      final service = ChatStreamService();
      addTearDown(service.dispose);
      final ctrl = StreamController<ChatMessage>();

      service.start(sessionId: 'sid', streamFactory: () => ctrl.stream, onMessage: (_) {});

      ctrl.add(
        ChatMessage(id: 'a', sessionId: 'sid', role: MessageRole.assistant, content: 'done', timestamp: DateTime.now()),
      );
      await ctrl.close();
      await Future<void>.delayed(Duration.zero);

      expect(service.liveMessagesFor('sid'), hasLength(1));
    });

    test('liveMessagesFor survives manual cancel', () async {
      final service = ChatStreamService();
      addTearDown(service.dispose);
      final ctrl = StreamController<ChatMessage>();

      service.start(sessionId: 'sid', streamFactory: () => ctrl.stream, onMessage: (_) {});
      ctrl.add(
        ChatMessage(
          id: 'a',
          sessionId: 'sid',
          role: MessageRole.assistant,
          content: 'partial',
          timestamp: DateTime.now(),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await service.cancel('sid');

      expect(service.liveMessagesFor('sid'), hasLength(1));
      await ctrl.close();
    });

    test('start() clears the buffer for that sessionId before the new turn', () async {
      final service = ChatStreamService();
      addTearDown(service.dispose);
      final ctrl1 = StreamController<ChatMessage>();
      service.start(sessionId: 'sid', streamFactory: () => ctrl1.stream, onMessage: (_) {});
      ctrl1.add(
        ChatMessage(id: 'old', sessionId: 'sid', role: MessageRole.user, content: 'first', timestamp: DateTime.now()),
      );
      await Future<void>.delayed(Duration.zero);
      await ctrl1.close();
      await Future<void>.delayed(Duration.zero);

      expect(service.liveMessagesFor('sid'), hasLength(1));

      final ctrl2 = StreamController<ChatMessage>();
      service.start(sessionId: 'sid', streamFactory: () => ctrl2.stream, onMessage: (_) {});

      expect(service.liveMessagesFor('sid'), isEmpty);

      ctrl2.add(
        ChatMessage(id: 'new', sessionId: 'sid', role: MessageRole.user, content: 'second', timestamp: DateTime.now()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.liveMessagesFor('sid').map((m) => m.id), ['new']);

      await ctrl2.close();
    });

    test('watchMessages emits subsequent messages to a subscriber attached after start()', () async {
      final service = ChatStreamService();
      addTearDown(service.dispose);
      final ctrl = StreamController<ChatMessage>();
      service.start(sessionId: 'sid', streamFactory: () => ctrl.stream, onMessage: (_) {});

      final received = <String>[];
      final sub = service.watchMessages('sid').listen((m) => received.add(m.id));
      addTearDown(sub.cancel);

      ctrl.add(
        ChatMessage(id: 'x', sessionId: 'sid', role: MessageRole.user, content: 'hi', timestamp: DateTime.now()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(received, ['x']);
      await ctrl.close();
    });

    test('liveMessagesFor and watchMessages are scoped per sessionId', () async {
      final service = ChatStreamService();
      addTearDown(service.dispose);
      final ctrlA = StreamController<ChatMessage>();
      final ctrlB = StreamController<ChatMessage>();
      service.start(sessionId: 'A', streamFactory: () => ctrlA.stream, onMessage: (_) {});
      service.start(sessionId: 'B', streamFactory: () => ctrlB.stream, onMessage: (_) {});

      ctrlA.add(ChatMessage(id: 'aa', sessionId: 'A', role: MessageRole.user, content: '', timestamp: DateTime.now()));
      ctrlB.add(ChatMessage(id: 'bb', sessionId: 'B', role: MessageRole.user, content: '', timestamp: DateTime.now()));
      await Future<void>.delayed(Duration.zero);

      expect(service.liveMessagesFor('A').map((m) => m.id), ['aa']);
      expect(service.liveMessagesFor('B').map((m) => m.id), ['bb']);

      await ctrlA.close();
      await ctrlB.close();
    });
  });

  group('persistence backstop', () {
    test('cancel(sessionId) flushes buffered messages through onPersist', () async {
      final service = ChatStreamService();
      addTearDown(service.dispose);
      final ctrl = StreamController<ChatMessage>();
      final persisted = <ChatMessage>[];

      service.start(
        sessionId: 'sid',
        streamFactory: () => ctrl.stream,
        onMessage: (_) {},
        onPersist: (m) async => persisted.add(m),
      );

      final base = DateTime.now();
      ctrl.add(ChatMessage(id: 'a', sessionId: 'sid', role: MessageRole.user, content: 'hi', timestamp: base));
      ctrl.add(
        ChatMessage(id: 'b', sessionId: 'sid', role: MessageRole.assistant, content: 'streaming', timestamp: base),
      );
      await Future<void>.delayed(Duration.zero);

      await service.cancel('sid');

      expect(persisted.map((m) => m.id), ['a', 'b']);
      await ctrl.close();
    });

    test('stream failure flushes buffered messages through onPersist', () async {
      final service = ChatStreamService();
      addTearDown(service.dispose);
      final ctrl = StreamController<ChatMessage>();
      final persisted = <ChatMessage>[];

      service.start(
        sessionId: 'sid',
        streamFactory: () => ctrl.stream,
        onMessage: (_) {},
        onPersist: (m) async => persisted.add(m),
        backoff: const [],
      );

      final base = DateTime.now();
      ctrl.add(ChatMessage(id: 'a', sessionId: 'sid', role: MessageRole.user, content: 'hi', timestamp: base));
      ctrl.add(
        ChatMessage(id: 'b', sessionId: 'sid', role: MessageRole.assistant, content: 'partial', timestamp: base),
      );
      await Future<void>.delayed(Duration.zero);

      ctrl.addError(StateError('transport blew up'));
      // Drain microtasks so unawaited flush runs.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(persisted.map((m) => m.id), ['a', 'b']);
      await ctrl.close();
    });

    test('cancel without onPersist is a no-op (no callback wired)', () async {
      final service = ChatStreamService();
      addTearDown(service.dispose);
      final ctrl = StreamController<ChatMessage>();

      service.start(sessionId: 'sid', streamFactory: () => ctrl.stream, onMessage: (_) {});

      ctrl.add(
        ChatMessage(id: 'a', sessionId: 'sid', role: MessageRole.user, content: 'hi', timestamp: DateTime.now()),
      );
      await Future<void>.delayed(Duration.zero);

      await expectLater(service.cancel('sid'), completes);
      await ctrl.close();
    });

    test('failed onPersist is logged but does not abort the flush of remaining messages', () async {
      final service = ChatStreamService();
      addTearDown(service.dispose);
      final ctrl = StreamController<ChatMessage>();
      final attempted = <String>[];

      service.start(
        sessionId: 'sid',
        streamFactory: () => ctrl.stream,
        onMessage: (_) {},
        onPersist: (m) async {
          attempted.add(m.id);
          if (m.id == 'fail-me') throw StateError('drift busy');
        },
      );

      final base = DateTime.now();
      ctrl.add(ChatMessage(id: 'a', sessionId: 'sid', role: MessageRole.user, content: '', timestamp: base));
      ctrl.add(ChatMessage(id: 'fail-me', sessionId: 'sid', role: MessageRole.assistant, content: '', timestamp: base));
      ctrl.add(ChatMessage(id: 'c', sessionId: 'sid', role: MessageRole.assistant, content: '', timestamp: base));
      await Future<void>.delayed(Duration.zero);

      await service.cancel('sid');

      expect(attempted, ['a', 'fail-me', 'c']);
      await ctrl.close();
    });

    test('persist callback is scoped per sessionId', () async {
      final service = ChatStreamService();
      addTearDown(service.dispose);
      final ctrlA = StreamController<ChatMessage>();
      final ctrlB = StreamController<ChatMessage>();
      final persistedA = <String>[];
      final persistedB = <String>[];

      service.start(
        sessionId: 'A',
        streamFactory: () => ctrlA.stream,
        onMessage: (_) {},
        onPersist: (m) async => persistedA.add(m.id),
      );
      service.start(
        sessionId: 'B',
        streamFactory: () => ctrlB.stream,
        onMessage: (_) {},
        onPersist: (m) async => persistedB.add(m.id),
      );

      final base = DateTime.now();
      ctrlA.add(ChatMessage(id: 'aa', sessionId: 'A', role: MessageRole.user, content: '', timestamp: base));
      ctrlB.add(ChatMessage(id: 'bb', sessionId: 'B', role: MessageRole.user, content: '', timestamp: base));
      await Future<void>.delayed(Duration.zero);

      await service.cancel('A');

      expect(persistedA, ['aa']);
      expect(persistedB, isEmpty);

      await service.cancel('B');
      expect(persistedB, ['bb']);

      await ctrlA.close();
      await ctrlB.close();
    });
  });
}
