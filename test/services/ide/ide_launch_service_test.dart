import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/ide/datasource/ide_launch_datasource_process.dart';

void main() {
  test('buildVsCodeArgs prepends `--` so a path starting with `-` is not a flag', () {
    expect(IdeLaunchDatasourceProcess.buildVsCodeArgs('/path/to/project'), equals(['--', '/path/to/project']));
    expect(IdeLaunchDatasourceProcess.buildVsCodeArgs('-tricky'), equals(['--', '-tricky']));
  });

  test('buildFinderArgs prepends `--` so a path starting with `-` is not a flag', () {
    // Regression: `open -foo` would interpret `-foo` as an option; the
    // `--` separator forces the rest of argv to be treated as positional.
    expect(IdeLaunchDatasourceProcess.buildFinderArgs('/path/to/project'), equals(['--', '/path/to/project']));
    expect(IdeLaunchDatasourceProcess.buildFinderArgs('-tricky'), equals(['--', '-tricky']));
  });

  test('buildTerminalArgs returns -a <app> -- <path>', () {
    expect(IdeLaunchDatasourceProcess.buildTerminalArgs('/path', 'iTerm'), equals(['-a', 'iTerm', '--', '/path']));
  });
}
