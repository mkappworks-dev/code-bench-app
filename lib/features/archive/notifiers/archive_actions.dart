import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/session/session_service.dart';
import 'archive_failure.dart';

part 'archive_actions.g.dart';

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
        dLog('[ArchiveActions] unarchiveSession failed: ${e.runtimeType}');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> deleteSession(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final svc = await ref.read(sessionServiceProvider.future);
        await svc.deleteSession(id);
      } catch (e, st) {
        dLog('[ArchiveActions] deleteSession failed: ${e.runtimeType}');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> unarchiveAllForProject(List<String> ids) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      var i = 0;
      try {
        final svc = await ref.read(sessionServiceProvider.future);
        for (; i < ids.length; i++) {
          await svc.unarchiveSession(ids[i]);
        }
      } catch (e, st) {
        dLog(
          '[ArchiveActions] unarchiveAllForProject failed at ids[$i]=${ids[i]} (${i + 1}/${ids.length}): ${e.runtimeType}',
        );
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> deleteAllForProject(List<String> ids) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      var i = 0;
      try {
        final svc = await ref.read(sessionServiceProvider.future);
        for (; i < ids.length; i++) {
          await svc.deleteSession(ids[i]);
        }
      } catch (e, st) {
        dLog(
          '[ArchiveActions] deleteAllForProject failed at ids[$i]=${ids[i]} (${i + 1}/${ids.length}): ${e.runtimeType}',
        );
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
}
