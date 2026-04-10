import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/services/ide/ide_launch_service.dart';

void main() {
  test('buildVsCodeArgs returns [path]', () {
    expect(
      IdeLaunchService.buildVsCodeArgs('/path/to/project'),
      equals(['/path/to/project']),
    );
  });

  test('buildFinderArgs prepends `--` so a path starting with `-` is not a flag', () {
    // Regression: `open -foo` would interpret `-foo` as an option; the
    // `--` separator forces the rest of argv to be treated as positional.
    expect(
      IdeLaunchService.buildFinderArgs('/path/to/project'),
      equals(['--', '/path/to/project']),
    );
    expect(
      IdeLaunchService.buildFinderArgs('-tricky'),
      equals(['--', '-tricky']),
    );
  });

  test('buildTerminalArgs returns -a <app> -- <path>', () {
    expect(
      IdeLaunchService.buildTerminalArgs('/path', 'iTerm'),
      equals(['-a', 'iTerm', '--', '/path']),
    );
  });
}
