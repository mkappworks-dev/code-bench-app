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
  });
}
