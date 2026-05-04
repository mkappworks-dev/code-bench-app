import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/features/onboarding/widgets/add_project_step.dart';

void main() {
  testWidgets('shows drop zone with "Drop a folder here" text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(extensions: [AppColors.dark]),
          home: Scaffold(
            body: AddProjectStep(onComplete: () {}, onSkip: () {}),
          ),
        ),
      ),
    );
    expect(find.text('Drop a folder here'), findsOneWidget);
  });

  testWidgets('"Add Project" button is disabled by default', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(extensions: [AppColors.dark]),
          home: Scaffold(
            body: AddProjectStep(onComplete: () {}, onSkip: () {}),
          ),
        ),
      ),
    );
    final gesture = tester.widget<GestureDetector>(
      find
          .ancestor(of: find.text('Add Project'), matching: find.byType(GestureDetector))
          .first,
    );
    expect(gesture.onTap, isNull);
  });
}
