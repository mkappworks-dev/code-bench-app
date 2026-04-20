import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/session/models/tool_event.dart';
import 'package:code_bench_app/features/chat/widgets/tool_call_row.dart';

Widget _host(ToolEvent event) => MaterialApp(
  theme: ThemeData(extensions: [AppColors.dark]),
  home: Scaffold(body: ToolCallRow(event: event)),
);

void main() {
  testWidgets('running status renders a spinner', (tester) async {
    await tester.pumpWidget(_host(const ToolEvent(id: 't1', type: 'tool_use', toolName: 'read_file')));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('success status renders a green check', (tester) async {
    await tester.pumpWidget(
      _host(
        const ToolEvent(id: 't2', type: 'tool_use', toolName: 'read_file', status: ToolStatus.success, output: 'ok'),
      ),
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('error status renders a red error icon with tooltip', (tester) async {
    await tester.pumpWidget(
      _host(
        const ToolEvent(id: 't3', type: 'tool_use', toolName: 'run_command', status: ToolStatus.error, error: 'exit 1'),
      ),
    );
    expect(find.byIcon(Icons.error), findsOneWidget);
    // Tooltip is the parent — look up by message.
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'exit 1');
  });

  testWidgets('cancelled status renders a grey cancel icon', (tester) async {
    await tester.pumpWidget(
      _host(const ToolEvent(id: 't4', type: 'tool_use', toolName: 'search', status: ToolStatus.cancelled)),
    );
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
  });

  testWidgets('expanded error section shows the error text', (tester) async {
    await tester.pumpWidget(
      _host(
        const ToolEvent(
          id: 't5',
          type: 'tool_use',
          toolName: 'run_command',
          status: ToolStatus.error,
          error: 'Permission denied',
        ),
      ),
    );
    // Tap to expand.
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();
    expect(find.text('Permission denied'), findsOneWidget);
    expect(find.text('ERROR'), findsOneWidget);
  });

  testWidgets('cancelled row renders the arg text with strikethrough decoration', (tester) async {
    const event = ToolEvent(
      id: 'e1',
      type: 'tool_use',
      toolName: 'read_file',
      status: ToolStatus.cancelled,
      input: {'path': 'lib/main.dart'},
    );
    await tester.pumpWidget(_host(event));
    await tester.pumpAndSettle();

    final argFinder = find.text('lib/main.dart');
    expect(argFinder, findsOneWidget);
    final argText = tester.widget<Text>(argFinder);
    expect(argText.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('success row does NOT apply strikethrough to the arg text', (tester) async {
    const event = ToolEvent(
      id: 'e2',
      type: 'tool_use',
      toolName: 'read_file',
      status: ToolStatus.success,
      input: {'path': 'lib/main.dart'},
      output: 'hello',
    );
    await tester.pumpWidget(_host(event));
    await tester.pumpAndSettle();

    final argText = tester.widget<Text>(find.text('lib/main.dart'));
    expect(argText.style?.decoration, anyOf(isNull, isNot(TextDecoration.lineThrough)));
  });
}
