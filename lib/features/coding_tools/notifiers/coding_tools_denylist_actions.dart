import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/denylist_category.dart';
import '../../../data/coding_tools/models/denylist_defaults.dart';
import '../../../data/coding_tools/repository/coding_tools_denylist_repository_impl.dart';
import 'coding_tools_denylist_failure.dart';
import 'coding_tools_denylist_notifier.dart';

export 'coding_tools_denylist_failure.dart';

part 'coding_tools_denylist_actions.g.dart';

@Riverpod(keepAlive: true)
class CodingToolsDenylistActions extends _$CodingToolsDenylistActions {
  @override
  FutureOr<void> build() {}

  CodingToolsDenylistFailure _asFailure(Object e) => switch (e) {
    CodingToolsDenylistFailure() => e,
    _ => CodingToolsDenylistFailure.unknown(e),
  };

  String _normalize(String raw) => raw.trim();

  Future<void> addUserEntry(DenylistCategory category, String raw) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final value = _normalize(raw);
        if (value.isEmpty) throw const CodingToolsDenylistFailure.invalidEntry();
        final repo = ref.read(codingToolsDenylistRepositoryProvider);
        final current = await repo.load();
        final added = {...(current.userAdded[category] ?? const <String>{})};
        final baseline = DenylistDefaults.forCategory(category);
        if (added.contains(value) || baseline.contains(value)) {
          throw const CodingToolsDenylistFailure.duplicate();
        }
        added.add(value);
        await repo.save(current.copyWith(userAdded: {...current.userAdded, category: added}));
        ref.invalidate(codingToolsDenylistProvider);
      } catch (e, st) {
        dLog('[CodingToolsDenylistActions] addUserEntry failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> removeUserEntry(DenylistCategory category, String value) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final repo = ref.read(codingToolsDenylistRepositoryProvider);
        final current = await repo.load();
        final added = {...(current.userAdded[category] ?? const <String>{})}..remove(value);
        await repo.save(current.copyWith(userAdded: {...current.userAdded, category: added}));
        ref.invalidate(codingToolsDenylistProvider);
      } catch (e, st) {
        dLog('[CodingToolsDenylistActions] removeUserEntry failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> suppressBaseline(DenylistCategory category, String value) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final repo = ref.read(codingToolsDenylistRepositoryProvider);
        final current = await repo.load();
        final suppressed = {...(current.suppressedDefaults[category] ?? const <String>{})}..add(value);
        await repo.save(current.copyWith(suppressedDefaults: {...current.suppressedDefaults, category: suppressed}));
        ref.invalidate(codingToolsDenylistProvider);
      } catch (e, st) {
        dLog('[CodingToolsDenylistActions] suppressBaseline failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> restoreBaseline(DenylistCategory category, String value) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final repo = ref.read(codingToolsDenylistRepositoryProvider);
        final current = await repo.load();
        final suppressed = {...(current.suppressedDefaults[category] ?? const <String>{})}..remove(value);
        await repo.save(current.copyWith(suppressedDefaults: {...current.suppressedDefaults, category: suppressed}));
        ref.invalidate(codingToolsDenylistProvider);
      } catch (e, st) {
        dLog('[CodingToolsDenylistActions] restoreBaseline failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> restoreCategory(DenylistCategory category) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final repo = ref.read(codingToolsDenylistRepositoryProvider);
        final current = await repo.load();
        await repo.save(
          current.copyWith(
            userAdded: {...current.userAdded, category: <String>{}},
            suppressedDefaults: {...current.suppressedDefaults, category: <String>{}},
          ),
        );
        ref.invalidate(codingToolsDenylistProvider);
      } catch (e, st) {
        dLog('[CodingToolsDenylistActions] restoreCategory failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> restoreAll() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(codingToolsDenylistRepositoryProvider).restoreAllDefaults();
        ref.invalidate(codingToolsDenylistProvider);
      } catch (e, st) {
        dLog('[CodingToolsDenylistActions] restoreAll failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
}
