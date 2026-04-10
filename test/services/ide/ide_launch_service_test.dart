import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/services/ide/ide_launch_service.dart';

void main() {
  test('buildVsCodeArgs returns correct arguments', () {
    expect(
      IdeLaunchService.buildVsCodeArgs('/path/to/project'),
      equals(['/path/to/project']),
    );
  });

  test('buildFinderArgs returns open command args', () {
    expect(
      IdeLaunchService.buildFinderArgs('/path/to/project'),
      equals(['/path/to/project']),
    );
  });

  test('buildTerminalArgs returns -a <app> <path>', () {
    expect(
      IdeLaunchService.buildTerminalArgs('/path', 'iTerm'),
      equals(['-a', 'iTerm', '/path']),
    );
  });
}
