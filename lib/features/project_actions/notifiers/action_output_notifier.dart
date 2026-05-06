import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/project/models/action_run.dart';
import '../../../data/project/models/project_action.dart';
import '../../../services/project/action_runner_service.dart';

part 'action_output_notifier.freezed.dart';
part 'action_output_notifier.g.dart';

enum ActionStatus { idle, running, done, failed }

@freezed
abstract class ActionOutputState with _$ActionOutputState {
  const factory ActionOutputState({
    @Default(ActionStatus.idle) ActionStatus status,
    @Default([]) List<String> lines,
    String? actionName,
    int? exitCode,
  }) = _ActionOutputState;
}

@Riverpod(keepAlive: true)
class ActionOutputNotifier extends _$ActionOutputNotifier {
  ActionRun? _currentRun;

  @override
  ActionOutputState build() => const ActionOutputState();

  void appendLine(String line, ActionStatus status, String? name) {
    state = state.copyWith(lines: [...state.lines, line], status: status, actionName: name ?? state.actionName);
  }

  void clear() {
    _currentRun?.kill();
    _currentRun = null;
    state = const ActionOutputState();
  }

  Future<void> run(ProjectAction action, String workingDirectory) async {
    _currentRun?.kill();
    _currentRun = null;
    state = ActionOutputState(status: ActionStatus.running, lines: const [], actionName: action.name);

    // Split shell command into executable + args (MVP: no quoted-arg support).
    final parts = action.command.trim().split(RegExp(r'\s+'));

    try {
      final run = await ref
          .read(actionRunnerServiceProvider)
          .start(executable: parts.first, args: parts.skip(1).toList(), workingDirectory: workingDirectory);
      _currentRun = run;

      // Drain output and await exit code together so late-arriving lines do
      // not fire after the terminal status is set.
      final results = await Future.wait<dynamic>([
        run.lines.forEach((line) => state = state.copyWith(lines: [...state.lines, line])),
        run.exitCode,
      ]);
      _currentRun = null;
      final code = results[1] as int;
      state = state.copyWith(status: code == 0 ? ActionStatus.done : ActionStatus.failed, exitCode: code);
    } on ActionRunnerException catch (e) {
      _currentRun = null;
      dLog('[ActionOutputNotifier] run failed to start: ${e.executable}');
      state = state.copyWith(
        status: ActionStatus.failed,
        lines: [
          ...state.lines,
          'Command not found or failed to start: ${e.executable}',
          'Check the action in the Actions dropdown → Add action.',
        ],
        exitCode: -1,
      );
    } catch (e) {
      _currentRun = null;
      dLog('[ActionOutputNotifier] run failed unexpectedly: $e');
      state = state.copyWith(
        status: ActionStatus.failed,
        lines: [...state.lines, 'Action failed unexpectedly.'],
        exitCode: -1,
      );
    }
  }
}
