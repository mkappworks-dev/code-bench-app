import 'package:code_bench_app/data/models/chat_message.dart';
import 'package:code_bench_app/data/models/project.dart';
import 'package:code_bench_app/data/models/tool_event.dart';
import 'package:code_bench_app/features/chat/chat_notifier.dart';
import 'package:code_bench_app/features/project_sidebar/project_sidebar_notifier.dart';
import 'package:code_bench_app/shell/widgets/status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Test harness ─────────────────────────────────────────────────────────────
// The "Working for Xs" pill is a private widget inside StatusBar. To exercise
// it we mount the full StatusBar and override every provider it touches so
// the real services (SessionService, ProjectService, …) stay out of the test.

class _FakeChatMessages extends ChatMessages {
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
  child: const MaterialApp(home: Scaffold(body: StatusBar())),
);

ProviderContainer _makeContainer({String? sessionId = 's1', String? messageId = 'm1'}) {
  final container = ProviderContainer(
    overrides: [
      // Stub the projects stream so the status bar's unconditional
      // ref.watch(projectsProvider) doesn't try to reach the real DB.
      projectsProvider.overrideWith((ref) => Stream<List<Project>>.value(const <Project>[])),
      chatMessagesProvider('s1').overrideWith(_FakeChatMessages.new),
    ],
  );
  if (sessionId != null) container.read(activeSessionIdProvider.notifier).set(sessionId);
  if (messageId != null) container.read(activeMessageIdProvider.notifier).set(messageId);
  addTearDown(container.dispose);
  return container;
}

void main() {
  tearDown(() => _seed = <String, List<ChatMessage>>{});

  testWidgets('hides pill when there is no active session', (tester) async {
    _seed = {
      's1': [
        _assistantMessage(sessionId: 's1', id: 'm1', toolEvents: [_running('e1')]),
      ],
    };
    final container = _makeContainer(sessionId: null, messageId: null);
    await tester.pumpWidget(_harness(container));
    await tester.pump();

    expect(find.textContaining('Working for'), findsNothing);
  });

  testWidgets('hides pill when there is no active message id', (tester) async {
    _seed = {
      's1': [
        _assistantMessage(sessionId: 's1', id: 'm1', toolEvents: [_running('e1')]),
      ],
    };
    final container = _makeContainer(sessionId: 's1', messageId: null);
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
    // from 0 (_WorkingPill clears _runStart on idle — this is intentional,
    // each burst gets its own timer, unlike WorkLogSection which is sticky).
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
          'pill must resume ticking after idle → running transition; a frozen 0s means the ticker was never re-armed',
    );
  });
}
