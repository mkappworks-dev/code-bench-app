import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/features/chat/widgets/iteration_cap_banner.dart';

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: ThemeData.dark().copyWith(extensions: [AppColors.dark]),
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('active state shows an enabled Continue button', (tester) async {
    await tester.pumpWidget(_wrap(const IterationCapBanner(messageId: 'cap', sessionId: 's', isActive: true)));
    await tester.pumpAndSettle();

    final btn = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Continue'));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('dismissed state shows a disabled Continue button', (tester) async {
    await tester.pumpWidget(_wrap(const IterationCapBanner(messageId: 'cap', sessionId: 's', isActive: false)));
    await tester.pumpAndSettle();

    final btn = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Continue'));
    expect(btn.onPressed, isNull);
    expect(find.text('Continued via new message.'), findsOneWidget);
  });
}
