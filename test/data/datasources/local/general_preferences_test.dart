import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:code_bench_app/data/datasources/local/general_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('GeneralPreferences.autoCommit', () {
    test('returns false by default', () async {
      expect(await GeneralPreferences().getAutoCommit(), false);
    });

    test('returns true after setAutoCommit(true)', () async {
      final prefs = GeneralPreferences();
      await prefs.setAutoCommit(true);
      expect(await prefs.getAutoCommit(), true);
    });
  });

  group('GeneralPreferences.terminalApp', () {
    test('returns "Terminal" by default', () async {
      expect(await GeneralPreferences().getTerminalApp(), 'Terminal');
    });

    test('returns set value', () async {
      final prefs = GeneralPreferences();
      await prefs.setTerminalApp('iTerm');
      expect(await prefs.getTerminalApp(), 'iTerm');
    });
  });

  group('GeneralPreferences.deleteConfirmation', () {
    test('returns true by default', () async {
      expect(await GeneralPreferences().getDeleteConfirmation(), true);
    });

    test('returns false after setDeleteConfirmation(false)', () async {
      final prefs = GeneralPreferences();
      await prefs.setDeleteConfirmation(false);
      expect(await prefs.getDeleteConfirmation(), false);
    });
  });
}
