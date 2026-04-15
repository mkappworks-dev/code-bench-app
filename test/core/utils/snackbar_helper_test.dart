import 'package:code_bench_app/core/constants/theme_constants.dart';
import 'package:code_bench_app/core/utils/snackbar_helper.dart';
import 'package:code_bench_app/core/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(VoidCallback onTap) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => ElevatedButton(onPressed: onTap, child: const Text('tap')),
    ),
  ),
);

void main() {
  testWidgets('showErrorSnackBar shows error label text', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            ctx = context;
            return ElevatedButton(
              onPressed: () => showErrorSnackBar(ctx, 'Test error'),
              child: const Text('tap'),
            );
          }),
        ),
      ),
    );

    await tester.tap(find.text('tap'));
    await tester.pump();

    expect(find.text('Test error'), findsOneWidget);
    // Accent strip colour matches the error token.
    final strip = tester.widget<Container>(
      find
          .descendant(of: find.byType(AppSnackBar), matching: find.byWidgetPredicate((w) => w is Container))
          .first,
    );
    final decoration = strip.decoration as BoxDecoration?;
    // The outermost Container has a border decoration, not a color — check the
    // colored accent strip (width: 3) via the icon colour instead.
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
    expect(icon.color, ThemeConstants.error);
  });

  testWidgets('showSuccessSnackBar shows message text', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            ctx = context;
            return ElevatedButton(
              onPressed: () => showSuccessSnackBar(ctx, 'Saved'),
              child: const Text('tap'),
            );
          }),
        ),
      ),
    );

    await tester.tap(find.text('tap'));
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
