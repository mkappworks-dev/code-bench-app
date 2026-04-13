import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/git/datasource/git_datasource_process.dart';

void main() {
  late Directory tempDir;

  Future<void> configureIdentity(String path) async {
    await Process.run('git', ['config', 'user.email', 'test@test.com'], workingDirectory: path);
    await Process.run('git', ['config', 'user.name', 'Test'], workingDirectory: path);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('git_service_test_');
    await Process.run('git', ['init'], workingDirectory: tempDir.path);
    await configureIdentity(tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('initGit creates .git directory', () async {
    final dir = await Directory.systemTemp.createTemp('git_init_test_');
    addTearDown(() => dir.delete(recursive: true));
    final svc = GitDatasourceProcess(dir.path);
    await svc.initGit();
    expect(Directory('${dir.path}/.git').existsSync(), isTrue);
  });

  test('commit stages and commits a file (root commit path)', () async {
    File('${tempDir.path}/hello.txt').writeAsStringSync('hi');
    final svc = GitDatasourceProcess(tempDir.path);
    final sha = await svc.commit('test: initial commit');
    expect(sha, isNotEmpty);
    expect(sha.length, greaterThanOrEqualTo(7));
  });

  test('commit parses SHA on a feature branch containing `-`', () async {
    // Regression test for a regex that previously excluded `-` from branch
    // names, causing the short-SHA parse to return an empty string.
    File('${tempDir.path}/one.txt').writeAsStringSync('one');
    final svc = GitDatasourceProcess(tempDir.path);
    await svc.commit('feat: initial');
    // Create and switch to a branch with `-` in its name.
    await Process.run('git', ['checkout', '-b', 'feat/2026-04-10-foo'], workingDirectory: tempDir.path);
    File('${tempDir.path}/two.txt').writeAsStringSync('two');
    final sha = await svc.commit('feat: second commit');
    expect(sha, isNotEmpty);
    expect(sha, matches(RegExp(r'^[a-f0-9]+$')));
  });

  test('fetchBehindCount returns null when no upstream is configured', () async {
    // Null (not 0) means "unknown" so the UI can distinguish from "up to date".
    final svc = GitDatasourceProcess(tempDir.path);
    final count = await svc.fetchBehindCount();
    expect(count, isNull);
  });

  test('currentBranch returns null outside a git repo', () async {
    final dir = await Directory.systemTemp.createTemp('no_git_');
    addTearDown(() => dir.delete(recursive: true));
    final svc = GitDatasourceProcess(dir.path);
    expect(await svc.currentBranch(), isNull);
  });

  test('getOriginUrl returns null when no origin is configured', () async {
    final svc = GitDatasourceProcess(tempDir.path);
    expect(await svc.getOriginUrl(), isNull);
  });

  test('listRemotes returns empty list when no remotes configured', () async {
    final svc = GitDatasourceProcess(tempDir.path);
    final remotes = await svc.listRemotes();
    expect(remotes, isEmpty);
  });

  test('pushToRemote rejects a remote name that looks like a flag', () async {
    final svc = GitDatasourceProcess(tempDir.path);
    expect(() => svc.pushToRemote('-d'), throwsA(isA<GitException>()));
  });
}
