import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/data/session/models/tool_event.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/features/chat/widgets/work_log_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Test harness ─────────────────────────────────────────────────────────────
// A subclass of ChatMessages that skips the real SessionService fetch and
// lets the test drive state transitions directly via `emit`. We override
// `chatMessagesProvider` with this fake so widgets that `ref.watch` it see
// the sequence of tool-event snapshots the test wants to assert on.

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
      body: WorkLogSection(sessionId: 's1', messageId: 'm1'),
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

  testWidgets('renders nothing when the message has no tool events', (tester) async {
    _seed = {
      's1': [_assistantMessage(sessionId: 's1', id: 'm1')],
    };
    final container = _makeContainer();
    await tester.pumpWidget(_harness(container));
    await tester.pump();

    expect(find.text('WORK LOG'), findsNothing);
    expect(find.byType(SizedBox), findsWidgets); // SizedBox.shrink path
  });

  testWidgets('renders nothing when the messageId does not match', (tester) async {
    _seed = {
      's1': [
        _assistantMessage(sessionId: 's1', id: 'other', toolEvents: [_running('e1')]),
      ],
    };
    final container = _makeContainer();
    await tester.pumpWidget(_harness(container));
    await tester.pump();

    // firstWhereOrNull returns null → empty toolEvents → shrink
    expect(find.text('WORK LOG'), findsNothing);
  });

  testWidgets('shows spinner and advances elapsed counter while running', (tester) async {
    _seed = {
      's1': [
        _assistantMessage(sessionId: 's1', id: 'm1', toolEvents: [_running('e1')]),
      ],
    };
    final container = _makeContainer();
    await tester.pumpWidget(_harness(container));
    await tester.pump();

    expect(find.text('WORK LOG'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('⏱ 0s'), findsOneWidget);

    // Advance fake clock by 3 periodic ticks.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Counter is wall-clock based; after ~3 seconds of fake time it should
    // be at least 2 (tolerance for timer drift on the first tick).
    final elapsedText = tester.widgetList<Text>(find.textContaining('⏱ ')).first.data!;
    final seconds = int.parse(RegExp(r'⏱ (\d+)s').firstMatch(elapsedText)!.group(1)!);
    expect(seconds, greaterThanOrEqualTo(2), reason: 'counter should tick while running');
  });

  testWidgets('counter keeps ticking across running → done → running transitions', (tester) async {
    // Regression guard for the silent-failure bug where `Timer.periodic`
    // self-cancelled on first `!anyRunning` observation and never
    // restarted, leaving "⏱ Xs" frozen for any subsequent tool call.
    _seed = {
      's1': [
        _assistantMessage(sessionId: 's1', id: 'm1', toolEvents: [_running('e1')]),
      ],
    };
    final container = _makeContainer();
    await tester.pumpWidget(_harness(container));
    await tester.pump();
    final notifier = container.read(chatMessagesProvider('s1').notifier) as _FakeChatMessages;

    // Burst 1: one running event, advance 2 ticks.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Tool completes → no running events, check icon visible.
    notifier.state = AsyncData([
      _assistantMessage(sessionId: 's1', id: 'm1', toolEvents: [_done('e1')]),
    ]);
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    // Burst 2: new tool starts streaming.
    notifier.state = AsyncData([
      _assistantMessage(sessionId: 's1', id: 'm1', toolEvents: [_done('e1'), _running('e2')]),
    ]);
    await tester.pump();

    // Spinner is back.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Advance time again — the critical assertion: counter continues from
    // where it was (sticky `_runStart`), NOT frozen at the old value.
    await tester.pump(const Duration(seconds: 2));

    final elapsedText = tester.widgetList<Text>(find.textContaining('⏱ ')).first.data!;
    final seconds = int.parse(RegExp(r'⏱ (\d+)s').firstMatch(elapsedText)!.group(1)!);
    expect(seconds, greaterThanOrEqualTo(3), reason: 'counter must not freeze after running → done → running cycle');
  });

  testWidgets('expanded view renders one row per tool event with a stable key', (tester) async {
    _seed = {
      's1': [
        _assistantMessage(
          sessionId: 's1',
          id: 'm1',
          toolEvents: [
            _done('e1', toolName: 'read_file'),
            _running('e2', toolName: 'run_command'),
          ],
        ),
      ],
    };
    final container = _makeContainer();
    await tester.pumpWidget(_harness(container));
    await tester.pump();

    // Toggle the section open. Tap the header label rather than the
    // GestureDetector itself — the detector uses `deferToChild`, so
    // taps in gaps between Row children don't fire; only the visible
    // children (text, spinner) are reliably hit-testable.
    await tester.tap(find.text('WORK LOG'));
    await tester.pump();

    expect(find.text('read_file'), findsOneWidget);
    expect(find.text('run_command'), findsOneWidget);
    // ValueKey on each row makes expansion state stable across rebuilds.
    expect(find.byKey(const ValueKey('work-log-e1')), findsOneWidget);
    expect(find.byKey(const ValueKey('work-log-e2')), findsOneWidget);
  });
}
