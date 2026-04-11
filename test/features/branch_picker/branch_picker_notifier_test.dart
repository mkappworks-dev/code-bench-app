import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/features/branch_picker/branch_picker_notifier.dart';
import 'package:code_bench_app/services/git/git_service.dart';

Future<Directory> _initRepo({String branchName = 'main'}) async {
  final dir = await Directory.systemTemp.createTemp('bp_notifier_test_');
  await Process.run('git', ['init', '-b', branchName], workingDirectory: dir.path);
  await Process.run('git', ['config', 'user.email', 'test@test.com'], workingDirectory: dir.path);
  await Process.run('git', ['config', 'user.name', 'Test'], workingDirectory: dir.path);
  await File('${dir.path}/readme.txt').writeAsString('hello');
  await Process.run('git', ['add', '.'], workingDirectory: dir.path);
  await Process.run('git', ['commit', '-m', 'init'], workingDirectory: dir.path);
  return dir;
}

void main() {
  group('BranchPickerNotifier', () {
    late Directory repoDir;
    late BranchPickerNotifier notifier;

    setUp(() async {
      repoDir = await _initRepo();
      notifier = BranchPickerNotifier(repoDir.path);
    });

    tearDown(() async {
      await repoDir.delete(recursive: true);
    });

    test('listLocalBranches includes current branch', () async {
      final branches = await notifier.listLocalBranches();
      expect(branches, isNotEmpty);
      expect(branches.first, equals(await GitService(repoDir.path).currentBranch()));
    });

    test('worktreeBranches is empty for a plain repo', () async {
      final wt = await notifier.worktreeBranches();
      expect(wt, isEmpty);
    });

    test('checkout switches to an existing branch', () async {
      // Create a second branch
      await Process.run('git', ['checkout', '-b', 'feat/test'], workingDirectory: repoDir.path);
      await Process.run('git', ['checkout', 'main'], workingDirectory: repoDir.path);

      await notifier.checkout('feat/test');

      final current = await GitService(repoDir.path).currentBranch();
      expect(current, equals('feat/test'));
    });

    test('checkout throws GitException on unknown branch', () async {
      expect(() => notifier.checkout('no-such-branch'), throwsA(isA<GitException>()));
    });

    test('createBranch creates and switches to new branch', () async {
      await notifier.createBranch('feat/new');
      final current = await GitService(repoDir.path).currentBranch();
      expect(current, equals('feat/new'));
    });

    test('createBranch throws ArgumentError on invalid name (leading dash)', () async {
      expect(() => notifier.createBranch('-bad'), throwsA(isA<ArgumentError>()));
    });

    test('createBranch throws ArgumentError on empty name', () async {
      expect(() => notifier.createBranch(''), throwsA(isA<ArgumentError>()));
    });

    test('createBranch throws ArgumentError on name containing spaces', () async {
      expect(() => notifier.createBranch('has space'), throwsA(isA<ArgumentError>()));
    });

    test('checkout throws ArgumentError on leading-dash name (security guard)', () async {
      // Defence-in-depth against a malicious repo that surfaces a ref named
      // `--orphan` in the picker: the click must NOT reach
      // `git checkout --orphan`.
      expect(() => notifier.checkout('--orphan'), throwsA(isA<ArgumentError>()));
    });

    test('checkout throws ArgumentError on empty name', () async {
      expect(() => notifier.checkout(''), throwsA(isA<ArgumentError>()));
    });

    test('checkout throws GitException when working tree is dirty', () async {
      // Create a second branch that diverges, then modify tracked content
      // so a checkout back would overwrite uncommitted changes.
      await Process.run('git', ['checkout', '-b', 'feat/other'], workingDirectory: repoDir.path);
      await File('${repoDir.path}/readme.txt').writeAsString('changed on other');
      await Process.run('git', ['add', '.'], workingDirectory: repoDir.path);
      await Process.run('git', ['commit', '-m', 'divergent'], workingDirectory: repoDir.path);
      await Process.run('git', ['checkout', 'main'], workingDirectory: repoDir.path);
      // Dirty the same file on main without committing.
      await File('${repoDir.path}/readme.txt').writeAsString('dirty');

      expect(() => notifier.checkout('feat/other'), throwsA(isA<GitException>()));
    });

    test('worktreeBranches parses `git worktree list --porcelain` output', () async {
      // Create a second branch, then a real worktree checking it out in a
      // sibling directory. `git worktree list --porcelain` in the main
      // checkout should then enumerate that branch.
      await Process.run('git', ['branch', 'feat/alt'], workingDirectory: repoDir.path);
      final siblingPath = '${repoDir.parent.path}/wt_${DateTime.now().microsecondsSinceEpoch}';
      addTearDown(() async {
        // Clean up the external worktree directory after the test.
        final d = Directory(siblingPath);
        if (d.existsSync()) await d.delete(recursive: true);
      });
      final addResult = await Process.run('git', [
        'worktree',
        'add',
        siblingPath,
        'feat/alt',
      ], workingDirectory: repoDir.path);
      expect(addResult.exitCode, equals(0), reason: addResult.stderr as String);

      final worktrees = await notifier.worktreeBranches();
      expect(worktrees, contains('feat/alt'));
      // The main worktree's own branch must NOT be listed — it's skipped
      // by design so the picker doesn't mark the current branch as
      // "checked out in another worktree".
      expect(worktrees, isNot(contains('main')));
    });
  });
}
