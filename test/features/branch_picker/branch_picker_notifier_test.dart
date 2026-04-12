import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/features/branch_picker/branch_picker_failure.dart';
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
  group('GitService branch ops', () {
    late Directory repoDir;
    late GitService git;

    setUp(() async {
      repoDir = await _initRepo();
      git = GitService(repoDir.path);
    });

    tearDown(() => repoDir.delete(recursive: true));

    test('listLocalBranches returns current branch first', () async {
      await Process.run('git', ['checkout', '-b', 'feat/x'], workingDirectory: repoDir.path);
      await Process.run('git', ['checkout', 'main'], workingDirectory: repoDir.path);
      final branches = await git.listLocalBranches();
      expect(branches.first, equals('main'));
      expect(branches, contains('feat/x'));
    });

    test('worktreeBranches is empty for plain repo', () async {
      final wt = await git.worktreeBranches();
      expect(wt, isEmpty);
    });

    test('checkout switches branch', () async {
      await Process.run('git', ['checkout', '-b', 'feat/y'], workingDirectory: repoDir.path);
      await Process.run('git', ['checkout', 'main'], workingDirectory: repoDir.path);
      await git.checkout('feat/y');
      final branch = await git.currentBranch();
      expect(branch, equals('feat/y'));
    });

    test('checkout rejects flag-shaped branch name', () async {
      expect(() => git.checkout('--orphan'), throwsArgumentError);
    });

    test('createBranch creates and switches to new branch', () async {
      await git.createBranch('new-branch');
      final branch = await git.currentBranch();
      expect(branch, equals('new-branch'));
    });

    test('createBranch rejects flag-shaped name', () async {
      expect(() => git.createBranch('--bad'), throwsArgumentError);
    });
  });

  group('BranchPickerNotifier (AsyncNotifier)', () {
    late Directory repoDir;

    setUp(() async {
      repoDir = await _initRepo();
    });

    tearDown(() async => repoDir.delete(recursive: true));

    // Creates a container with an active listener on the provider so it isn't
    // auto-disposed mid-test (the provider is autoDispose: true by default
    // with @riverpod).
    ProviderContainer makeContainer(String path) {
      final c = ProviderContainer();
      // Keep the provider alive for the duration of the test by holding a
      // subscription. The subscription is discarded when the container disposes.
      c.listen(branchPickerProvider(path), (_, __) {});
      addTearDown(c.dispose);
      return c;
    }

    test('build loads branches successfully', () async {
      final c = makeContainer(repoDir.path);
      final state = await c.read(branchPickerProvider(repoDir.path).future);
      expect(state.branches, isNotEmpty);
      expect(state.branches.first, equals('main'));
      expect(state.worktreeBranches, isEmpty);
    });

    test('checkout transitions to success', () async {
      final c = makeContainer(repoDir.path);
      await c.read(branchPickerProvider(repoDir.path).future);
      await Process.run('git', ['branch', 'feat/test'], workingDirectory: repoDir.path);
      await c.read(branchPickerProvider(repoDir.path).notifier).checkout('feat/test');
      expect(c.read(branchPickerProvider(repoDir.path)).hasError, isFalse);
    });

    test('checkout with flag-shaped name emits BranchPickerInvalidName', () async {
      final c = makeContainer(repoDir.path);
      await c.read(branchPickerProvider(repoDir.path).future);
      await c.read(branchPickerProvider(repoDir.path).notifier).checkout('--orphan');
      final state = c.read(branchPickerProvider(repoDir.path));
      expect(state.hasError, isTrue);
      expect(state.error, isA<BranchPickerInvalidName>());
    });

    test('createBranch emits failure for duplicate name', () async {
      final c = makeContainer(repoDir.path);
      await c.read(branchPickerProvider(repoDir.path).future);
      await c.read(branchPickerProvider(repoDir.path).notifier).createBranch('main');
      final state = c.read(branchPickerProvider(repoDir.path));
      expect(state.hasError, isTrue);
      expect(state.error, isA<BranchPickerFailure>());
    });
  });
}
