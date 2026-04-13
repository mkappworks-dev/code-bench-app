import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/project/models/project_action.dart';

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

/// Notifier that runs a user-defined [ProjectAction] as a subprocess and
/// streams its stdout/stderr lines into [ActionOutputState].
///
/// Lives in `lib/shell/notifiers/` because [ActionOutputPanel] (the widget
/// that displays it) is a shell-level widget. The actual process lifecycle
/// (`Process.start`) is confined here — widgets only call [run] and [clear].
@Riverpod(keepAlive: true)
class ActionOutputNotifier extends _$ActionOutputNotifier {
  Process? _currentProcess;

  @override
  ActionOutputState build() => const ActionOutputState();

  void appendLine(String line, ActionStatus status, String? name) {
    state = state.copyWith(lines: [...state.lines, line], status: status, actionName: name ?? state.actionName);
  }

  void clear() {
    _currentProcess?.kill();
    _currentProcess = null;
    state = const ActionOutputState();
  }

  Future<void> run(ProjectAction action, String workingDirectory) async {
    // Kill any currently running process first.
    _currentProcess?.kill();
    _currentProcess = null;
    state = ActionOutputState(status: ActionStatus.running, lines: const [], actionName: action.name);

    // Split shell command into executable + args (MVP: no quoted-arg support).
    final parts = action.command.trim().split(RegExp(r'\s+'));
    final executable = parts.first;
    final args = parts.skip(1).toList();

    try {
      // SECURITY: NEVER set runInShell: true here. Arguments are passed as
      // a literal argv list; enabling shell mode would turn any user-defined
      // command into a shell-injection vector once variables get interpolated.
      final process = await Process.start(executable, args, workingDirectory: workingDirectory);
      _currentProcess = process;

      // Drain both streams to completion. We must await the stream futures
      // alongside exitCode — otherwise late-arriving lines would fire their
      // listeners AFTER we set the terminal status, and copyWith(lines: …)
      // would silently revert `status` from done/failed back to running.
      final stdoutDone = process.stdout.transform(const SystemEncoding().decoder).forEach((chunk) {
        for (final line in chunk.split('\n')) {
          if (line.isNotEmpty) {
            state = state.copyWith(lines: [...state.lines, line]);
          }
        }
      });

      final stderrDone = process.stderr.transform(const SystemEncoding().decoder).forEach((chunk) {
        for (final line in chunk.split('\n')) {
          if (line.isNotEmpty) {
            state = state.copyWith(lines: [...state.lines, line]);
          }
        }
      });

      final results = await Future.wait([stdoutDone, stderrDone, process.exitCode]);
      _currentProcess = null;
      final code = results[2] as int;
      state = state.copyWith(status: code == 0 ? ActionStatus.done : ActionStatus.failed, exitCode: code);
    } on ProcessException catch (e) {
      // Distinguish "command not found" from other failures so the user gets
      // actionable guidance instead of a cryptic stack trace.
      _currentProcess = null;
      state = state.copyWith(
        status: ActionStatus.failed,
        lines: [
          ...state.lines,
          'Command not found or failed to start: ${e.executable}',
          'Check the action in the Actions dropdown → Add action.',
        ],
        exitCode: -1,
      );
    }
  }
}
