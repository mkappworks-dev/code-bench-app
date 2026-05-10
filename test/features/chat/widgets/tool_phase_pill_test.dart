import 'package:code_bench_app/core/theme/app_theme.dart';
import 'package:code_bench_app/features/chat/utils/tool_phase_classifier.dart';
import 'package:code_bench_app/features/chat/widgets/tool_phase_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );

  testWidgets('renders label with phase color · think', (tester) async {
    await tester.pumpWidget(wrap(const ToolPhasePill(phase: PhaseClass.think, label: 'thinking')));
    expect(find.text('thinking'), findsOneWidget);
  });

  testWidgets('renders label with phase color · tool', (tester) async {
    await tester.pumpWidget(wrap(const ToolPhasePill(phase: PhaseClass.tool, label: 'running git status')));
    expect(find.text('running git status'), findsOneWidget);
  });

  testWidgets('renders label with phase color · io', (tester) async {
    await tester.pumpWidget(wrap(const ToolPhasePill(phase: PhaseClass.io, label: 'reading 3 files')));
    expect(find.text('reading 3 files'), findsOneWidget);
  });
}
