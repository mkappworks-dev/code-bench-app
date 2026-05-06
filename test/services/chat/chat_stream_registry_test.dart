import 'dart:async';

import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/services/chat/chat_stream_registry.dart';
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
    final registry = container.read(chatStreamRegistryProvider);
    expect(registry.latestState('unknown'), isA<ChatStreamIdle>());
  });

  test('watchState emits the current state immediately', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final registry = container.read(chatStreamRegistryProvider);
    final first = await registry.watchState('s').first;
    expect(first, isA<ChatStreamIdle>());
  });

  group('start', () {
    test('start emits connecting → streaming → done as chunks arrive', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(chatStreamRegistryProvider);

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
      final registry = container.read(chatStreamRegistryProvider);
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
      final registry = container.read(chatStreamRegistryProvider);
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
      final registry = container.read(chatStreamRegistryProvider);
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
}
