import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/services/session/session_service.dart';

// ── Fake SessionService ───────────────────────────────────────────────────────

class _FakeSessionService extends Fake implements SessionService {
  final StreamController<ChatMessage> controller = StreamController();
  bool sendCalled = false;
  bool deleteMessageCalled = false;
  String? deletedMessageId;

  @override
  Stream<ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    String? systemPrompt,
  }) {
    sendCalled = true;
    return controller.stream;
  }

  @override
  Future<void> deleteMessage(String sessionId, String messageId) async {
    deleteMessageCalled = true;
    deletedMessageId = messageId;
  }

  @override
  Future<List<ChatMessage>> loadHistory(String sessionId, {int limit = 50, int offset = 0}) async => [];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer(_FakeSessionService svc) {
  return ProviderContainer(
    overrides: [
      sessionServiceProvider.overrideWith((ref) async => svc),
      activeSessionIdProvider.overrideWithValue('session-1'),
      selectedModelProvider.overrideWithValue(AIModels.claude35Sonnet),
    ],
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ChatMessagesNotifier.cancelSend', () {
    test('restores state to pre-send messages when cancelled', () async {
      final svc = _FakeSessionService();
      final container = _makeContainer(svc);
      addTearDown(container.dispose);

      // Prime the notifier with an initial empty state.
      await container.read(chatMessagesProvider('session-1').future);

      // Start a send — stream never emits.
      unawaited(container.read(chatMessagesProvider('session-1').notifier).sendMessage('hello'));
      await Future.microtask(() {}); // let sendMessage start

      // Cancel.
      container.read(chatMessagesProvider('session-1').notifier).cancelSend();
      await Future.microtask(() {});

      // State is AsyncData with a single interrupted marker.
      final state = container.read(chatMessagesProvider('session-1'));
      expect(state, isA<AsyncData<List<ChatMessage>>>());
      expect(state.value?.length, 1);
      expect(state.value?.first.role, MessageRole.interrupted);
    });
  });

  group('ChatMessagesNotifier.deleteMessage', () {
    test('removes message from in-memory state and calls service', () async {
      final svc = _FakeSessionService();
      final container = _makeContainer(svc);
      addTearDown(container.dispose);

      // Seed with a known message.
      final msg = ChatMessage(
        id: 'msg-1',
        sessionId: 'session-1',
        role: MessageRole.user,
        content: 'hello',
        timestamp: DateTime(2026),
      );
      // Set state directly.
      container.read(chatMessagesProvider('session-1').notifier).state = AsyncData([msg]);

      await container.read(chatMessagesProvider('session-1').notifier).deleteMessage('msg-1');

      expect(container.read(chatMessagesProvider('session-1')).value, isEmpty);
      expect(svc.deleteMessageCalled, isTrue);
      expect(svc.deletedMessageId, 'msg-1');
    });
  });
}
