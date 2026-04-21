import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:code_bench_app/data/_core/preferences/coding_tools_preferences.dart';
import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_denylist_repository_impl.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('effective() returns baseline when no user state', () async {
    final repo = CodingToolsDenylistRepositoryImpl(prefs: CodingToolsPreferences());
    final effective = await repo.effective(DenylistCategory.filename);
    expect(effective, contains('.env'));
    expect(effective, contains('credentials'));
  });

  test('user-added entries merge in lowercase', () async {
    final repo = CodingToolsDenylistRepositoryImpl(prefs: CodingToolsPreferences());
    final state = (await repo.load()).copyWith(
      userAdded: {
        DenylistCategory.filename: {'COMPANY_TOKEN'},
        for (final c in DenylistCategory.values)
          if (c != DenylistCategory.filename) c: <String>{},
      },
    );
    await repo.save(state);
    final effective = await repo.effective(DenylistCategory.filename);
    expect(effective, contains('company_token'));
  });

  test('suppressed defaults drop out of effective', () async {
    final repo = CodingToolsDenylistRepositoryImpl(prefs: CodingToolsPreferences());
    final state = (await repo.load()).copyWith(
      suppressedDefaults: {
        DenylistCategory.filename: {'credentials'},
        for (final c in DenylistCategory.values)
          if (c != DenylistCategory.filename) c: <String>{},
      },
    );
    await repo.save(state);
    final effective = await repo.effective(DenylistCategory.filename);
    expect(effective, isNot(contains('credentials')));
    expect(effective, contains('.env'));
  });

  test('restoreAllDefaults clears user divergence', () async {
    final repo = CodingToolsDenylistRepositoryImpl(prefs: CodingToolsPreferences());
    final divergent = (await repo.load()).copyWith(
      userAdded: {
        DenylistCategory.filename: {'custom'},
        for (final c in DenylistCategory.values)
          if (c != DenylistCategory.filename) c: <String>{},
      },
    );
    await repo.save(divergent);
    await repo.restoreAllDefaults();
    final effective = await repo.effective(DenylistCategory.filename);
    expect(effective, isNot(contains('custom')));
    expect(effective, contains('.env'));
  });
}
