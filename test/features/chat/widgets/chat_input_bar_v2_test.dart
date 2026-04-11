import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/models/project.dart';
import 'package:code_bench_app/features/chat/widgets/chat_input_bar_v2.dart';
import 'package:code_bench_app/features/project_sidebar/project_sidebar_notifier.dart';

Widget _wrap(Widget child) => ProviderScope(
  // ChatInputBarV2 watches projectsProvider for the missing-folder guard.
  // Override it with an empty stub stream so the widget tree can build
  // without pulling in the real on-disk Drift database (which leaves
  // pending timers that fail the test binding's invariant checks).
  overrides: [projectsProvider.overrideWith((ref) => Stream<List<Project>>.value(const <Project>[]))],
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('effort chip shows current selection', (tester) async {
    await tester.pumpWidget(_wrap(const ChatInputBarV2(sessionId: 'sid')));
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('tapping effort chip opens dropdown with all options', (tester) async {
    await tester.pumpWidget(_wrap(const ChatInputBarV2(sessionId: 'sid')));
    await tester.tap(find.text('High'));
    await tester.pumpAndSettle();
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
  });

  testWidgets('selecting effort option updates the chip label', (tester) async {
    await tester.pumpWidget(_wrap(const ChatInputBarV2(sessionId: 'sid')));
    await tester.tap(find.text('High'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Low'));
    await tester.pumpAndSettle();
    expect(find.text('Low'), findsOneWidget);
  });
}
