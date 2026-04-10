import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/services/git/git_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('git_service_test_');
    await Process.run('git', ['init'], workingDirectory: tempDir.path);
    await Process.run(
      'git',
      ['config', 'user.email', 'test@test.com'],
      workingDirectory: tempDir.path,
    );
    await Process.run(
      'git',
      ['config', 'user.name', 'Test'],
      workingDirectory: tempDir.path,
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('initGit creates .git directory', () async {
    final dir = await Directory.systemTemp.createTemp('git_init_test_');
    addTearDown(() => dir.delete(recursive: true));
    final svc = GitService(dir.path);
    await svc.initGit();
    expect(Directory('${dir.path}/.git').existsSync(), isTrue);
  });

  test('commit stages and commits a file', () async {
    File('${tempDir.path}/hello.txt').writeAsStringSync('hi');
    final svc = GitService(tempDir.path);
    final sha = await svc.commit('test: initial commit');
    expect(sha, isNotEmpty);
    expect(sha.length, greaterThanOrEqualTo(7));
  });

  test('fetchBehindCount returns 0 for repo with no remote', () async {
    final svc = GitService(tempDir.path);
    final count = await svc.fetchBehindCount();
    expect(count, 0);
  });

  test('listRemotes returns empty list when no remotes configured', () async {
    final svc = GitService(tempDir.path);
    final remotes = await svc.listRemotes();
    expect(remotes, isEmpty);
  });
}
