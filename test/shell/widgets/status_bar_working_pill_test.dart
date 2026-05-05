import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/data/session/models/tool_event.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/layout/widgets/working_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Test harness ─────────────────────────────────────────────────────────────
// WorkingPill is now a standalone widget that receives sessionId/messageId
// directly as constructor params. Mount it directly rather than going through
// StatusBar, which no longer contains the pill.

class _FakeChatMessages extends ChatMessagesNotifier {
  @override
  Future<List<ChatMessage>> build(String sessionId) async => _initialFor(sessionId);
}

Map<String, List<ChatMessage>> _seed = <String, List<ChatMessage>>{};

List<ChatMessage> _initialFor(String sessionId) => List<ChatMessage>.of(_seed[sessionId] ?? const <ChatMessage>[]);

ChatMessage _assistantMessage({required String sessionId, required String id, List<ToolEvent> toolEvents = const []}) =>
    ChatMessage(
      id: id,
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: 'working',
      timestamp: DateTime(2026, 4, 11),
      toolEvents: toolEvents,
    );

ToolEvent _running(String id, {String toolName = 'read_file'}) =>
    ToolEvent(id: id, type: 'tool_use', toolName: toolName);

ToolEvent _done(String id, {String toolName = 'read_file'}) =>
    ToolEvent(id: id, type: 'tool_use', toolName: toolName, status: ToolStatus.success, output: 'ok', durationMs: 12);

Widget _harness(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: ThemeData(extensions: [AppColors.dark]),
    home: const Scaffold(
      body: WorkingPill(sessionId: 's1', messageId: 'm1'),
    ),
  ),
);

ProviderContainer _makeContainer() {
  final container = ProviderContainer(overrides: [chatMessagesProvider('s1').overrideWith(_FakeChatMessages.new)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  tearDown(() => _seed = <String, List<ChatMessage>>{});

  testWidgets('hides pill when there are no tool events', (tester) async {
    _seed = {
      's1': [_assistantMessage(sessionId: 's1', id: 'm1')],
    };
    final container = _makeContainer();
    await tester.pumpWidget(_harness(container));
    await tester.pump();

    expect(find.textContaining('Working for'), findsNothing);
  });

  testWidgets('hides pill when no tool event is running', (tester) async {
    _seed = {
      's1': [
        _assistantMessage(sessionId: 's1', id: 'm1', toolEvents: [_done('e1')]),
      ],
    };
    final container = _makeContainer();
    await tester.pumpWidget(_harness(container));
    await tester.pump();

    expect(find.textContaining('Working for'), findsNothing);
  });

  testWidgets('shows and advances the pill while a tool event is running', (tester) async {
    _seed = {
      's1': [
        _assistantMessage(sessionId: 's1', id: 'm1', toolEvents: [_running('e1')]),
      ],
    };
    final container = _makeContainer();
    await tester.pumpWidget(_harness(container));
    await tester.pump();

    expect(find.textContaining('Working for'), findsOneWidget);
    expect(find.text('Working for 0s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    final pillText = tester.widgetList<Text>(find.textContaining('Working for')).first.data!;
    final seconds = int.parse(RegExp(r'Working for (\d+)s').firstMatch(pillText)!.group(1)!);
    expect(seconds, greaterThanOrEqualTo(2), reason: 'pill counter should tick while a tool is running');
  });

  testWidgets('pill restarts on a new burst after idle — counter is not frozen', (tester) async {
    // Regression guard for the `Timer.periodic` self-cancel bug: once the
    // first tool finished, the old ticker never re-armed, so subsequent
    // tool calls would show "Working for 0s" forever. The fix is the
    // `_syncTicker` method driven from build; this test asserts it.
    _seed = {
      's1': [
        _assistantMessage(sessionId: 's1', id: 'm1', toolEvents: [_running('e1')]),
      ],
    };
    final container = _makeContainer();
    await tester.pumpWidget(_harness(container));
    await tester.pump();

    // Burst 1: running for 2 ticks.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Working for'), findsOneWidget);

    // Idle — no running events, pill should disappear.
    final notifier = container.read(chatMessagesProvider('s1').notifier) as _FakeChatMessages;
    notifier.state = AsyncData([
      _assistantMessage(sessionId: 's1', id: 'm1', toolEvents: [_done('e1')]),
    ]);
    await tester.pump();
    expect(find.textContaining('Working for'), findsNothing);

    // Burst 2: a new tool kicks off → pill re-appears and starts counting
    // from 0 (each burst gets its own timer).
    notifier.state = AsyncData([
      _assistantMessage(sessionId: 's1', id: 'm1', toolEvents: [_done('e1'), _running('e2')]),
    ]);
    await tester.pump();
    expect(find.text('Working for 0s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    final pillText = tester.widgetList<Text>(find.textContaining('Working for')).first.data!;
    final seconds = int.parse(RegExp(r'Working for (\d+)s').firstMatch(pillText)!.group(1)!);
    expect(
      seconds,
      greaterThanOrEqualTo(1),
      reason:
          'pill must resume ticking after idle → running transition; '
          'a frozen 0s means the ticker was never re-armed',
    );
  });
}
