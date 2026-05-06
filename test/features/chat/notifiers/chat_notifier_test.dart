import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/session/models/permission_request.dart';
import 'package:code_bench_app/data/session/models/session_settings.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_notifier.dart';
import 'package:code_bench_app/features/providers/notifiers/providers_notifier.dart';
import 'package:code_bench_app/services/chat/chat_stream_service.dart';
import 'package:code_bench_app/services/chat/chat_stream_state.dart';
import 'package:code_bench_app/services/mcp/mcp_service.dart' show McpRemoveCallback, McpStatusCallback;
import 'package:code_bench_app/services/session/session_service.dart';

class _DisposalTestFakeApiKeysNotifier extends ApiKeysNotifier {
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

bool _neverCancelDisposal() => false;

class _DisposalTestSessionService extends Fake implements SessionService {
  final StreamController<ChatMessage> controller = StreamController<ChatMessage>();

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
    bool Function() cancelFlag = _neverCancelDisposal,
    Future<bool> Function(PermissionRequest req)? requestPermission,
    McpStatusCallback? onMcpStatusChanged,
    McpRemoveCallback? onMcpServerRemoved,
  }) {
    return controller.stream;
  }

  @override
  Future<List<ChatMessage>> loadHistory(String sessionId, {int limit = 50, int offset = 0}) async => [];

  @override
  Future<void> persistMessage(String sessionId, ChatMessage message) async {}
}

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

  test('disposing notifier mid-stream does not crash on next chunk', () async {
    final svc = _DisposalTestSessionService();
    final container = ProviderContainer(
      overrides: [
        sessionServiceProvider.overrideWith((ref) async => svc),
        activeSessionIdProvider.overrideWithValue('s'),
        selectedModelProvider.overrideWithValue(AIModels.claude35Sonnet),
        activeProjectProvider.overrideWithValue(null),
        apiKeysProvider.overrideWith(_DisposalTestFakeApiKeysNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await container.read(chatMessagesProvider('s').future);
    // ignore: unawaited_futures — intentionally not awaited; notifier will be disposed before it resolves
    container.read(chatMessagesProvider('s').notifier).sendMessage('hi');
    await Future<void>.delayed(Duration.zero);

    // Dispose the notifier to simulate the user navigating away.
    container.invalidate(chatMessagesProvider('s'));
    await Future<void>.delayed(Duration.zero);

    // Registry keeps emitting — onMessage and termSub guards must swallow these.
    svc.controller.add(
      ChatMessage(
        id: 'msg-1',
        sessionId: 's',
        role: MessageRole.assistant,
        content: 'chunk',
        timestamp: DateTime(2026),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    // No uncaught error means the fix works.
  });
}
