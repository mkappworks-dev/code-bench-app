import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/denylist_category.dart';
import '../../../services/coding_tools/coding_tools_denylist_service.dart';
import 'coding_tools_denylist_failure.dart';
import 'coding_tools_denylist_notifier.dart';

export 'coding_tools_denylist_failure.dart';

part 'coding_tools_denylist_actions.g.dart';

@Riverpod(keepAlive: true)
class CodingToolsDenylistActions extends _$CodingToolsDenylistActions {
  @override
  FutureOr<void> build() {}

  CodingToolsDenylistFailure _asFailure(Object e) => switch (e) {
    CodingToolsInvalidEntryException() => const CodingToolsDenylistFailure.invalidEntry(),
    CodingToolsDuplicateEntryException() => const CodingToolsDenylistFailure.duplicate(),
    PlatformException() => const CodingToolsDenylistFailure.saveFailed(),
    _ => CodingToolsDenylistFailure.unknown(e),
  };

  String _normalize(String raw) => raw.trim();

  Future<void> addUserEntry(DenylistCategory category, String raw) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final value = _normalize(raw);
        await ref.read(codingToolsDenylistServiceProvider).addUserEntry(category, value);
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
        await ref.read(codingToolsDenylistServiceProvider).removeUserEntry(category, value);
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
        await ref.read(codingToolsDenylistServiceProvider).suppressBaseline(category, value);
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
        await ref.read(codingToolsDenylistServiceProvider).restoreBaseline(category, value);
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
        await ref.read(codingToolsDenylistServiceProvider).restoreCategory(category);
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
        await ref.read(codingToolsDenylistServiceProvider).restoreAll();
        ref.invalidate(codingToolsDenylistProvider);
      } catch (e, st) {
        dLog('[CodingToolsDenylistActions] restoreAll failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
}
