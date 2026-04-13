import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/session/repository/session_repository_impl.dart';
import 'archive_failure.dart';

part 'archive_actions.g.dart';

/// Imperative actions for the Archive screen.
@Riverpod(keepAlive: true)
class ArchiveActions extends _$ArchiveActions {
  @override
  FutureOr<void> build() {}

  ArchiveFailure _asFailure(Object e) => switch (e) {
    StorageException() => ArchiveFailure.storage(e.message),
    _ => ArchiveFailure.unknown(e),
  };

  Future<void> unarchiveSession(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final repo = await ref.read(sessionRepositoryProvider.future);
        await repo.unarchiveSession(id);
      } catch (e, st) {
        dLog('[ArchiveActions] unarchiveSession failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
}
