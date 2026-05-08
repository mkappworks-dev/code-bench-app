import 'package:code_bench_app/core/theme/app_theme.dart';
import 'package:code_bench_app/features/chat/widgets/apply_diff_card.dart';
import 'package:code_bench_app/features/chat/widgets/diff_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('ready state shows Apply button and diff body', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ApplyDiffCard(
          filename: 'chat_notifier.dart',
          language: 'dart',
          newCode: 'final x = 1;\n',
          oldPreview: 'final x = 0;\n',
          additions: 1,
          deletions: 1,
          state: ApplyCardState.ready,
        ),
      ),
    );
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('chat_notifier.dart'), findsOneWidget);
    expect(find.byType(DiffBody), findsOneWidget);
  });

  testWidgets('applied state shows applied pill, no Apply button', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ApplyDiffCard(
          filename: 'chat_notifier.dart',
          language: 'dart',
          newCode: 'final x = 1;\n',
          oldPreview: 'final x = 0;\n',
          additions: 1,
          deletions: 1,
          state: ApplyCardState.applied,
        ),
      ),
    );
    expect(find.text('Apply'), findsNothing);
    expect(find.textContaining('applied'), findsOneWidget);
  });

  testWidgets('failed state shows Re-diff button and warning style', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ApplyDiffCard(
          filename: 'chat_notifier.dart',
          language: 'dart',
          newCode: 'final x = 1;\n',
          oldPreview: 'final x = 0;\n',
          additions: 1,
          deletions: 1,
          state: ApplyCardState.failed,
          errorMessage: 'file diverged',
        ),
      ),
    );
    expect(find.text('Re-diff'), findsOneWidget);
    expect(find.textContaining('diverged'), findsOneWidget);
  });
}
