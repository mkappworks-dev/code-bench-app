import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/services/git/git_live_state_provider.dart';

Future<Directory> _initGitRepo() async {
  final dir = await Directory.systemTemp.createTemp('git_live_test_');
  await Process.run('git', ['init'], workingDirectory: dir.path);
  await Process.run('git', ['config', 'user.email', 'test@test.com'], workingDirectory: dir.path);
  await Process.run('git', ['config', 'user.name', 'Test'], workingDirectory: dir.path);
  // Create initial commit so HEAD is valid
  await File('${dir.path}/readme.txt').writeAsString('hello');
  await Process.run('git', ['add', '.'], workingDirectory: dir.path);
  await Process.run('git', ['commit', '-m', 'init'], workingDirectory: dir.path);
  return dir;
}

void main() {
  group('gitLiveStateProvider', () {
    test('returns notGit for a non-git directory', () async {
      final dir = await Directory.systemTemp.createTemp('non_git_');
      addTearDown(() => dir.delete(recursive: true));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(gitLiveStateProvider(dir.path).future);
      expect(state.isGit, isFalse);
      expect(state.hasUncommitted, isFalse);
      expect(state.aheadCount, equals(0));
    });

    test('returns correct state for a clean git repo', () async {
      final dir = await _initGitRepo();
      addTearDown(() => dir.delete(recursive: true));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(gitLiveStateProvider(dir.path).future);
      expect(state.isGit, isTrue);
      expect(state.branch, isNotNull);
      expect(state.hasUncommitted, isFalse);
      expect(state.aheadCount, equals(0));
    });

    test('hasUncommitted is true when working tree has changes', () async {
      final dir = await _initGitRepo();
      addTearDown(() => dir.delete(recursive: true));

      await File('${dir.path}/new_file.txt').writeAsString('change');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(gitLiveStateProvider(dir.path).future);
      expect(state.hasUncommitted, isTrue);
    });

    test('isOnDefaultBranch is true on main', () async {
      final dir = await _initGitRepo();
      addTearDown(() => dir.delete(recursive: true));

      // Rename branch to 'main' if git defaulted to something else
      await Process.run('git', ['checkout', '-b', 'main'], workingDirectory: dir.path);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(gitLiveStateProvider(dir.path).future);
      expect(state.isOnDefaultBranch, isTrue);
    });

    test('isOnDefaultBranch is false on a feature branch', () async {
      final dir = await _initGitRepo();
      addTearDown(() => dir.delete(recursive: true));

      await Process.run('git', ['checkout', '-b', 'feat/test'], workingDirectory: dir.path);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(gitLiveStateProvider(dir.path).future);
      expect(state.isOnDefaultBranch, isFalse);
    });
  });

  group('behindCountProvider', () {
    test('returns null when no upstream is configured', () async {
      final dir = await _initGitRepo();
      addTearDown(() => dir.delete(recursive: true));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // No remote → fetchBehindCount returns null
      final count = await container.read(behindCountProvider(dir.path).future);
      expect(count, isNull);
    });
  });
}
