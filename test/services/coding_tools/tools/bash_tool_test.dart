import 'dart:io';

import 'package:code_bench_app/data/bash/datasource/bash_datasource_process.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/services/coding_tools/tools/bash_tool.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_helpers/tool_test_helpers.dart';

class _ThrowingDatasource extends BashDatasource {
  @override
  Future<BashResult> run({required String command, required String workingDirectory}) async {
    throw FileSystemException('no such directory', '/nonexistent');
  }
}

class _FakeDatasource extends BashDatasource {
  _FakeDatasource(this._result);
  final BashResult _result;

  @override
  Future<BashResult> run({required String command, required String workingDirectory}) async {
    return _result;
  }
}

void main() {
  group('BashTool.execute', () {
    test('returns error when command arg is missing', () async {
      final tool = BashTool(datasource: _FakeDatasource((exitCode: 0, output: '', timedOut: false)));
      final result = await tool.execute(fakeCtx(projectPath: '/tmp'));
      expect(result, isA<CodingToolResultError>());
    });

    test('returns error when command arg is empty string', () async {
      final tool = BashTool(datasource: _FakeDatasource((exitCode: 0, output: '', timedOut: false)));
      final result = await tool.execute(fakeCtx(projectPath: '/tmp', args: {'command': '   '}));
      expect(result, isA<CodingToolResultError>());
    });

    test('returns success with Exit header on success', () async {
      final tool = BashTool(datasource: _FakeDatasource((exitCode: 0, output: 'ok\n', timedOut: false)));
      final result = await tool.execute(fakeCtx(projectPath: '/tmp', args: {'command': 'echo ok'}));
      expect(result, isA<CodingToolResultSuccess>());
      final output = (result as CodingToolResultSuccess).output;
      expect(output, startsWith('Exit 0\n\n'));
      expect(output, contains('ok'));
    });

    test('returns success with Timed out header on timeout', () async {
      final tool = BashTool(datasource: _FakeDatasource((exitCode: -1, output: '', timedOut: true)));
      final result = await tool.execute(fakeCtx(projectPath: '/tmp', args: {'command': 'sleep 200'}));
      expect(result, isA<CodingToolResultSuccess>());
      final output = (result as CodingToolResultSuccess).output;
      expect(output, startsWith('Timed out after 120 s\n\n'));
    });

    test('returns error when datasource throws IOException', () async {
      final tool = BashTool(datasource: _ThrowingDatasource());
      final result = await tool.execute(fakeCtx(projectPath: '/tmp', args: {'command': 'echo hi'}));
      expect(result, isA<CodingToolResultError>());
    });
  });
}
