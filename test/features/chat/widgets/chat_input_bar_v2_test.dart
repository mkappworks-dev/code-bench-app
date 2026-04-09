import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/features/chat/widgets/chat_input_bar_v2.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('effort chip shows current selection', (tester) async {
    await tester.pumpWidget(_wrap(const ChatInputBarV2(sessionId: 'sid')));
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('tapping effort chip opens dropdown with all options',
      (tester) async {
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
