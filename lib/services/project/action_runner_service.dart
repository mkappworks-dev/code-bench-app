import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/project/datasource/action_runner_datasource_process.dart';
import '../../data/project/models/action_run.dart';

export '../../data/project/action_runner_exceptions.dart';

part 'action_runner_service.g.dart';

@Riverpod(keepAlive: true)
ActionRunnerService actionRunnerService(Ref ref) => ActionRunnerService(ActionRunnerDatasource());

class ActionRunnerService {
  ActionRunnerService(this._ds);
  final ActionRunnerDatasource _ds;

  Future<ActionRun> start({required String executable, required List<String> args, required String workingDirectory}) =>
      _ds.start(executable: executable, args: args, workingDirectory: workingDirectory);
}
