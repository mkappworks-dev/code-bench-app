import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/session/repository/session_repository_impl.dart';

part 'archive_actions.g.dart';

/// Imperative actions for the Archive screen.
@Riverpod(keepAlive: true)
class ArchiveActions extends _$ArchiveActions {
  @override
  FutureOr<void> build() {}

  Future<void> unarchiveSession(String id) async {
    final repo = await ref.read(sessionRepositoryProvider.future);
    return repo.unarchiveSession(id);
  }
}
