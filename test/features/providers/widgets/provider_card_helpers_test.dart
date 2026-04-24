import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/features/providers/widgets/api_key_card.dart';
import 'package:code_bench_app/features/providers/widgets/provider_card_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _withTheme(Widget child) => MaterialApp(
  theme: ThemeData(extensions: [AppColors.dark]),
  home: Scaffold(body: child),
);

void main() {
  group('ActivePill', () {
    testWidgets('renders "Active" text', (tester) async {
      await tester.pumpWidget(_withTheme(const ActivePill()));
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('uses accent color for text', (tester) async {
      await tester.pumpWidget(_withTheme(const ActivePill()));
      final text = tester.widget<Text>(find.text('Active'));
      expect(text.style?.color, AppColors.dark.accent);
    });
  });

  group('TransportRadio', () {
    testWidgets('renders both labels', (tester) async {
      await tester.pumpWidget(
        _withTheme(
          TransportRadio(leftLabel: 'API Key', rightLabel: 'Claude Code CLI', selectedIndex: 0, onChanged: (_) {}),
        ),
      );
      expect(find.text('API Key'), findsOneWidget);
      expect(find.text('Claude Code CLI'), findsOneWidget);
    });

    testWidgets('calls onChanged with correct index when right label tapped', (tester) async {
      int? received;
      await tester.pumpWidget(
        _withTheme(
          TransportRadio(
            leftLabel: 'API Key',
            rightLabel: 'Claude Code CLI',
            selectedIndex: 0,
            onChanged: (i) => received = i,
          ),
        ),
      );
      await tester.tap(find.text('Claude Code CLI'));
      await tester.pump();
      expect(received, 1);
    });

    testWidgets('does not fire onChanged when rightDisabled is true', (tester) async {
      int? received;
      await tester.pumpWidget(
        _withTheme(
          TransportRadio(
            leftLabel: 'API Key',
            rightLabel: 'Claude Code CLI',
            selectedIndex: 0,
            onChanged: (i) => received = i,
            rightDisabled: true,
          ),
        ),
      );
      await tester.tap(find.text('Claude Code CLI'));
      await tester.pump();
      expect(received, isNull);
    });

    testWidgets('does not fire onChanged when onChanged is null (both disabled)', (tester) async {
      await tester.pumpWidget(
        _withTheme(const TransportRadio(leftLabel: 'API Key', rightLabel: 'Claude Code CLI', selectedIndex: 0)),
      );
      // Should not throw or crash; just verify it renders
      expect(find.text('API Key'), findsOneWidget);
    });
  });

  group('ApiKeyCard showActivePill', () {
    Widget card({required bool showActivePill}) {
      final ctrl = TextEditingController();
      return ProviderScope(
        child: _withTheme(
          ApiKeyCard(
            provider: AIProvider.anthropic,
            controller: ctrl,
            initialValue: '',
            showActivePill: showActivePill,
          ),
        ),
      );
    }

    testWidgets('shows Active pill when showActivePill is true', (tester) async {
      await tester.pumpWidget(card(showActivePill: true));
      await tester.pump(); // let providers settle
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('hides Active pill when showActivePill is false', (tester) async {
      await tester.pumpWidget(card(showActivePill: false));
      await tester.pump();
      expect(find.text('Active'), findsNothing);
    });
  });
}
