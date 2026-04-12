import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/session/session_service.dart';

part 'archive_actions.g.dart';

/// Imperative actions for the Archive screen.
@Riverpod(keepAlive: true)
class ArchiveActions extends _$ArchiveActions {
  @override
  FutureOr<void> build() {}

  Future<void> unarchiveSession(String id) => ref.read(sessionServiceProvider).unarchiveSession(id);
}
