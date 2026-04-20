import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';
import 'package:code_bench_app/features/coding_tools/notifiers/coding_tools_denylist_actions.dart';
import 'package:code_bench_app/features/coding_tools/notifiers/coding_tools_denylist_failure.dart';
import 'package:code_bench_app/features/coding_tools/notifiers/coding_tools_denylist_notifier.dart';

void main() {
  late ProviderContainer c;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    c = ProviderContainer();
    addTearDown(c.dispose);
  });

  test('addUserEntry persists + state reflects it', () async {
    await c.read(codingToolsDenylistProvider.future);
    await c.read(codingToolsDenylistActionsProvider.notifier).addUserEntry(DenylistCategory.filename, 'custom_secret');
    final state = await c.read(codingToolsDenylistProvider.future);
    expect(state.userAdded[DenylistCategory.filename], contains('custom_secret'));
  });

  test('addUserEntry rejects empty input with invalidEntry failure', () async {
    await c.read(codingToolsDenylistActionsProvider.notifier).addUserEntry(DenylistCategory.filename, '  ');
    final err = c.read(codingToolsDenylistActionsProvider).error;
    expect(err, isA<CodingToolsDenylistInvalidEntry>());
  });

  test('suppressBaseline drops the entry from effective', () async {
    await c
        .read(codingToolsDenylistActionsProvider.notifier)
        .suppressBaseline(DenylistCategory.filename, 'credentials');
    final state = await c.read(codingToolsDenylistProvider.future);
    expect(state.effective(DenylistCategory.filename), isNot(contains('credentials')));
  });

  test('restoreCategory clears both userAdded + suppressedDefaults for one kind', () async {
    await c.read(codingToolsDenylistActionsProvider.notifier).addUserEntry(DenylistCategory.filename, 'custom');
    await c.read(codingToolsDenylistActionsProvider.notifier).suppressBaseline(DenylistCategory.filename, '.env');
    await c.read(codingToolsDenylistActionsProvider.notifier).restoreCategory(DenylistCategory.filename);
    final state = await c.read(codingToolsDenylistProvider.future);
    expect(state.userAdded[DenylistCategory.filename], isEmpty);
    expect(state.suppressedDefaults[DenylistCategory.filename], isEmpty);
  });

  test('restoreAll clears everything', () async {
    await c.read(codingToolsDenylistActionsProvider.notifier).addUserEntry(DenylistCategory.filename, 'a');
    await c.read(codingToolsDenylistActionsProvider.notifier).addUserEntry(DenylistCategory.segment, 'b');
    await c.read(codingToolsDenylistActionsProvider.notifier).restoreAll();
    final state = await c.read(codingToolsDenylistProvider.future);
    for (final cat in DenylistCategory.values) {
      expect(state.userAdded[cat], isEmpty);
      expect(state.suppressedDefaults[cat], isEmpty);
    }
  });
}
