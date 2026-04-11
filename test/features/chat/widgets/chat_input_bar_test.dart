import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/models/project.dart';
import 'package:code_bench_app/features/chat/widgets/chat_input_bar.dart';
import 'package:code_bench_app/features/project_sidebar/project_sidebar_notifier.dart';

Widget _wrap(Widget child) => ProviderScope(
  // ChatInputBar watches projectsProvider for the missing-folder guard.
  // Override it with an empty stub stream so the widget tree can build
  // without pulling in the real on-disk Drift database (which leaves
  // pending timers that fail the test binding's invariant checks).
  overrides: [projectsProvider.overrideWith((ref) => Stream<List<Project>>.value(const <Project>[]))],
  child: MaterialApp(home: Scaffold(body: child)),
);

/// Test harness that keeps a single ProviderScope alive while the caller
/// swaps the active sessionId via a GlobalKey. Needed because per-session
/// drafts live in a Riverpod provider that resets if the ProviderScope
/// itself is rebuilt between tester.pumpWidget calls.
class _SessionSwitcher extends StatefulWidget {
  const _SessionSwitcher({super.key, required this.initial});
  final String initial;
  @override
  State<_SessionSwitcher> createState() => _SessionSwitcherState();
}

class _SessionSwitcherState extends State<_SessionSwitcher> {
  late String sessionId = widget.initial;
  void switchTo(String id) => setState(() => sessionId = id);
  @override
  Widget build(BuildContext context) => ChatInputBar(sessionId: sessionId);
}

void main() {
  testWidgets('effort chip shows current selection', (tester) async {
    await tester.pumpWidget(_wrap(const ChatInputBar(sessionId: 'sid')));
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('tapping effort chip opens dropdown with all options', (tester) async {
    await tester.pumpWidget(_wrap(const ChatInputBar(sessionId: 'sid')));
    await tester.tap(find.text('High'));
    await tester.pumpAndSettle();
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
  });

  testWidgets('selecting effort option updates the chip label', (tester) async {
    await tester.pumpWidget(_wrap(const ChatInputBar(sessionId: 'sid')));
    await tester.tap(find.text('High'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Low'));
    await tester.pumpAndSettle();
    expect(find.text('Low'), findsOneWidget);
  });

  testWidgets('switching to a never-typed-in session shows an empty draft', (tester) async {
    final key = GlobalKey<_SessionSwitcherState>();
    await tester.pumpWidget(_wrap(_SessionSwitcher(key: key, initial: 's1')));
    await tester.enterText(find.byType(TextField), 'half-written question');
    expect(find.text('half-written question'), findsOneWidget);

    // Switch to s2 which has never had anything typed — should be empty,
    // not inherit s1's draft.
    key.currentState!.switchTo('s2');
    await tester.pump();

    expect(find.text('half-written question'), findsNothing);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, isEmpty);
  });

  testWidgets('draft persists per-session when switching back and forth', (tester) async {
    final key = GlobalKey<_SessionSwitcherState>();
    await tester.pumpWidget(_wrap(_SessionSwitcher(key: key, initial: 's1')));

    // Type a draft in s1.
    await tester.enterText(find.byType(TextField), 's1 draft');

    // Switch to s2, type a different draft there.
    key.currentState!.switchTo('s2');
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);
    await tester.enterText(find.byType(TextField), 's2 draft');

    // Switch back to s1 — original draft should reappear.
    key.currentState!.switchTo('s1');
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 's1 draft');

    // And switching forward to s2 again — that draft should also be there.
    key.currentState!.switchTo('s2');
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 's2 draft');
  });
}
