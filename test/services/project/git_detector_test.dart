import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/services/project/git_detector.dart';

void main() {
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('git_detector_test_');
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
  });

  group('GitDetector.isGitRepo', () {
    test('returns false when no .git entry exists', () {
      expect(GitDetector.isGitRepo(tmpDir.path), isFalse);
    });

    test('returns true when .git is a directory (normal repo)', () async {
      await Directory('${tmpDir.path}/.git').create();
      expect(GitDetector.isGitRepo(tmpDir.path), isTrue);
    });

    test('returns true when .git is a file (worktree)', () async {
      await File('${tmpDir.path}/.git').writeAsString('gitdir: ../.git/worktrees/foo');
      expect(GitDetector.isGitRepo(tmpDir.path), isTrue);
    });
  });
}
