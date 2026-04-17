// lib/features/archive/notifiers/archive_actions.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/session/session_service.dart';
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
        final svc = await ref.read(sessionServiceProvider.future);
        await svc.unarchiveSession(id);
      } catch (e, st) {
        dLog('[ArchiveActions] unarchiveSession failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
}
