import 'package:code_bench_app/core/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showErrorSnackBar shows error text with error background', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showErrorSnackBar(context, 'Test error'),
              child: const Text('tap'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('tap'));
    await tester.pump();

    expect(find.text('Test error'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, const Color(0xFFF44747)); // ThemeConstants.error
  });

  testWidgets('showSuccessSnackBar shows message text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSuccessSnackBar(context, 'Saved'),
              child: const Text('tap'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('tap'));
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
  });
}
