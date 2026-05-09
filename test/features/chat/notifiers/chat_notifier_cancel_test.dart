import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/ai/models/provider_setting_drop.dart';
import 'package:code_bench_app/data/chat/models/transport_readiness.dart';
import 'package:code_bench_app/data/ai/models/provider_runtime_event.dart';
import 'package:code_bench_app/data/session/models/permission_request.dart';
import 'package:code_bench_app/data/shared/session_settings.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_messages_actions.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_messages_failure.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/features/chat/notifiers/transport_readiness_notifier.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_notifier.dart';
import 'package:code_bench_app/features/providers/notifiers/providers_notifier.dart';
import 'package:code_bench_app/services/mcp/mcp_service.dart' show McpRemoveCallback, McpStatusCallback;
import 'package:code_bench_app/services/session/session_service.dart';

class _FakeApiKeysNotifier extends ApiKeysNotifier {
  @override
  Future<ApiKeysNotifierState> build() async => const ApiKeysNotifierState(
    openai: '',
    anthropic: '',
    gemini: '',
    ollamaUrl: '',
    customEndpoint: '',
    customApiKey: '',
    anthropicTransport: 'api-key',
    openaiTransport: 'api-key',
  );
}

bool _neverCancel() => false;

class _FakeSessionService extends Fake implements SessionService {
  final StreamController<ChatMessage> controller = StreamController();
  bool sendCalled = false;
  bool deleteMessagesCalled = false;
  List<String>? deletedMessageIds;
  String? deleteSessionId;
  Object? deleteError;

  @override
  Stream<ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    String? systemPrompt,
    ChatMode mode = ChatMode.chat,
    ChatPermission permission = ChatPermission.fullAccess,
    String? projectPath,
    String? providerId,
    bool Function() cancelFlag = _neverCancel,
    Future<bool> Function(PermissionRequest req)? requestPermission,
    Future<void> Function(ProviderUserInputRequest req)? requestUserInput,
    McpStatusCallback? onMcpStatusChanged,
    McpRemoveCallback? onMcpServerRemoved,
    ProviderSettingDropSink? onSettingDropped,
  }) {
    sendCalled = true;
    return controller.stream;
  }

  @override
  Future<void> deleteMessages(String sessionId, List<String> messageIds) async {
    deleteMessagesCalled = true;
    deleteSessionId = sessionId;
    deletedMessageIds = messageIds;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<void> persistMessage(String sessionId, ChatMessage message) async {}

  @override
  Future<List<ChatMessage>> loadHistory(String sessionId, {int limit = 50, int offset = 0}) async => [];
}

ProviderContainer _makeContainer(_FakeSessionService svc) {
  return ProviderContainer(
    overrides: [
      sessionServiceProvider.overrideWith((ref) async => svc),
      activeSessionIdProvider.overrideWithValue('session-1'),
      selectedModelProvider.overrideWithValue(AIModels.sonnet46),
      activeProjectProvider.overrideWithValue(null),
      apiKeysProvider.overrideWith(_FakeApiKeysNotifier.new),
      transportReadinessProvider.overrideWithValue(const TransportReadiness.ready()),
    ],
  );
}

void main() {
  group('ChatMessagesNotifier.cancelSend', () {
    test('appends an interrupted marker and unblocks the send future', () async {
      final svc = _FakeSessionService();
      final container = _makeContainer(svc);
      addTearDown(container.dispose);

      // Prime the notifier with an initial empty state.
      await container.read(chatMessagesProvider('session-1').future);

      // Start a send — stream never emits.
      final sendFuture = container.read(chatMessagesProvider('session-1').notifier).sendMessage('hello');
      await Future.microtask(() {}); // let sendMessage subscribe

      // Cancel.
      container.read(chatMessagesProvider('session-1').notifier).cancelSend();
      final result = await sendFuture;
      expect(result, isNull, reason: 'cancelled send must complete with null');

      final state = container.read(chatMessagesProvider('session-1'));
      expect(state, isA<AsyncData<List<ChatMessage>>>());
      expect(state.value?.length, 1);
      expect(state.value?.first.role, MessageRole.interrupted);
    });

    test('does nothing when called with no in-flight send', () async {
      final svc = _FakeSessionService();
      final container = _makeContainer(svc);
      addTearDown(container.dispose);

      await container.read(chatMessagesProvider('session-1').future);
      // No send started — cancel must be a no-op (no marker appended).
      container.read(chatMessagesProvider('session-1').notifier).cancelSend();
      final state = container.read(chatMessagesProvider('session-1'));
      expect(state.value, isEmpty);
    });

    test('late onDone after cancel does not throw a swallowed StateError', () async {
      final svc = _FakeSessionService();
      final container = _makeContainer(svc);
      addTearDown(container.dispose);

      await container.read(chatMessagesProvider('session-1').future);
      final sendFuture = container.read(chatMessagesProvider('session-1').notifier).sendMessage('hello');
      await Future.microtask(() {});

      container.read(chatMessagesProvider('session-1').notifier).cancelSend();
      // Simulate the underlying stream firing onDone *after* cancel — the
      // completer was nulled before completion so this must not throw.
      await svc.controller.close();
      expect(await sendFuture, isNull);
    });
  });

  group('ChatMessagesActions.deleteMessage', () {
    test('removes message + trailing interrupted markers via service', () async {
      final svc = _FakeSessionService();
      final container = _makeContainer(svc);
      addTearDown(container.dispose);

      final user = ChatMessage(
        id: 'msg-1',
        sessionId: 'session-1',
        role: MessageRole.user,
        content: 'hello',
        timestamp: DateTime(2026),
      );
      final marker = ChatMessage(
        id: 'marker-1',
        sessionId: 'session-1',
        role: MessageRole.interrupted,
        content: '',
        timestamp: DateTime(2026),
      );
      // Prime state so removeFromState has something to filter.
      await container.read(chatMessagesProvider('session-1').future);
      container.read(chatMessagesProvider('session-1').notifier).state = AsyncData([user, marker]);

      await container.read(chatMessagesActionsProvider.notifier).deleteMessage('session-1', 'msg-1');

      expect(container.read(chatMessagesProvider('session-1')).value, isEmpty);
      expect(svc.deleteMessagesCalled, isTrue);
      expect(svc.deleteSessionId, 'session-1');
      expect(svc.deletedMessageIds, ['msg-1', 'marker-1']);
      expect(container.read(chatMessagesActionsProvider).hasError, isFalse);
    });

    test('emits typed ChatMessagesFailure on service error', () async {
      final svc = _FakeSessionService()..deleteError = Exception('db locked');
      final container = _makeContainer(svc);
      addTearDown(container.dispose);

      await container.read(chatMessagesProvider('session-1').future);
      await container.read(chatMessagesActionsProvider.notifier).deleteMessage('session-1', 'msg-1');

      final actionState = container.read(chatMessagesActionsProvider);
      expect(actionState.hasError, isTrue);
      expect(actionState.error, isA<ChatMessagesFailure>());
      expect(actionState.error, isA<ChatMessagesDeleteFailed>());
    });
  });
}
