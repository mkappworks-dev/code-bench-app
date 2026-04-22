// test/services/coding_tools/tools/str_replace_tool_test.dart

import 'dart:io';

import 'package:code_bench_app/data/apply/models/applied_change.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:code_bench_app/services/coding_tools/tools/str_replace_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../_helpers/tool_test_helpers.dart';

// ---------------------------------------------------------------------------
// Stub that always throws [ApplyContentChangedException] from [applyChange].
// Used to test the catch clause in StrReplaceTool without a real race condition.
// ---------------------------------------------------------------------------
class _ContentChangedApplyService extends ApplyService {
  _ContentChangedApplyService({required super.repo});

  @override
  Future<AppliedChange> applyChange({
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
    String? expectedChecksum,
  }) async {
    throw const ApplyContentChangedException();
  }
}

void main() {
  late Directory projectDir;
  late StrReplaceTool tool;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('repl_tool_');
    final applyRepo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()));
    tool = StrReplaceTool(
      repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()),
      applyService: ApplyService(repo: applyRepo),
    );
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  test('replaces a unique occurrence', () async {
    File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('hello world');
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'path': 'x.txt', 'old_str': 'world', 'new_str': 'dart'}),
    );
    expect(r, isA<CodingToolResultSuccess>());
    expect(File(p.join(projectDir.path, 'x.txt')).readAsStringSync(), 'hello dart');
  });

  test('returns error when old_str not found', () async {
    File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('hello');
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'path': 'x.txt', 'old_str': 'missing', 'new_str': 'x'}),
    );
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('not found'));
  });

  test('returns error when old_str matches multiple times', () async {
    File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('ab ab ab');
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'path': 'x.txt', 'old_str': 'ab', 'new_str': 'cd'}),
    );
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('matches 3 times'));
  });

  test('surfaces ctx.safePath errors (path escape sanity)', () async {
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'path': '../x', 'old_str': 'a', 'new_str': 'b'}),
    );
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('outside'));
  });

  test('returns error with "was modified externally" when ApplyContentChangedException is thrown', () async {
    final applyRepo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()));
    final toolWithStub = StrReplaceTool(
      repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()),
      applyService: _ContentChangedApplyService(repo: applyRepo),
    );
    File(p.join(projectDir.path, 'race.txt')).writeAsStringSync('hello world');
    final r = await toolWithStub.execute(
      fakeCtx(projectPath: projectDir.path, args: {'path': 'race.txt', 'old_str': 'world', 'new_str': 'dart'}),
    );
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('was modified externally'));
  });
}
