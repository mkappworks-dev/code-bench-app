import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:code_bench_app/app.dart';
import 'package:code_bench_app/features/general/notifiers/general_prefs_notifier.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [generalPrefsProvider.overrideWith(() => _StubGeneralPrefsNotifier())],
        child: const CodeBenchApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

class _StubGeneralPrefsNotifier extends GeneralPrefsNotifier {
  @override
  Future<GeneralPrefsNotifierState> build() async {
    return const GeneralPrefsNotifierState(
      autoCommit: false,
      deleteConfirmation: true,
      terminalApp: '',
      themeMode: ThemeMode.system,
    );
  }
}
