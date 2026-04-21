import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';
import 'package:code_bench_app/features/coding_tools/notifiers/coding_tools_denylist_notifier.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loads empty state with all baseline defaults available', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = await container.read(codingToolsDenylistProvider.future);
    expect(state.userAdded[DenylistCategory.filename], isEmpty);
    expect(state.suppressedDefaults[DenylistCategory.filename], isEmpty);
  });
}
