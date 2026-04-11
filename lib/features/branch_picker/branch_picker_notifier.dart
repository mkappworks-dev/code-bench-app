import 'dart:io';

import '../../core/utils/debug_logger.dart';
import '../../services/git/git_service.dart';

/// Plain Dart class that handles git operations for the branch picker.
/// Instantiated per-popover; not a Riverpod provider.
class BranchPickerNotifier {
  BranchPickerNotifier(this.projectPath);

  final String projectPath;

  /// Returns local branch names, current branch first, then alphabetical.
  Future<List<String>> listLocalBranches() async {
    final result = await Process.run('git', ['branch', '--format=%(refname:short)'], workingDirectory: projectPath);
    if (result.exitCode != 0) return [];
    final all = (result.stdout as String).trim().split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final current = await GitService(projectPath).currentBranch();
    if (current != null) {
      all.remove(current);
      return [current, ...all..sort()];
    }
    return all..sort();
  }

  /// Returns the set of branch names checked out in other worktrees.
  Future<Set<String>> worktreeBranches() async {
    final result = await Process.run('git', ['worktree', 'list', '--porcelain'], workingDirectory: projectPath);
    if (result.exitCode != 0) return {};

    // Split into per-worktree blocks (blank-line separated).
    // The first block is always the main worktree — skip it.
    final blocks = (result.stdout as String).trim().split(RegExp(r'\n\n+'));

    final branches = <String>{};
    for (int i = 1; i < blocks.length; i++) {
      for (final line in blocks[i].split('\n')) {
        if (line.startsWith('branch ')) {
          final branchRef = line.substring('branch '.length).trim();
          branches.add(branchRef.replaceFirst('refs/heads/', ''));
        }
      }
    }
    return branches;
  }

  /// Runs `git checkout [branch]`.
  /// Throws [ArgumentError] for invalid names, [GitException] on git failure.
  ///
  /// Defence-in-depth: a cloned-from-attacker repo can ship a ref literally
  /// named `--orphan` (or any leading-dash name). `git branch --format=…`
  /// surfaces it unchanged, the picker renders it, and — without this
  /// guard — a click would reach `git checkout --orphan`, silently mutating
  /// repo state. Mirror the same leading-dash guard used in [createBranch]
  /// and in `GitService.pushToRemote`.
  Future<void> checkout(String branch) async {
    if (branch.isEmpty) {
      throw ArgumentError('Branch name must not be empty.');
    }
    if (branch.startsWith('-')) {
      sLog('[branchPicker] flag-shaped checkout branch rejected: "$branch"');
      throw ArgumentError('Branch name must not start with a dash.');
    }
    final result = await Process.run('git', ['checkout', branch], workingDirectory: projectPath);
    if (result.exitCode != 0) {
      throw GitException(
        (result.stderr as String).trim().isNotEmpty ? (result.stderr as String).trim() : 'git checkout failed',
      );
    }
  }

  /// Validates [name] and runs `git checkout -b [name]`.
  /// Throws [ArgumentError] for invalid names, [GitException] on git failure.
  Future<void> createBranch(String name) async {
    if (name.isEmpty) throw ArgumentError('Branch name must not be empty.');
    if (name.startsWith('-')) {
      throw ArgumentError('Branch name must not start with a dash.');
    }
    if (name.contains(' ')) {
      throw ArgumentError('Branch name must not contain spaces.');
    }

    final result = await Process.run('git', ['checkout', '-b', name], workingDirectory: projectPath);
    if (result.exitCode != 0) {
      throw GitException((result.stderr as String).trim());
    }
  }
}
