import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/ide/repository/ide_launch_repository.dart';
import '../../data/ide/repository/ide_launch_repository_impl.dart';

part 'ide_launch_actions.g.dart';

/// Command notifier mediating every IDE / Finder / terminal launch from
/// the top action bar. Widgets never reach [IdeLaunchRepository] directly.
///
/// The repository already returns a user-facing error message (or `null` on
/// success), so these methods are thin passthroughs — no extra logging
/// is needed at this layer.
@Riverpod(keepAlive: true)
class IdeLaunchActions extends _$IdeLaunchActions {
  @override
  void build() {}

  IdeLaunchRepository get _repo => ref.read(ideLaunchRepositoryProvider);

  Future<String?> openVsCode(String projectPath) => _repo.openVsCode(projectPath);

  Future<String?> openCursor(String projectPath) => _repo.openCursor(projectPath);

  Future<String?> openInFinder(String projectPath) => _repo.openInFinder(projectPath);

  Future<String?> openInTerminal(String projectPath) => _repo.openInTerminal(projectPath);
}
