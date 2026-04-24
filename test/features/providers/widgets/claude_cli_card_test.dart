import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/ai/models/cli_detection.dart';
import 'package:code_bench_app/features/providers/notifiers/claude_cli_detection_notifier.dart';
import 'package:code_bench_app/features/providers/widgets/claude_cli_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(CliDetection detection) {
  return ProviderScope(
    overrides: [claudeCliDetectionProvider.overrideWith(() => _FakeDetectionNotifier(detection))],
    child: MaterialApp(
      theme: ThemeData(extensions: [AppColors.dark]),
      home: const Scaffold(body: ClaudeCliCard()),
    ),
  );
}

class _FakeDetectionNotifier extends ClaudeCliDetectionNotifier {
  _FakeDetectionNotifier(this._value);
  final CliDetection _value;

  @override
  Future<CliDetection> build() async => _value;

  @override
  Future<void> recheck() async {}
}

void main() {
  group('ClaudeCliCard', () {
    testWidgets('shows "Not installed" when CliNotInstalled', (tester) async {
      await tester.pumpWidget(_harness(const CliDetection.notInstalled()));
      await tester.pump();
      expect(find.textContaining('Not installed'), findsOneWidget);
      expect(find.textContaining('Install Claude Code'), findsOneWidget);
    });

    testWidgets('shows authenticated status for CliInstalled authenticated', (tester) async {
      await tester.pumpWidget(
        _harness(
          CliDetection.installed(
            version: '2.1.104',
            binaryPath: '/usr/local/bin/claude',
            authStatus: CliAuthStatus.authenticated,
            checkedAt: DateTime.now(),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('authenticated'), findsOneWidget);
      expect(find.textContaining('v2.1.104'), findsOneWidget);
      expect(find.textContaining('Re-check'), findsOneWidget);
    });

    testWidgets('shows copy-to-clipboard CTA when unauthenticated', (tester) async {
      await tester.pumpWidget(
        _harness(
          CliDetection.installed(
            version: '2.0.0',
            binaryPath: '/usr/local/bin/claude',
            authStatus: CliAuthStatus.unauthenticated,
            checkedAt: DateTime.now(),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('not authenticated'), findsOneWidget);
      expect(find.textContaining('Run this'), findsOneWidget);
      expect(find.text('claude'), findsOneWidget);
    });

    testWidgets('shows Active pill when showActivePill is true', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            claudeCliDetectionProvider.overrideWith(
              () => _FakeDetectionNotifier(
                CliDetection.installed(
                  version: '2.1.0',
                  binaryPath: '/usr/local/bin/claude',
                  authStatus: CliAuthStatus.authenticated,
                  checkedAt: DateTime.now(),
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [AppColors.dark]),
            home: const Scaffold(body: ClaudeCliCard(showActivePill: true)),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Active'), findsOneWidget);
    });
  });
}
