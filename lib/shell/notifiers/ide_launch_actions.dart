import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../services/ide/ide_service.dart';
import 'ide_launch_failure.dart';

export 'ide_launch_failure.dart';

part 'ide_launch_actions.g.dart';

/// Command notifier mediating every IDE / Finder / terminal launch from
/// the top action bar. Widgets never reach [IdeService] directly.
///
/// Errors are emitted as [AsyncError] carrying an [IdeLaunchFailure] so
/// widgets can use [ref.listen] to surface inline error messages.
@Riverpod(keepAlive: true)
class IdeLaunchActions extends _$IdeLaunchActions {
  @override
  FutureOr<void> build() {}

  IdeLaunchFailure _asFailure(Object e) => switch (e) {
    IdeLaunchFailedException(:final detail) => IdeLaunchFailure.launchFailed(detail ?? e.toString()),
    _ => IdeLaunchFailure.unknown(e),
  };

  Future<void> openVsCode(String projectPath) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(ideServiceProvider).openVsCode(projectPath);
      } catch (e, st) {
        dLog('[IdeLaunchActions] openVsCode failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> openCursor(String projectPath) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(ideServiceProvider).openCursor(projectPath);
      } catch (e, st) {
        dLog('[IdeLaunchActions] openCursor failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> openInFinder(String projectPath) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(ideServiceProvider).openInFinder(projectPath);
      } catch (e, st) {
        dLog('[IdeLaunchActions] openInFinder failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> openInTerminal(String projectPath) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(ideServiceProvider).openInTerminal(projectPath);
      } catch (e, st) {
        dLog('[IdeLaunchActions] openInTerminal failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
}
