import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/ide/ide_launch_service.dart';

part 'ide_launch_actions.g.dart';

/// Command notifier mediating every IDE / Finder / terminal launch from
/// the top action bar. Widgets never reach [IdeLaunchService] directly.
///
/// The service already returns a user-facing error message (or `null` on
/// success), so these methods are thin passthroughs — no extra logging
/// is needed at this layer.
@Riverpod(keepAlive: true)
class IdeLaunchActions extends _$IdeLaunchActions {
  @override
  void build() {}

  IdeLaunchService get _svc => ref.read(ideLaunchServiceProvider);

  Future<String?> openVsCode(String projectPath) => _svc.openVsCode(projectPath);

  Future<String?> openCursor(String projectPath) => _svc.openCursor(projectPath);

  Future<String?> openInFinder(String projectPath) => _svc.openInFinder(projectPath);

  Future<String?> openInTerminal(String projectPath) => _svc.openInTerminal(projectPath);
}
