import 'package:code_bench_app/core/theme/app_theme.dart';
import 'package:code_bench_app/features/chat/widgets/diff_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );

  testWidgets('renders addition lines with + marker', (tester) async {
    await tester.pumpWidget(wrap(const DiffBody(diffText: '+final x = 1;\n-final x = 0;\n')));
    expect(find.text('+'), findsOneWidget);
    expect(find.text('−'), findsOneWidget);
  });

  testWidgets('renders hunk header lines', (tester) async {
    await tester.pumpWidget(wrap(const DiffBody(diffText: '@@ -1,3 +1,4 @@ void main() {')));
    expect(find.textContaining('@@ -1,3'), findsOneWidget);
  });

  testWidgets('renders context lines with space marker', (tester) async {
    await tester.pumpWidget(wrap(const DiffBody(diffText: ' context line')));
    expect(find.text('context line'), findsOneWidget);
  });
}
