import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/project_action.dart';

part 'action_runner_service.freezed.dart';
part 'action_runner_service.g.dart';

enum ActionStatus { idle, running, done, failed }

@freezed
class ActionOutputState with _$ActionOutputState {
  const factory ActionOutputState({
    @Default(ActionStatus.idle) ActionStatus status,
    @Default([]) List<String> lines,
    String? actionName,
    int? exitCode,
  }) = _ActionOutputState;
}

@Riverpod(keepAlive: true)
class ActionOutputNotifier extends _$ActionOutputNotifier {
  Process? _currentProcess;

  @override
  ActionOutputState build() => const ActionOutputState();

  void appendLine(String line, ActionStatus status, String? name) {
    state = state.copyWith(
      lines: [...state.lines, line],
      status: status,
      actionName: name ?? state.actionName,
    );
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
    state = ActionOutputState(
      status: ActionStatus.running,
      lines: const [],
      actionName: action.name,
    );

    // Split shell command into executable + args (MVP: no quoted-arg support).
    final parts = action.command.trim().split(RegExp(r'\s+'));
    final executable = parts.first;
    final args = parts.skip(1).toList();

    try {
      final process = await Process.start(
        executable,
        args,
        workingDirectory: workingDirectory,
      );
      _currentProcess = process;

      process.stdout.transform(const SystemEncoding().decoder).listen((chunk) {
        for (final line in chunk.split('\n')) {
          if (line.isNotEmpty) {
            state = state.copyWith(lines: [...state.lines, line]);
          }
        }
      });

      process.stderr.transform(const SystemEncoding().decoder).listen((chunk) {
        for (final line in chunk.split('\n')) {
          if (line.isNotEmpty) {
            state = state.copyWith(lines: [...state.lines, line]);
          }
        }
      });

      final code = await process.exitCode;
      _currentProcess = null;
      state = state.copyWith(
        status: code == 0 ? ActionStatus.done : ActionStatus.failed,
        exitCode: code,
      );
    } catch (e) {
      state = state.copyWith(
        status: ActionStatus.failed,
        lines: [...state.lines, 'Error: $e'],
        exitCode: -1,
      );
    }
  }
}
