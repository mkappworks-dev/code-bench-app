import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/git/repository/git_repository.dart';
import '../../../data/git/repository/git_repository_impl.dart';
import 'branch_picker_failure.dart';
import 'branch_picker_state.dart';

part 'branch_picker_notifier.g.dart';

@riverpod
class BranchPickerNotifier extends _$BranchPickerNotifier {
  @override
  Future<BranchPickerState> build(String projectPath) async {
    final git = ref.watch(gitRepositoryProvider);
    final branches = await git.listLocalBranches(projectPath);
    final wtBranches = await git.worktreeBranches(projectPath);
    return BranchPickerState(branches: branches, worktreeBranches: wtBranches);
  }

  BranchPickerFailure _asFailure(Object e) => switch (e) {
    ArgumentError(:final message) => BranchPickerFailure.invalidName(message?.toString() ?? 'Invalid branch name'),
    GitException(:final message) when message.contains('would be overwritten') => BranchPickerFailure.checkoutConflict(
      'Checkout failed — stash or commit your changes first.',
    ),
    GitException(:final message) => BranchPickerFailure.createFailed(message),
    _ => BranchPickerFailure.gitUnavailable(),
  };

  Future<void> checkout(String branch) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final git = ref.read(gitRepositoryProvider);
        await git.checkout(projectPath, branch);
        final branches = await git.listLocalBranches(projectPath);
        final wt = await git.worktreeBranches(projectPath);
        return BranchPickerState(branches: branches, worktreeBranches: wt);
      } catch (e, st) {
        dLog('[BranchPickerNotifier] checkout failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  /// Re-triggers [build] via Riverpod's lifecycle. Call after an action error
  /// to restore the branch list without leaving the popover in an error state.
  void reload() => ref.invalidateSelf();

  Future<void> createBranch(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final git = ref.read(gitRepositoryProvider);
        await git.createBranch(projectPath, name);
        final branches = await git.listLocalBranches(projectPath);
        final wt = await git.worktreeBranches(projectPath);
        return BranchPickerState(branches: branches, worktreeBranches: wt);
      } catch (e, st) {
        dLog('[BranchPickerNotifier] createBranch failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
}
