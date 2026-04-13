import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:code_bench_app/data/_core/preferences/onboarding_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingPreferences', () {
    test('isCompleted returns false when never set', () async {
      final prefs = OnboardingPreferences();
      expect(await prefs.isCompleted(), false);
    });

    test('isCompleted returns true after markCompleted', () async {
      final prefs = OnboardingPreferences();
      await prefs.markCompleted();
      expect(await prefs.isCompleted(), true);
    });

    test('markCompleted is idempotent', () async {
      final prefs = OnboardingPreferences();
      await prefs.markCompleted();
      await prefs.markCompleted();
      expect(await prefs.isCompleted(), true);
    });
  });
}
