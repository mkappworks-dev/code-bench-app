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

    test('returns true when .git file points to a legitimate worktree dir', () async {
      // Construct a fake but well-formed worktree layout: a main repo with a
      // `.git/worktrees/<name>` metadata directory, and a sibling worktree
      // whose `.git` file points at it.
      final mainRepo = await Directory('${tmpDir.path}/main').create(recursive: true);
      final worktreeMeta = await Directory('${mainRepo.path}/.git/worktrees/feat').create(recursive: true);
      final wtCheckout = await Directory('${tmpDir.path}/wt').create();
      await File('${wtCheckout.path}/.git').writeAsString('gitdir: ${worktreeMeta.path}\n');

      expect(GitDetector.isGitRepo(wtCheckout.path), isTrue);
    });

    test('returns true when .git file points to a submodule metadata dir', () async {
      final superProject = await Directory('${tmpDir.path}/super').create();
      final moduleMeta = await Directory('${superProject.path}/.git/modules/sub').create(recursive: true);
      final submodule = await Directory('${superProject.path}/sub').create();
      await File('${submodule.path}/.git').writeAsString('gitdir: ${moduleMeta.path}\n');

      expect(GitDetector.isGitRepo(submodule.path), isTrue);
    });

    test('returns false when .git file has no gitdir: line', () async {
      await File('${tmpDir.path}/.git').writeAsString('this is not a worktree file');
      expect(GitDetector.isGitRepo(tmpDir.path), isFalse);
    });

    test('returns false when .git file points to a non-existent path', () async {
      await File('${tmpDir.path}/.git').writeAsString('gitdir: /nonexistent/path/to/worktrees/foo\n');
      expect(GitDetector.isGitRepo(tmpDir.path), isFalse);
    });

    test('returns false when .git file points outside worktree/modules metadata (attack)', () async {
      // Attacker-crafted .git file that would otherwise make the app probe
      // an unrelated repo on disk. The canonical target is a real directory
      // (so canonicalize succeeds), but it does NOT contain
      // `/.git/worktrees/` or `/.git/modules/`.
      final unrelated = await Directory('${tmpDir.path}/unrelated').create();
      await File('${tmpDir.path}/.git').writeAsString('gitdir: ${unrelated.path}\n');

      expect(GitDetector.isGitRepo(tmpDir.path), isFalse);
    });

    test('returns false when .git file uses `..` traversal to escape the project', () async {
      // `..` is collapsed by resolveSymbolicLinksSync, so the canonical path
      // is `tmpDir` itself — which does not contain the required segments.
      await File('${tmpDir.path}/.git').writeAsString('gitdir: ..\n');
      expect(GitDetector.isGitRepo(tmpDir.path), isFalse);
    });
  });

  group('GitDetector.getCurrentBranch', () {
    test('returns null for a non-git directory', () {
      expect(GitDetector.getCurrentBranch(tmpDir.path), isNull);
    });

    test('returns branch name for a real git repo', () async {
      await Process.run('git', ['init', '-b', 'main'], workingDirectory: tmpDir.path);
      await Process.run('git', ['config', 'user.email', 'test@test.com'], workingDirectory: tmpDir.path);
      await Process.run('git', ['config', 'user.name', 'Test'], workingDirectory: tmpDir.path);
      await File('${tmpDir.path}/readme.txt').writeAsString('hi');
      await Process.run('git', ['add', '.'], workingDirectory: tmpDir.path);
      await Process.run('git', ['commit', '-m', 'init'], workingDirectory: tmpDir.path);

      expect(GitDetector.getCurrentBranch(tmpDir.path), equals('main'));
    });

    test('returns null for detached HEAD (not the literal string "HEAD")', () async {
      await Process.run('git', ['init', '-b', 'main'], workingDirectory: tmpDir.path);
      await Process.run('git', ['config', 'user.email', 'test@test.com'], workingDirectory: tmpDir.path);
      await Process.run('git', ['config', 'user.name', 'Test'], workingDirectory: tmpDir.path);
      await File('${tmpDir.path}/readme.txt').writeAsString('hi');
      await Process.run('git', ['add', '.'], workingDirectory: tmpDir.path);
      await Process.run('git', ['commit', '-m', 'init'], workingDirectory: tmpDir.path);
      // Detach.
      final sha = await Process.run('git', ['rev-parse', 'HEAD'], workingDirectory: tmpDir.path);
      await Process.run('git', ['checkout', (sha.stdout as String).trim()], workingDirectory: tmpDir.path);

      expect(GitDetector.getCurrentBranch(tmpDir.path), isNull);
    });
  });
}
