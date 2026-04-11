import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/features/onboarding/widgets/add_project_step.dart';

void main() {
  testWidgets('shows drop zone with "Drop a folder here" text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AddProjectStep(onComplete: () {}, onSkip: () {})),
        ),
      ),
    );
    expect(find.text('Drop a folder here'), findsOneWidget);
  });

  testWidgets('"Add Project" button is disabled by default', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AddProjectStep(onComplete: () {}, onSkip: () {})),
        ),
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
