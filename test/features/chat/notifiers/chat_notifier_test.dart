import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/services/chat/chat_stream_service.dart';
import 'package:code_bench_app/services/chat/chat_stream_state.dart';
import 'package:code_bench_app/services/session/session_service.dart';

void main() {
  test('setIterationCapReached flips the flag on the matching message', () {
    final container = ProviderContainer(
      overrides: [sessionServiceProvider.overrideWith((ref) async => throw UnimplementedError())],
    );
    addTearDown(container.dispose);

    final capped = ChatMessage(
      id: 'cap',
      sessionId: 's',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime(2026, 4, 20),
      iterationCapReached: true,
    );

    final notifier = container.read(chatMessagesProvider('s').notifier);
    notifier.state = AsyncData([capped]);

    notifier.setIterationCapReached('cap', false);
    expect(container.read(chatMessagesProvider('s')).value!.first.iterationCapReached, isFalse);

    notifier.setIterationCapReached('cap', true);
    expect(container.read(chatMessagesProvider('s')).value!.first.iterationCapReached, isTrue);
  });

  test('two sessions can stream concurrently', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final registry = container.read(chatStreamServiceProvider);

    final aSrc = StreamController<ChatMessage>();
    final bSrc = StreamController<ChatMessage>();
    registry.start(sessionId: 'a', streamFactory: () => aSrc.stream, onMessage: (_) {});
    registry.start(sessionId: 'b', streamFactory: () => bSrc.stream, onMessage: (_) {});
    await Future<void>.delayed(Duration.zero);

    expect(registry.latestState('a'), isA<ChatStreamConnecting>());
    expect(registry.latestState('b'), isA<ChatStreamConnecting>());

    aSrc.add(
      ChatMessage(id: 'a1', sessionId: 'a', role: MessageRole.assistant, content: '', timestamp: DateTime(2026)),
    );
    await Future<void>.delayed(Duration.zero);
    expect(registry.latestState('a'), isA<ChatStreamStreaming>());
    expect(registry.latestState('b'), isA<ChatStreamConnecting>());
  });
}
